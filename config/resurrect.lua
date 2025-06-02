-- cat > ~/.config/wezterm/config/resurrect.lua << 'EOF'
--
-- ОПИСАНИЕ: Конфигурация плагина resurrect.wezterm
-- Настройка сохранения и восстановления сессий.
-- Все функции вынесены в utils/resurrect.lua согласно архитектуре проекта.
--
-- ЗАВИСИМОСТИ: utils/resurrect

local wezterm = require('wezterm')
local session_status = require('events.session-status')
local environment = require('config.environment')
local env_utils = require("utils.environment")
local icons = require("config.environment.icons")
local colors = require("config.environment.colors")local resurrect_utils = require("utils.resurrect")

-- Инициализация плагина resurrect.wezterm
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

-- === КОНФИГУРАЦИЯ ПЛАГИНА ===

-- Настройка периодического сохранения каждые 5 минут
resurrect.state_manager.periodic_save({
  interval_seconds = 300,
  save_tabs = true,
  save_windows = true,
  save_workspaces = true,
})

-- Ограничение на количество сохраняемых строк
resurrect.state_manager.set_max_nlines(5000)

-- Настройка папки сохранения для нашего проекта (кроссплатформенно)
local paths = require("config.environment.paths")
resurrect.state_manager.change_state_save_dir(paths.resurrect_state_dir)

-- === ПЕРЕМЕННЫЕ СОСТОЯНИЯ ===

local state_refs = {
  is_periodic_save = false,
  is_user_save = false,
  current_save_name = "",
  current_operation = nil,
  selected_session_name = nil,
  save_timeout_timer = nil,
}

local pending_operation_ref = { current = nil }
local list_shown_timer = nil
local pending_restore = nil

-- === РЕГИСТРАЦИЯ ОБРАБОТЧИКОВ СОБЫТИЙ ===

-- Обработка отмены workspace switcher
wezterm.on("smart_workspace_switcher.workspace_switcher.canceled", function(window)
  session_status.clear_saved_mode()
end)

-- Обработка ошибок
wezterm.on('resurrect.error', function(error)
  local window = nil
  if wezterm.mux and wezterm.mux.get_active_window then
    window = wezterm.mux.get_active_window()
  end
  
  if window then
    if state_refs.current_operation == "save" then
      session_status.save_session_error(window, tostring(error))
      state_refs.current_operation = nil
      state_refs.is_user_save = false
      state_refs.current_save_name = ""
      if state_refs.save_timeout_timer then
        state_refs.save_timeout_timer:cancel()
        state_refs.save_timeout_timer = nil
      end
    else
      session_status.load_session_error(window, tostring(error))
    end
  end
end)

-- Установка флага при начале периодического сохранения
wezterm.on('resurrect.state_manager.periodic_save.start', function()
  state_refs.is_periodic_save = true
end)

-- Обработчик завершения сохранения состояния
wezterm.on('resurrect.state_manager.save_state.finished', function(session_path)
  if state_refs.save_timeout_timer then
    state_refs.save_timeout_timer:cancel()
    state_refs.save_timeout_timer = nil
  end
  
  if not state_refs.is_periodic_save and state_refs.is_user_save then
    local path = session_path:match(".+/([^/]+)$")
    local name = path and path:match("^(.+)%.json$") or state_refs.current_save_name or environment.locale.t("unknown_type")
    
    local window = nil
    if wezterm.mux and wezterm.mux.get_active_window then
      window = wezterm.mux.get_active_window()
    end
    
    if window then
      session_status.save_session_success(window, name)
      
      if pending_restore then
        wezterm.time.call_after(2, function()
          resurrect_utils.perform_restore(wezterm, resurrect, session_status, environment, pending_restore.window, pending_restore.pane, pending_restore.id, pending_restore.session_name, pending_restore.type_info, pending_operation_ref)
          pending_restore = nil
        end)
      end
    end
    
    state_refs.is_user_save = false
    state_refs.current_save_name = ""
    state_refs.current_operation = nil
  elseif state_refs.is_periodic_save then
    state_refs.is_periodic_save = false
  end
end)

-- Обработчик начала сохранения состояния
wezterm.on('resurrect.state_manager.save_state.start', function(state, opt_name)
  if not state_refs.is_periodic_save and state_refs.is_user_save then
    state_refs.current_operation = "save"
    
    state_refs.save_timeout_timer = wezterm.time.call_after(1, function()
      local window = nil
      if wezterm.mux and wezterm.mux.get_active_window then
        window = wezterm.mux.get_active_window()
      end
      
      if window and state_refs.is_user_save then
        session_status.save_session_error(window, environment.locale.t("plugin_error"))
        state_refs.is_user_save = false
        state_refs.current_save_name = ""
        state_refs.current_operation = nil
        
        if pending_restore then
          wezterm.time.call_after(2, function()
            resurrect_utils.perform_restore(wezterm, resurrect, session_status, environment, pending_restore.window, pending_restore.pane, pending_restore.id, pending_restore.session_name, pending_restore.type_info, pending_operation_ref)
            pending_restore = nil
          end)
        end
      end
      state_refs.save_timeout_timer = nil
    end)
  end
end)

-- Остальные обработчики
wezterm.on('resurrect.state_manager.load_state.finished', function(name, type)
  if pending_operation_ref.current and pending_operation_ref.current.type == "load" then
    local window = pending_operation_ref.current.window
    local session_name = pending_operation_ref.current.session_name or name
    
    session_status.load_session_success(window, session_name)
    
    pending_operation_ref.current = nil
    state_refs.current_operation = nil
    state_refs.selected_session_name = nil
  end
end)

wezterm.on('resurrect.state_manager.delete_state.finished', function(id)
  if pending_operation_ref.current and pending_operation_ref.current.type == "delete" then
    local window = pending_operation_ref.current.window
    local session_name = pending_operation_ref.current.session_name
    
    if not session_name then
      local path = id:match(".+/([^/]+)$")
      session_name = path and path:match("^(.+)%.json$") or id
    end
    
    session_status.delete_session_success(window, session_name)
    
    pending_operation_ref.current = nil
    state_refs.current_operation = nil
    state_refs.selected_session_name = nil
  end
end)

wezterm.on('resurrect.fuzzy_loader.fuzzy_load.start', function(window, pane)
end)

wezterm.on('resurrect.fuzzy_loader.fuzzy_load.finished', function(window, pane)
  if list_shown_timer then
    list_shown_timer:cancel()
    list_shown_timer = nil
  end
  
  wezterm.time.call_after(0.3, function()
    if state_refs.current_operation and not pending_operation_ref.current then
      if state_refs.current_operation == "load" then
        session_status.load_session_cancelled(window)
      elseif state_refs.current_operation == "delete" then
        session_status.delete_session_cancelled(window)
      end
      state_refs.current_operation = nil
      state_refs.selected_session_name = nil
    end
  end)
end)

-- === РЕГИСТРАЦИЯ ОБРАБОТЧИКОВ СОХРАНЕНИЯ И ЗАГРУЗКИ ===

-- Используем функции из utils/resurrect.lua
wezterm.on('resurrect.save_state', resurrect_utils.create_save_workspace_handler(wezterm, resurrect, session_status, environment, env_utils, icons, state_refs))
wezterm.on('resurrect.save_window', resurrect_utils.create_save_window_handler(wezterm, resurrect, session_status, environment, env_utils, icons))
wezterm.on('resurrect.save_tab', resurrect_utils.create_save_tab_handler(wezterm, resurrect, session_status, environment, env_utils, icons))
wezterm.on('resurrect.load_state', resurrect_utils.create_load_state_handler(wezterm, resurrect, session_status, environment, state_refs, pending_operation_ref))

-- Регистрируем обработчик удаления состояний
local appearance_utils = require("utils.appearance")
wezterm.on('resurrect.delete_state', appearance_utils.create_delete_state_handler(
  wezterm, 
  session_status, 
  environment, 
  icons, 
  colors, 
  env_utils
))