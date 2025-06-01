-- cat > ~/.config/wezterm/config/resurrect.lua << 'EOF'
--
-- ОПИСАНИЕ: Объединенный модуль для сохранения и восстановления сессий
-- Включает всю функциональность плагина resurrect.wezterm: 
-- инициализацию, настройку, обработчики событий, и вспомогательные функции.
-- Централизует всю логику сохранения и восстановления сессий.
--
-- ЗАВИСИМОСТИ: events.session-status

local wezterm = require('wezterm')
local session_status = require('events.session-status')
local environment = require('config.environment')
local M = {}

-- Инициализация плагина resurrect.wezterm
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
M.resurrect = resurrect

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

-- Переменные для отслеживания состояния
local is_periodic_save = false
local is_user_save = false
local current_save_name = ""
local current_operation = nil
local selected_session_name = nil
local list_shown_timer = nil
local pending_operation = nil
local save_timeout_timer = nil
local pending_restore = nil

-- Безопасная функция для получения состояния workspace
local function safe_get_workspace_state()
  local ok, state = pcall(function()
    return resurrect.workspace_state.get_workspace_state()
  end)
  
  if ok then
    return state
  else
    return nil
  end
end

-- Функция для принудительного закрытия всех вкладок
local function safe_clear_tabs(window)
  local mux_window = window:mux_window()
  local tabs = mux_window:tabs()
  
  -- Оставляем только первую вкладку, остальные закрываем
  for i = #tabs, 2, -1 do
    local tab = tabs[i]
    if tab then
      tab:activate()
      window:perform_action(wezterm.action.CloseCurrentTab({confirm = false}), tab:active_pane())
    end
  end
end

-- Функция для выполнения восстановления состояния
local function perform_restore(window, pane, id, session_name, type_info)
  session_status.start_loading(window)
  
  pending_operation = {
    type = "load",
    window = window,
    session_name = session_name
  }
  
  local type = string.match(id, "^([^/]+)")
  local clean_id = string.match(id, "([^/]+)$")
  clean_id = string.match(clean_id, "(.+)%..+$")
  
  safe_clear_tabs(window)
  
  wezterm.time.call_after(1.0, function()
    local opts = {
      window = window:mux_window(),
      relative = false,
      restore_text = true,
      on_pane_restore = resurrect.tab_state.default_on_pane_restore,
    }
    
    local success = false
    
    if type == "workspace" then
      local state = resurrect.state_manager.load_state(clean_id, "workspace")
      if state then
        resurrect.workspace_state.restore_workspace(state, opts)
        success = true
      end
    elseif type == "window" then
      local state = resurrect.state_manager.load_state(clean_id, "window")
      if state then
        resurrect.window_state.restore_window(pane:window(), state, opts)
        success = true
      end
    elseif type == "tab" then
      local state = resurrect.state_manager.load_state(clean_id, "tab")
      if state then
        resurrect.tab_state.restore_tab(pane:tab(), state, opts)
        success = true
      end
    end
    
    if not success then
      session_status.load_session_error(window, environment.locale.t("cannot_get_state"))
      pending_operation = nil
      current_operation = nil
      selected_session_name = nil
    else
      session_status.load_session_success(window, session_name or environment.locale.t("session_saved_as", ""))
    end
  end)
end

-- ========================== ОБРАБОТЧИКИ СОБЫТИЙ ==========================

local function register_event_handlers()
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
      if current_operation == "save" then
        session_status.save_session_error(window, tostring(error))
        current_operation = nil
        is_user_save = false
        current_save_name = ""
        if save_timeout_timer then
          save_timeout_timer:cancel()
          save_timeout_timer = nil
        end
      else
        session_status.load_session_error(window, tostring(error))
      end
    end
  end)

  -- Установка флага при начале периодического сохранения
  wezterm.on('resurrect.state_manager.periodic_save.start', function()
    is_periodic_save = true
  end)

  -- Обработчик завершения сохранения состояния
  wezterm.on('resurrect.state_manager.save_state.finished', function(session_path)
    if save_timeout_timer then
      save_timeout_timer:cancel()
      save_timeout_timer = nil
    end
    
    if not is_periodic_save and is_user_save then
      local path = session_path:match(".+/([^/]+)$")
      local name = path and path:match("^(.+)%.json$") or current_save_name or environment.locale.t("unknown_type")
      
      local window = nil
      if wezterm.mux and wezterm.mux.get_active_window then
        window = wezterm.mux.get_active_window()
      end
      
      if window then
        session_status.save_session_success(window, name)
        
        if pending_restore then
          wezterm.time.call_after(2, function()
            perform_restore(pending_restore.window, pending_restore.pane, pending_restore.id, pending_restore.session_name, pending_restore.type_info)
            pending_restore = nil
          end)
        end
      end
      
      is_user_save = false
      current_save_name = ""
      current_operation = nil
    elseif is_periodic_save then
      is_periodic_save = false
    end
  end)

  -- Обработчик начала сохранения состояния
  wezterm.on('resurrect.state_manager.save_state.start', function(state, opt_name)
    if not is_periodic_save and is_user_save then
      current_operation = "save"
      
      save_timeout_timer = wezterm.time.call_after(1, function()
        local window = nil
        if wezterm.mux and wezterm.mux.get_active_window then
          window = wezterm.mux.get_active_window()
        end
        
        if window and is_user_save then
          session_status.save_session_error(window, environment.locale.t("plugin_error"))
          is_user_save = false
          current_save_name = ""
          current_operation = nil
          
          if pending_restore then
            wezterm.time.call_after(2, function()
              perform_restore(pending_restore.window, pending_restore.pane, pending_restore.id, pending_restore.session_name, pending_restore.type_info)
              pending_restore = nil
            end)
          end
        end
        save_timeout_timer = nil
      end)
    end
  end)

  -- Остальные обработчики...
  wezterm.on('resurrect.state_manager.load_state.finished', function(name, type)
    if pending_operation and pending_operation.type == "load" then
      local window = pending_operation.window
      local session_name = pending_operation.session_name or name
      
      session_status.load_session_success(window, session_name)
      
      pending_operation = nil
      current_operation = nil
      selected_session_name = nil
    end
  end)

  wezterm.on('resurrect.state_manager.delete_state.finished', function(id)
    if pending_operation and pending_operation.type == "delete" then
      local window = pending_operation.window
      local session_name = pending_operation.session_name
      
      if not session_name then
        local path = id:match(".+/([^/]+)$")
        session_name = path and path:match("^(.+)%.json$") or id
      end
      
      session_status.delete_session_success(window, session_name)
      
      pending_operation = nil
      current_operation = nil
      selected_session_name = nil
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
      if current_operation and not pending_operation then
        if current_operation == "load" then
          session_status.load_session_cancelled(window)
        elseif current_operation == "delete" then
          session_status.delete_session_cancelled(window)
        end
        current_operation = nil
        selected_session_name = nil
      end
    end)
  end)

  -- Сохранение состояния

  -- Сохранение window
  wezterm.on('resurrect.save_window', function(window, pane)
    local current_workspace = window:active_workspace()
    local window_title = (window and window.get_title and window:get_title()) or "window"
    local default_name = current_workspace .. "_window_" .. os.date("%H%M%S")
    
    window:perform_action(
      wezterm.action.PromptInputLine({
        description = env_utils.get_icon(icons, "save_window_tab") .. " " .. environment.locale.t("save_window_as") .. "\n" .. environment.locale.t("save_window_default", default_name) .. "\n\n" .. environment.locale.t("save_window_instructions"),
        action = wezterm.action_callback(function(inner_win, inner_pane, line)
          local save_name = (line == "" or line == nil) and default_name or line
          if save_name then
            local window_state = resurrect.window_state.get_window_state(inner_win:mux_window())
            resurrect.state_manager.save_state(window_state, save_name, "window")
            local session_status = require("events.session-status")
            session_status.clear_saved_mode()
          end
        end),
      }),
      pane
    )
  end)

  -- Сохранение tab
  wezterm.on('resurrect.save_tab', function(window, pane)
    local tab_title = (pane and pane.tab and pane:tab() and pane:tab().get_title and pane:tab():get_title()) or "tab"
    local workspace = window:active_workspace()
    local default_name = workspace .. "_tab_" .. os.date("%H%M%S")
    
    window:perform_action(
      wezterm.action.PromptInputLine({
        description = env_utils.get_icon(icons, "save_tab_tab") .. " " .. environment.locale.t("save_tab_as") .. "\n" .. environment.locale.t("save_tab_default", default_name) .. "\n\n" .. environment.locale.t("save_tab_instructions"),
        action = wezterm.action_callback(function(inner_win, inner_pane, line)
          local save_name = (line == "" or line == nil) and default_name or line
          if save_name then
            local tab = inner_pane:tab() or inner_win:active_tab()
            if not tab then
              wezterm.log_error("Cannot get tab from pane or window")
              session_status.save_session_error(inner_win, environment.locale.t("cannot_get_tab_error"))
              return
            end
            local tab_state = resurrect.tab_state.get_tab_state(tab)
            resurrect.state_manager.save_state(tab_state, save_name, "tab")
            local session_status = require("events.session-status")
            session_status.clear_saved_mode()
          end
        end),
      }),
      pane
    )
  end)

  wezterm.on('resurrect.save_state', function(window, pane)
    window:perform_action(
      wezterm.action.PromptInputLine({
        description = env_utils.get_icon(icons, "save_workspace_tab") .. " " .. environment.locale.t("enter_save_session_name") .. "\n" .. environment.locale.t("current_workspace", window:active_workspace()) .. "\n\n" .. environment.locale.t("enter_save_default"),
        action = wezterm.action_callback(function(inner_win, inner_pane, line)
          local save_name
          
          if line == nil then
            session_status.clear_saved_mode()
            return
          elseif line == "" then
            save_name = window:active_workspace()
          else
            save_name = line
          end
          
          if save_name and save_name ~= "" then
            is_user_save = true
            current_save_name = save_name
            current_operation = "save"
            
            session_status.start_loading(window)
            
            -- ПРИНУДИТЕЛЬНЫЙ ТАЙМЕР НА 2 СЕКУНДЫ для ошибок плагина
            save_timeout_timer = wezterm.time.call_after(1, function()
              if window then
                session_status.save_session_error(window, environment.locale.t("plugin_error"))
              end
              is_user_save = false
              current_save_name = ""
              current_operation = nil
              save_timeout_timer = nil
            end)
            
            wezterm.time.call_after(0.1, function()
              local state = resurrect.workspace_state.get_workspace_state()
              if state then
                resurrect.state_manager.save_state(state, save_name)
              else
                -- Отменяем таймер и сразу очищаем иконку
                if save_timeout_timer then
                  save_timeout_timer:cancel()
                  save_timeout_timer = nil
                end
                session_status.save_session_error(window, environment.locale.t("cannot_get_state"))
                is_user_save = false
                current_save_name = ""
                current_operation = nil
              end
            end)
          else
            session_status.clear_saved_mode()
          end
        end),
      }),
      pane
    )
  end)

  -- Загрузка состояния
  wezterm.on('resurrect.load_state', function(window, pane)
    current_operation = "load"
    selected_session_name = nil
    pending_operation = nil
    session_status.load_session_start(window)
    
    resurrect.fuzzy_loader.fuzzy_load(
      window, 
      pane, 
      function(id, label)
        current_operation = nil
        
        local type = string.match(id, "^([^/]+)")
        local type_display = environment.locale.t("unknown_type")
        if type == "workspace" then
          type_display = environment.locale.t("workspace_type")
        elseif type == "window" then
          type_display = environment.locale.t("window_type")
        elseif type == "tab" then
          type_display = environment.locale.t("tab_type")
        end
        
        if label and label ~= "" then
          selected_session_name = label
        else
          local clean_id = string.match(id, "([^/]+)$")
          selected_session_name = clean_id and string.match(clean_id, "(.+)%..+$") or clean_id
        end
        
        perform_restore(window, pane, id, selected_session_name, type_display)
      end,
      {
        title = environment.locale.t("loading_sessions_title"),
        description = environment.locale.t("loading_sessions_description"),
        fuzzy_description = environment.locale.t("loading_sessions_fuzzy"),
        is_fuzzy = true,
      }
    )
  end)

  -- УДАЛЕНИЕ СОСТОЯНИЯ - ОТКЛЮЧЕНО, используем events.delete-states.lua
  -- wezterm.on('resurrect.delete_state', function(window, pane)
  --   -- Этот обработчик отключен в пользу локализованного модуля
  -- end)
end

-- Инициализация
register_event_handlers()

return M
