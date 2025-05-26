-- ОПИСАНИЕ: Расширенный workspace менеджер с интеграцией smart_workspace_switcher
-- Объединяет ваш session-status с новым плагином для лучшего UX

local wezterm = require('wezterm')
local session_status = require('events.session-status')
local M = {}

-- Инициализация плагинов
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

-- Настройки
M.config = {
  zoxide_path = "/opt/homebrew/bin/zoxide",
  auto_save_on_switch = true,
  session_prefix = "ws_",
  show_workspace_in_status = true,
}

-- Локальные переменные
local current_operation = nil
local workspace_history = {}

-- Настройка плагинов
workspace_switcher.zoxide_path = M.config.zoxide_path

-- Кастомизация formatter для красивого отображения
workspace_switcher.workspace_formatter = function(label)
  return wezterm.format({
    { Attribute = { Italic = false } },
    { Foreground = { Color = "#50fa7b" } },
    { Background = { Color = "#282a36" } },
    { Text = "󱂬 " .. label },
  })
end

-- === ОСНОВНЫЕ ФУНКЦИИ ===

-- Умное переключение workspace с интеграцией вашего session-status
M.smart_switch_workspace = function()
  return wezterm.action_callback(function(window, pane)
    -- Устанавливаем режим поиска workspace (интегрируется с вашей системой)
    session_status.set_mode("workspace_search")
    current_operation = "switch"
    
    -- Автосохранение текущего workspace если нужно
    if M.config.auto_save_on_switch then
      local current_ws = window:active_workspace()
      M.auto_save_workspace(current_ws, window)
    end
    
    -- Запускаем smart_workspace_switcher
    window:perform_action(workspace_switcher.switch_workspace(), pane)
  end)
end

-- Автосохранение workspace с индикацией
M.auto_save_workspace = function(workspace_name, window)
  if not workspace_name or workspace_name == "" then return end
  
  -- Показываем анимацию сохранения
  session_status.start_loading(window)
  
  local session_name = M.config.session_prefix .. workspace_name .. "_auto_" .. os.date("%H%M")
  
  wezterm.time.call_after(0.3, function()
    local state = resurrect.workspace_state.get_workspace_state()
    if state then
      resurrect.state_manager.save_state(state, session_name)
      -- Не показываем уведомление для автосохранения (только loading)
      wezterm.time.call_after(1, function()
        session_status.stop_loading(window)
      end)
    else
      session_status.save_session_error(window, "Ошибка автосохранения")
    end
  end)
end

-- Ручное сохранение workspace
M.save_workspace = function()
  return wezterm.action_callback(function(window, pane)
    session_status.set_mode("session_control")
    
    local workspace_name = window:active_workspace()
    
    window:perform_action(
      wezterm.action.PromptInputLine({
        description = "💾 Сохранить workspace '" .. workspace_name .. "' как:",
        action = wezterm.action_callback(function(inner_window, inner_pane, line)
          if line and line ~= "" then
            session_status.start_loading(window)
            
            local session_name = M.config.session_prefix .. workspace_name .. "_" .. line
            
            wezterm.time.call_after(0.2, function()
              local state = resurrect.workspace_state.get_workspace_state()
              if state then
                resurrect.state_manager.save_state(state, session_name)
                session_status.save_session_success(window, line)
              else
                session_status.save_session_error(window, "Ошибка сохранения")
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
end

-- Переключение на предыдущий workspace
M.switch_to_previous = function()
  return wezterm.action_callback(function(window, pane)
    session_status.set_mode("workspace_search")
    
    wezterm.time.call_after(0.2, function()
      window:perform_action(workspace_switcher.switch_to_prev_workspace(), pane)
    end)
  end)
end

-- Показ списка всех workspace
M.show_workspace_launcher = function()
  return wezterm.action_callback(function(window, pane)
    session_status.set_mode("workspace_search")
    
    wezterm.time.call_after(0.1, function()
      window:perform_action(
        wezterm.action.ShowLauncherArgs({ 
          flags = "FUZZY|WORKSPACES",
          title = "🏠 Выберите workspace"
        }), 
        pane
      )
    end)
  end)
end

-- === СОБЫТИЯ (интеграция с вашей системой) ===

M.setup_events = function()
  -- Событие начала поиска workspace
  wezterm.on('smart_workspace_switcher.workspace_switcher.start', function(window)
    wezterm.log_info("🔍 Workspace switcher запущен")
    -- Ваша система уже показывает режим, просто логируем
  end)
  
  -- Событие отмены поиска
  wezterm.on('smart_workspace_switcher.workspace_switcher.canceled', function(window)
    wezterm.log_info("❌ Workspace switcher отменен")
    if current_operation then
      session_status.clear_saved_mode() -- Очищаем режим при отмене
      current_operation = nil
    end
  end)
  
  -- Событие выбора workspace
  wezterm.on('smart_workspace_switcher.workspace_switcher.selected', function(window, workspace)
    wezterm.log_info("👆 Workspace выбран: " .. workspace)
    -- Можем показать промежуточную анимацию
  end)
  
  -- Событие успешного переключения на существующий workspace
  wezterm.on('smart_workspace_switcher.workspace_switcher.chosen', function(window, workspace)
    local workspace_name = workspace:match("([^/]+)$") or workspace
    wezterm.log_info("✅ Переключились на workspace: " .. workspace_name)
    
    -- Добавляем в историю
    table.insert(workspace_history, 1, workspace_name)
    if #workspace_history > 10 then
      table.remove(workspace_history)
    end
    
    -- Очищаем режим после успешного переключения
    if current_operation == "switch" then
      wezterm.time.call_after(0.5, function()
        session_status.clear_saved_mode()
        current_operation = nil
      end)
    end
  end)
  
  -- Событие создания нового workspace
  wezterm.on('smart_workspace_switcher.workspace_switcher.created', function(window, workspace)
    local workspace_name = workspace:match("([^/]+)$") or workspace
    wezterm.log_info("🆕 Создан новый workspace: " .. workspace_name)
    
    -- Добавляем в историю
    table.insert(workspace_history, 1, workspace_name)
    
    -- Показываем уведомление о создании
    wezterm.time.call_after(0.5, function()
      session_status.show_notification(window, "Создан: " .. workspace_name, "🆕", "#50fa7b", 2000, true)
      current_operation = nil
    end)
  end)
  
  -- Событие переключения на предыдущий workspace
  wezterm.on('smart_workspace_switcher.workspace_switcher.switched_to_prev', function(window)
    wezterm.log_info("⏪ Переключились на предыдущий workspace")
    
    wezterm.time.call_after(0.3, function()
      session_status.clear_saved_mode()
      current_operation = nil
    end)
  end)
  
  -- Интеграция с вашей системой статуса - показ текущего workspace
  if M.config.show_workspace_in_status then
    -- Расширяем вашу функцию get_status_elements
    local original_get_status = session_status.get_status_elements
    session_status.get_status_elements = function()
      local elements = original_get_status()
      
      -- Если нет активных режимов, показываем текущий workspace
      local has_active_mode = false
      for _, element in ipairs(elements) do
        if element.type == "mode" or element.type == "loading" then
          has_active_mode = true
          break
        end
      end
      
      if not has_active_mode then
        local workspace = wezterm.mux and wezterm.mux.get_active_workspace() or "default"
        local base_name = workspace:match("([^/]+)$") or workspace
        
        table.insert(elements, {
          type = "mode",
          icon = "󱂬",
          text = base_name,
          color = "#6272a4"
        })
      end
      
      return elements
    end
  end
end

-- === ИНИЦИАЛИЗАЦИЯ ===

M.setup = function(user_config)
  if user_config then
    for k, v in pairs(user_config) do
      M.config[k] = v
    end
  end
  
  workspace_switcher.zoxide_path = M.config.zoxide_path
  M.setup_events()
  
  wezterm.log_info("🚀 Workspace Manager инициализирован с интеграцией session-status")
  return M
end

return M
