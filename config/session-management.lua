-- ОПИСАНИЕ: Объединенное управление сессиями и workspace
-- Интегрирует smart_workspace_switcher + resurrect.wezterm + ваша система индикации

local wezterm = require('wezterm')
local session_status = require('events.session-status')
local M = {}

-- Инициализация плагинов
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

-- Локальные переменные для отслеживания состояния
local current_operation = nil
local session_mode = nil

-- === НАСТРОЙКИ ===
M.config = {
  zoxide_path = "/opt/homebrew/bin/zoxide",
  auto_save_interval = 300, -- 5 минут
  max_nlines = 5000,
  session_prefix = "session_",
  workspace_prefix = "ws_",
}

-- === ИНИЦИАЛИЗАЦИЯ ПЛАГИНОВ ===
M.setup = function(user_config)
  if user_config then
    for k, v in pairs(user_config) do
      M.config[k] = v
    end
  end
  
  -- Настройка workspace_switcher
  workspace_switcher.zoxide_path = M.config.zoxide_path
  
  -- Настройка resurrect
  resurrect.state_manager.periodic_save({
    interval_seconds = M.config.auto_save_interval,
    save_tabs = true,
    save_windows = true,
    save_workspaces = true,
  })
  resurrect.state_manager.set_max_nlines(M.config.max_nlines)
  
  -- Настройка событий
  M.setup_events()
  
  wezterm.log_info("🎯 Session Management инициализирован")
  return M
end

-- === ОСНОВНЫЕ ФУНКЦИИ ===

-- 1. Умный поиск workspace (с zoxide)
M.switch_workspace = function()
  return wezterm.action_callback(function(window, pane)
    session_status.set_mode("workspace_search")
    current_operation = "workspace_switch"
    session_mode = "workspace_search"
    
    window:perform_action(workspace_switcher.switch_workspace(), pane)
  end)
end

-- 2. Переключение на предыдущий workspace
M.switch_to_previous_workspace = function()
  return wezterm.action_callback(function(window, pane)
    session_status.set_mode("workspace_search")
    current_operation = "workspace_prev"
    session_mode = "workspace_search"
    
    window:perform_action(workspace_switcher.switch_to_prev_workspace(), pane)
  end)
end

-- 3. Сохранение текущего состояния с именем
M.save_session = function()
  return wezterm.action_callback(function(window, pane)
    session_status.set_mode("session_control")
    current_operation = "session_save"
    session_mode = "session_control"
    
    window:perform_action(
      wezterm.action.PromptInputLine({
        description = "💾 Введите имя для сохранения сессии:",
        action = wezterm.action_callback(function(inner_window, inner_pane, line)
          if line and line ~= "" then
            session_status.start_loading(window)
            
            local session_name = M.config.session_prefix .. line
            
            wezterm.time.call_after(0.2, function()
              local state = resurrect.workspace_state.get_workspace_state()
              if state then
                resurrect.state_manager.save_state(state, session_name)
                wezterm.log_info("💾 Сохраняем сессию: " .. session_name)
              else
                session_status.save_session_error(window, "Ошибка получения состояния")
              end
            end)
          else
            session_status.clear_saved_mode()
            current_operation = nil
            session_mode = nil
          end
        end),
      }),
      pane
    )
  end)
end

-- 4. Загрузка сессии через fuzzy finder
M.load_session = function()
  return wezterm.action_callback(function(window, pane)
    session_status.set_mode("session_control") 
    current_operation = "session_load"
    session_mode = "session_control"
    
    session_status.load_session_start(window)
    
    -- Используем fuzzy_loader от resurrect для выбора сессии
    resurrect.fuzzy_loader.fuzzy_load(
      window, 
      pane, 
      function(id, label)
        current_operation = "session_restore"
        session_status.start_loading(window)
        
        wezterm.log_info("🔄 Загружаем сессию: " .. (label or id))
        
        wezterm.time.call_after(0.3, function()
          -- Определяем тип состояния и загружаем соответственно
          local type = string.match(id, "^([^/]+)")
          local clean_id = string.match(id, "([^/]+)$")
          clean_id = clean_id and string.match(clean_id, "(.+)%..+$") or clean_id
          
          local state
          if type == "workspace" then
            state = resurrect.state_manager.load_state(clean_id, "workspace")
            if state then
              resurrect.workspace_state.restore_workspace(state, {
                relative = false,
                restore_text = true,
              })
            end
          elseif type == "window" then
            state = resurrect.state_manager.load_state(clean_id, "window")
            if state then
              resurrect.window_state.restore_window(pane:window(), state, {
                relative = false,
                restore_text = true,
              })
            end
          elseif type == "tab" then
            state = resurrect.state_manager.load_state(clean_id, "tab")
            if state then
              resurrect.tab_state.restore_tab(pane:tab(), state, {
                relative = false,
                restore_text = true,
              })
            end
          end
          
          if state then
            local display_name = label or clean_id or "сессия"
            session_status.load_session_success(window, display_name)
          else
            session_status.load_session_error(window, "Ошибка загрузки состояния")
          end
        end)
      end,
      {
        title = "🔄 Загрузка сессии",
        description = "Выберите сессию для загрузки: Enter = загрузить, Esc = отмена, / = фильтр",
        fuzzy_description = "Поиск сессии: ",
        is_fuzzy = true,
      }
    )
  end)
end

-- 5. Удаление сессии через fuzzy finder
M.delete_session = function()
  return wezterm.action_callback(function(window, pane)
    session_status.set_mode("session_control")
    current_operation = "session_delete"
    session_mode = "session_control"
    
    session_status.delete_session_start(window)
    
    resurrect.fuzzy_loader.fuzzy_load(
      window, 
      pane, 
      function(id, label)
        local display_name = label or string.match(id, "([^/]+)$") or "сессия"
        
        wezterm.log_info("🗑️  Удаляем сессию: " .. display_name)
        resurrect.state_manager.delete_state(id)
        
        session_status.delete_session_success(window, display_name)
        current_operation = nil
        session_mode = nil
      end,
      {
        title = "🗑️ Удаление сессии",
        description = "Выберите сессию для удаления: Enter = удалить, Esc = отмена, / = фильтр",
        fuzzy_description = "Поиск сессии для удаления: ",
        is_fuzzy = true,
      }
    )
  end)
end

-- 6. Показ всех workspace (встроенный лаунчер)
M.show_workspaces = function()
  return wezterm.action_callback(function(window, pane)
    session_status.set_mode("workspace_search")
    current_operation = "workspace_list" 
    session_mode = "workspace_search"
    
    window:perform_action(
      wezterm.action.ShowLauncherArgs({ 
        flags = "FUZZY|WORKSPACES",
        title = "🏠 Workspace Manager"
      }), 
      pane
    )
  end)
end

-- === СОБЫТИЯ ПЛАГИНОВ ===

M.setup_events = function()
  -- События workspace_switcher
  wezterm.on('smart_workspace_switcher.workspace_switcher.start', function(window)
    wezterm.log_info("🔍 Workspace switcher: поиск начат")
  end)
  
  wezterm.on('smart_workspace_switcher.workspace_switcher.canceled', function(window)
    wezterm.log_info("❌ Workspace switcher: отменено")
    if current_operation and session_mode then
      session_status.clear_saved_mode()
      current_operation = nil
      session_mode = nil
    end
  end)
  
  wezterm.on('smart_workspace_switcher.workspace_switcher.chosen', function(window, workspace)
    local workspace_name = workspace:match("([^/]+)$") or workspace
    wezterm.log_info("✅ Workspace выбран: " .. workspace_name)
    
    if current_operation == "workspace_switch" or current_operation == "workspace_prev" then
      wezterm.time.call_after(0.5, function()
        session_status.show_notification(window, workspace_name, "🏠", "#50fa7b", 2000, true)
        current_operation = nil
        session_mode = nil
      end)
    end
  end)
  
  wezterm.on('smart_workspace_switcher.workspace_switcher.created', function(window, workspace)
    local workspace_name = workspace:match("([^/]+)$") or workspace
    wezterm.log_info("🆕 Workspace создан: " .. workspace_name)
    
    wezterm.time.call_after(0.5, function()
      session_status.show_notification(window, "Создан: " .. workspace_name, "🆕", "#50fa7b", 3000, true)
      current_operation = nil
      session_mode = nil
    end)
  end)
  
  -- События resurrect
  wezterm.on('resurrect.save_state.finished', function(session_path)
    wezterm.log_info("💾 Resurrect: сохранение завершено - " .. session_path)
    
    if current_operation == "session_save" then
      local path = session_path:match(".+/([^/]+)$")
      local name = path and path:match("^(.+)%.json$") or "сессия"
      local display_name = name:gsub(M.config.session_prefix, "")
      
      local window = wezterm.mux.get_active_window()
      if window then
        session_status.save_session_success(window, display_name)
        current_operation = nil
        session_mode = nil
      end
    end
  end)
  
  wezterm.on('resurrect.load_state.finished', function(name, type)
    wezterm.log_info("🔄 Resurrect: загрузка завершена - " .. name .. " (" .. type .. ")")
    
    if current_operation == "session_restore" then
      current_operation = nil
      session_mode = nil
    end
  end)
  
  wezterm.on('resurrect.error', function(error)
    wezterm.log_error("❌ Resurrect error: " .. tostring(error))
    
    local window = wezterm.mux.get_active_window()
    if window then
      if current_operation == "session_save" then
        session_status.save_session_error(window, tostring(error))
      else
        session_status.load_session_error(window, tostring(error))
      end
      current_operation = nil
      session_mode = nil
    end
  end)
  
  -- Очистка при отмене лаунчера workspace
  wezterm.on('launcher-canceled', function(window)
    if current_operation == "workspace_list" and session_mode == "workspace_search" then
      session_status.clear_saved_mode()
      current_operation = nil
      session_mode = nil
    end
  end)
end

return M
