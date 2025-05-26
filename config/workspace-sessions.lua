-- ОПИСАНИЕ: Интегрированное управление workspace с автосохранением и восстановлением
-- Объединяет smart_workspace_switcher с resurrect для полной системы управления сессиями

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
  max_sessions_per_workspace = 5,
  show_workspace_in_status = true,
}

-- Локальные переменные
local current_workspace = nil
local workspace_sessions = {}
local current_operation = nil

-- Инициализация workspace switcher
workspace_switcher.zoxide_path = M.config.zoxide_path

-- Настройка resurrect для workspace
resurrect.state_manager.periodic_save({
  interval_seconds = 600,
  save_tabs = true,
  save_windows = true,
  save_workspaces = true,
})

-- === ОСНОВНЫЕ ФУНКЦИИ ===

M.get_current_workspace = function()
  if wezterm.mux and wezterm.mux.get_active_workspace then
    return wezterm.mux.get_active_workspace()
  end
  return "default"
end

M.generate_session_name = function(workspace_name, suffix)
  suffix = suffix or os.date("%Y%m%d_%H%M")
  return M.config.session_prefix .. workspace_name .. "_" .. suffix
end

M.auto_save_workspace = function(workspace_name)
  if not M.config.auto_save_on_switch then return end
  
  workspace_name = workspace_name or M.get_current_workspace()
  local session_name = M.generate_session_name(workspace_name, "auto")
  
  wezterm.log_info("🔄 Автосохранение workspace: " .. workspace_name)
  session_status.start_loading(wezterm.mux.get_active_window())
  
  local state = resurrect.workspace_state.get_workspace_state()
  if state then
    resurrect.state_manager.save_state(state, session_name)
    
    if not workspace_sessions[workspace_name] then
      workspace_sessions[workspace_name] = {}
    end
    table.insert(workspace_sessions[workspace_name], 1, session_name)
    
    while #workspace_sessions[workspace_name] > M.config.max_sessions_per_workspace do
      table.remove(workspace_sessions[workspace_name])
    end
    
    session_status.save_session_success(wezterm.mux.get_active_window(), workspace_name .. " (auto)")
  end
end

M.smart_switch_workspace = function()
  return wezterm.action_callback(function(window, pane)
    local old_workspace = M.get_current_workspace()
    
    -- Устанавливаем режим workspace_search перед началом
    session_status.set_mode("workspace_search")
    current_operation = "switch"
    
    -- Автосохраняем текущий workspace
    if M.config.auto_save_on_switch then
      M.auto_save_workspace(old_workspace)
      
      -- Небольшая задержка для завершения автосохранения
      wezterm.time.call_after(1, function()
        window:perform_action(workspace_switcher.switch_workspace(), pane)
      end)
    else
      window:perform_action(workspace_switcher.switch_workspace(), pane)
    end
  end)
end

M.list_workspace_sessions = function()
  return wezterm.action_callback(function(window, pane)
    local workspace_name = M.get_current_workspace()
    local sessions = workspace_sessions[workspace_name] or {}
    
    session_status.set_mode("session_control")
    
    if #sessions == 0 then
      session_status.load_session_error(window, "Нет сохраненных сессий")
      return
    end
    
    session_status.load_session_start(window)
    
    local choices = {}
    for i, session_name in ipairs(sessions) do
      table.insert(choices, {
        id = tostring(i),
        label = session_name:gsub(M.config.session_prefix, ""):gsub(workspace_name .. "_", ""),
      })
    end
    
    window:perform_action(
      wezterm.action.InputSelector({
        action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
          if id then
            local session_index = tonumber(id)
            M.restore_workspace_session(workspace_name, session_index, inner_window)
          else
            session_status.load_session_cancelled(window)
          end
        end),
        title = "Сессии для workspace: " .. workspace_name,
        choices = choices,
        fuzzy = true,
      }),
      pane
    )
  end)
end

M.restore_workspace_session = function(workspace_name, session_index, window)
  session_index = session_index or 1
  window = window or wezterm.mux.get_active_window()
  
  if not workspace_sessions[workspace_name] or #workspace_sessions[workspace_name] == 0 then
    session_status.load_session_error(window, "Нет сохраненных сессий")
    return false
  end
  
  local session_name = workspace_sessions[workspace_name][session_index]
  if not session_name then
    session_status.load_session_error(window, "Сессия не найдена")
    return false
  end
  
  session_status.start_loading(window)
  
  wezterm.time.call_after(0.5, function()
    local state = resurrect.state_manager.load_state(session_name:gsub(M.config.session_prefix, ""), "workspace")
    if state then
      resurrect.workspace_state.restore_workspace(state, {
        relative = false,
        restore_text = true,
      })
      local display_name = session_name:gsub(M.config.session_prefix .. workspace_name .. "_", "")
      session_status.load_session_success(window, display_name)
    else
      session_status.load_session_error(window, "Ошибка восстановления")
    end
  end)
  
  return true
end

M.save_workspace_session = function()
  return wezterm.action_callback(function(window, pane)
    local workspace_name = M.get_current_workspace()
    
    session_status.set_mode("session_control")
    current_operation = "save"
    
    window:perform_action(
      wezterm.action.PromptInputLine({
        description = "Имя для сохранения workspace '" .. workspace_name .. "':",
        action = wezterm.action_callback(function(inner_window, inner_pane, line)
          if line and line ~= "" then
            session_status.start_loading(window)
            
            local session_name = M.generate_session_name(workspace_name, line)
            
            wezterm.time.call_after(0.2, function()
              local state = resurrect.workspace_state.get_workspace_state()
              if state then
                resurrect.state_manager.save_state(state, session_name)
                
                if not workspace_sessions[workspace_name] then
                  workspace_sessions[workspace_name] = {}
                end
                table.insert(workspace_sessions[workspace_name], 1, session_name)
                
                session_status.save_session_success(window, line)
                wezterm.log_info("💾 Workspace сохранен: " .. session_name)
              else
                session_status.save_session_error(window, "Ошибка получения состояния")
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

-- === СОБЫТИЯ ===

M.setup_events = function()
  wezterm.on('smart_workspace_switcher.workspace_switcher.chosen', function(window, workspace)
    current_workspace = workspace:match("([^/]+)$")
    wezterm.log_info("🏠 Переключение на workspace: " .. current_workspace)
    
    if current_operation == "switch" then
      -- Очищаем режим после успешного переключения
      wezterm.time.call_after(0.5, function()
        session_status.clear_saved_mode()
        current_operation = nil
      end)
    end
  end)
  
  wezterm.on('smart_workspace_switcher.workspace_switcher.created', function(window, workspace)
    current_workspace = workspace:match("([^/]+)$")
    wezterm.log_info("🆕 Создан workspace: " .. current_workspace)
    
    if current_operation == "switch" then
      wezterm.time.call_after(0.5, function()
        session_status.clear_saved_mode()
        current_operation = nil
      end)
    end
  end)
  
  -- Показ workspace в статусе (интегрируется с существующей системой)
  if M.config.show_workspace_in_status then
    local original_get_status = session_status.get_status_elements
    session_status.get_status_elements = function()
      local elements = original_get_status()
      
      -- Добавляем workspace info если нет других активных режимов
      local has_mode = false
      for _, element in ipairs(elements) do
        if element.type == "mode" or element.type == "loading" then
          has_mode = true
          break
        end
      end
      
      if not has_mode then
        local workspace = M.get_current_workspace()
        local base_path = workspace:match("([^/]+)$") or workspace
        table.insert(elements, {
          type = "mode",
          icon = "󱂬",
          text = base_path,
          color = "#50fa7b"
        })
      end
      
      return elements
    end
  end
end

M.setup = function(user_config)
  if user_config then
    for k, v in pairs(user_config) do
      M.config[k] = v
    end
  end
  
  workspace_switcher.zoxide_path = M.config.zoxide_path
  M.setup_events()
  
  wezterm.log_info("🚀 Workspace Sessions инициализован")
  return M
end

return M
