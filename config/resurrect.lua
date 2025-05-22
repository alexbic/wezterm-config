-- cat > ~/.config/wezterm/config/resurrect.lua << 'EOF'
--
-- ОПИСАНИЕ: Объединенный модуль для сохранения и восстановления сессий
-- Включает всю функциональность плагина resurrect.wezterm: 
-- инициализацию, настройку, обработчики событий, и вспомогательные функции.
-- Централизует всю логику сохранения и восстановления сессий.
--
-- ЗАВИСИМОСТИ: utils.session-status

local wezterm = require('wezterm')
local session_status = require('utils.session-status')
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

-- Переменные для отслеживания состояния
local is_periodic_save = false
local is_user_save = false
local current_save_name = ""
local fuzzy_load_active = false

-- ========================== ОБРАБОТЧИКИ СОБЫТИЙ ==========================

local function register_event_handlers()
  -- Обработка ошибок
  wezterm.on('resurrect.error', function(error)
    wezterm.log_info("Событие resurrect.error: " .. tostring(error))
    
    local window = nil
    if wezterm.mux and wezterm.mux.get_active_window then
      window = wezterm.mux.get_active_window()
    end
    
    if window then
      session_status.load_session_error(window, tostring(error))
    end
  end)

  -- Установка флага при начале периодического сохранения
  wezterm.on('resurrect.state_manager.periodic_save.start', function()
    is_periodic_save = true
  end)

  -- Обработчик завершения сохранения состояния
  wezterm.on('resurrect.state_manager.save_state.finished', function(session_path)
    wezterm.log_info("Событие save_state.finished: " .. session_path)
    
    if not is_periodic_save and is_user_save then
      local path = session_path:match(".+/([^/]+)$")
      local name = path and path:match("^(.+)%.json$") or current_save_name or "неизвестно"
      
      local window = nil
      if wezterm.mux and wezterm.mux.get_active_window then
        window = wezterm.mux.get_active_window()
      end
      
      if window then
        session_status.save_session_success(window, name)
      end
      
      is_user_save = false
      current_save_name = ""
    elseif is_periodic_save then
      is_periodic_save = false
    end
  end)

  -- Обработчик завершения загрузки состояния (когда выбрана сессия)
  wezterm.on('resurrect.state_manager.load_state.finished', function(name, type)
    wezterm.log_info("Событие load_state.finished: " .. name .. ", тип: " .. type)
    
    local window = nil
    if wezterm.mux and wezterm.mux.get_active_window then
      window = wezterm.mux.get_active_window()
    end
    
    if window then
      session_status.load_session_success(window, name)
    end
  end)

  -- Обработчик удаления сессии (когда выбрана сессия для удаления)
  wezterm.on('resurrect.state_manager.delete_state.finished', function(id)
    wezterm.log_info("Событие delete_state.finished: " .. id)
    
    local path = id:match(".+/([^/]+)$")
    local name = path and path:match("^(.+)%.json$") or id
    
    local window = nil
    if wezterm.mux and wezterm.mux.get_active_window then
      window = wezterm.mux.get_active_window()
    end
    
    if window then
      session_status.delete_session_success(window, name)
    end
  end)

  -- Обработчик начала fuzzy_load
  wezterm.on('resurrect.fuzzy_loader.fuzzy_load.start', function(window, pane)
    wezterm.log_info("Событие fuzzy_load.start")
    fuzzy_load_active = true
  end)
  
  -- Обработчик завершения fuzzy_load
  wezterm.on('resurrect.fuzzy_loader.fuzzy_load.finished', function(window, pane)
    wezterm.log_info("Событие fuzzy_load.finished")
    fuzzy_load_active = false
    
    -- Если список был показан, но пользователь не выбрал ничего - это отмена
    local status = wezterm.GLOBALS.session_status
    if status and status.operation_state and status.operation_state.active then
      wezterm.time.call_after(0.1, function()
        if status.operation_state.active then
          if status.operation_state.type == "load" then
            session_status.load_session_cancelled(window)
          elseif status.operation_state.type == "delete" then
            session_status.delete_session_cancelled(window)
          end
        end
      end)
    end
  end)

  -- Регистрируем основные обработчики команд resurrect
  
  -- Сохранение состояния
  wezterm.on('resurrect.save_state', function(window, pane)
    wezterm.log_info("Обработчик события resurrect.save_state")
    
    window:perform_action(
      wezterm.action.PromptInputLine({
        description = "Введите имя для сохранения сессии",
        action = wezterm.action_callback(function(inner_win, inner_pane, line)
          if line and line ~= "" then
            is_user_save = true
            current_save_name = line
            
            session_status.start_loading(window)
            
            local state = resurrect.workspace_state.get_workspace_state()
            resurrect.state_manager.save_state(state, line)
          else
            -- Если отменено, очищаем режим
            session_status.clear_saved_mode()
          end
        end),
      }),
      pane
    )
  end)

  -- Восстановление состояния
  wezterm.on('resurrect.restore_state', function(window, pane)
    wezterm.log_info("Обработчик события resurrect.restore_state")
    
    local workspace_name = ""
    if wezterm.mux and wezterm.mux.get_active_workspace then
      workspace_name = wezterm.mux.get_active_workspace()
    end
    
    session_status.start_loading(window)
    
    local state = resurrect.state_manager.load_state(workspace_name, "workspace")
    if state then
      resurrect.workspace_state.restore_workspace(state, {
        window = window:mux_window(),
        relative = true,
        restore_text = true,
        on_pane_restore = resurrect.tab_state.default_on_pane_restore,
      })
    else
      session_status.load_session_error(window, "Сессия не найдена")
    end
  end)

  -- Загрузка состояния
  wezterm.on('resurrect.load_state', function(window, pane)
    wezterm.log_info("Обработчик события resurrect.load_state")
    
    session_status.load_session_start(window)
    
    local callback_executed = false
    
    resurrect.fuzzy_loader.fuzzy_load(
      window, 
      pane, 
      function(id, label)
        wezterm.log_info("fuzzy_load callback вызван с id: " .. id)
        callback_executed = true
        
        local type = string.match(id, "^([^/]+)")
        local clean_id = string.match(id, "([^/]+)$")
        clean_id = string.match(clean_id, "(.+)%..+$")
        
        wezterm.log_info("Обработка выбора: тип=" .. (type or "unknown") .. ", id=" .. (clean_id or "unknown"))
        
        local opts = {
          window = window:mux_window(),
          relative = true,
          restore_text = true,
          on_pane_restore = resurrect.tab_state.default_on_pane_restore,
        }
        
        if type == "workspace" then
          local state = resurrect.state_manager.load_state(clean_id, "workspace")
          resurrect.workspace_state.restore_workspace(state, opts)
        elseif type == "window" then
          local state = resurrect.state_manager.load_state(clean_id, "window")
          resurrect.window_state.restore_window(pane:window(), state, opts)
        elseif type == "tab" then
          local state = resurrect.state_manager.load_state(clean_id, "tab")
          resurrect.tab_state.restore_tab(pane:tab(), state, opts)
        end
      end,
      {
        title = "Загрузка сессии",
        description = "Выберите сессию для загрузки и нажмите Enter = загрузить, Esc = отмена, / = фильтр",
        fuzzy_description = "Поиск сессии для загрузки: ",
        is_fuzzy = true,
      }
    )
    
    -- Останавливаем анимацию когда список появился
    wezterm.time.call_after(1, function()
      if not callback_executed then
        wezterm.log_info("Список загрузки отображен, останавливаем анимацию")
        session_status.stop_loading(window)
        session_status.mark_list_shown()
      end
    end)
  end)

  -- Удаление состояния
  wezterm.on('resurrect.delete_state', function(window, pane)
    wezterm.log_info("Обработчик события resurrect.delete_state")
    
    session_status.delete_session_start(window)
    
    local callback_executed = false
    
    resurrect.fuzzy_loader.fuzzy_load(
      window, 
      pane, 
      function(id)
        wezterm.log_info("fuzzy_load callback для удаления вызван с id: " .. id)
        callback_executed = true
        
        local path = id:match(".+/([^/]+)$")
        local name = path and path:match("^(.+)%.json$") or id
        
        wezterm.log_info("Удаление сессии: " .. name)
        
        resurrect.state_manager.delete_state(id)
      end,
      {
        title = "Удаление сессии",
        description = "Выберите сессию для удаления и нажмите Enter = удалить, Esc = отмена, / = фильтр",
        fuzzy_description = "Поиск сессии для удаления: ",
        is_fuzzy = true,
      }
    )
    
    -- Останавливаем анимацию когда список появился
    wezterm.time.call_after(1, function()
      if not callback_executed then
        wezterm.log_info("Список удаления отображен, останавливаем анимацию")
        session_status.stop_loading(window)
        session_status.mark_list_shown()
      end
    end)
  end)

  -- Тестовое событие
  wezterm.on('resurrect.test_notification', function(window, pane)
    wezterm.log_info("Тестовое событие")
    
    if window then
      session_status.start_loading(window)
      
      wezterm.time.call_after(3, function()
        session_status.save_session_success(window, "тестовая_сессия")
      end)
    end
  end)
end

-- Инициализация
register_event_handlers()

return M
