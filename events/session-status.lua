local wezterm = require('wezterm')
local debug = require("utils.debug")

local M = {}

-- Локальные переменные в модуле вместо глобальных
local session_state = {
  current_mode = nil,
  saved_mode = nil,
}

-- Иконки режимов
local mode_icons = {
  session_control = { icon = "◎", name = "", color = "#4ECDC4" },
  pane_control = { icon = "◫", name = "", color = "#4ECDC4" },
  font_control = { icon = "ƒ", name = "", color = "#4ECDC4" },
  workspace_search = { icon = "🔍", name = "", color = "#F1FA8C" },}

local function log_status()
end

M.set_mode = function(mode_name)
  debug.log("session_status", "debug_set_mode_called", tostring(mode_name))
  session_state.current_mode = mode_name
  session_state.saved_mode = mode_name
  log_status()
end

M.clear_mode = function()
  debug.log("session_status", "debug_clear_mode_called")
  session_state.current_mode = nil
  -- НЕ очищаем saved_mode здесь - только при завершении операций
  log_status()
end

M.clear_saved_mode = function()
  wezterm.log_info("🚨 SESSION-STATUS clear_saved_mode вызван")
  session_state.current_mode = nil
  session_state.saved_mode = nil
  log_status()
end

M.clear_all_modes = function()
  wezterm.log_info("🚨 SESSION-STATUS clear_all_modes вызван")
  session_state.current_mode = nil
  session_state.saved_mode = nil
  log_status()
end

M.get_status_elements = function()
  local elements = {}
  
  
  -- Показываем saved_mode если он есть
  local mode_to_show = session_state.saved_mode
  if mode_to_show and mode_icons[mode_to_show] then
    local mode = mode_icons[mode_to_show]
    table.insert(elements, {
      type = "mode",
      icon = mode.icon,
      text = mode.name,
      color = mode.color
    })
  else
  end
  
  return elements
end

-- Функция для отладки - возвращает текущее состояние
M.get_debug_state = function()
  return {
    current_mode = session_state.current_mode,
    saved_mode = session_state.saved_mode
  }
end

-- Минимальные заглушки для операций - НЕ очищают saved_mode
M.load_session_start = function(window) 
  wezterm.log_info("🚨 SESSION-STATUS load_session_start - НЕ очищаем режим")
  log_status()
end

M.delete_session_start = function(window) 
  wezterm.log_info("🚨 SESSION-STATUS delete_session_start - НЕ очищаем режим")
  log_status()
end

M.start_loading = function(window) end
M.stop_loading = function(window) end
M.show_notification = function(window, message, icon, color, duration, hide_mode) end

M.load_session_list_shown = function(window, count) 
  wezterm.log_info("🚨 SESSION-STATUS load_session_list_shown - НЕ очищаем режим")
  log_status()
end

M.delete_session_list_shown = function(window, count) 
  wezterm.log_info("🚨 SESSION-STATUS delete_session_list_shown - НЕ очищаем режим")
  log_status()
end

-- Функции с очисткой SAVED_MODE ТОЛЬКО при завершении операций
M.load_session_success = function(window, name) 
  wezterm.log_info("🚨 SESSION-STATUS load_session_success - очищаем saved_mode")
  M.clear_saved_mode() 
end

M.delete_session_success = function(window, name) 
  wezterm.log_info("🚨 SESSION-STATUS delete_session_success - очищаем saved_mode")
  M.clear_saved_mode() 
end

M.save_session_success = function(window, name) 
  wezterm.log_info("🚨 SESSION-STATUS save_session_success - очищаем saved_mode")
  M.clear_saved_mode() 
end

M.load_session_cancelled = function(window) 
  wezterm.log_info("🚨 SESSION-STATUS load_session_cancelled - очищаем saved_mode")
  M.clear_saved_mode() 
end

M.delete_session_cancelled = function(window) 
  wezterm.log_info("🚨 SESSION-STATUS delete_session_cancelled - очищаем saved_mode")
  M.clear_saved_mode() 
end

M.load_session_error = function(window, error_msg) 
  wezterm.log_info("🚨 SESSION-STATUS load_session_error - очищаем saved_mode")
  M.clear_saved_mode() 
end

M.save_session_error = function(window, error_msg) 
  wezterm.log_info("🚨 SESSION-STATUS save_session_error - очищаем saved_mode")
  M.clear_saved_mode() 
end

M.delete_session_error = function(window, error_msg) 
  wezterm.log_info("🚨 SESSION-STATUS delete_session_error - очищаем saved_mode")
  M.clear_saved_mode() 
end

return M
