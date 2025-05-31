-- cat > ~/.config/wezterm/events/session-status.lua << 'EOF'
--
-- ОПИСАНИЕ: Управление статусом сессий и режимов
-- Отслеживает текущий режим терминала и предоставляет элементы для строки состояния
-- ОБНОВЛЕНО: Использует централизованную систему иконок
--
-- ЗАВИСИМОСТИ: utils.debug, config.environment.icons, utils.environment

local wezterm = require('wezterm')
local debug = require("utils.debug")
local icons = require("config.environment.icons")
local env_utils = require("utils.environment")
local environment = require('config.environment')

local M = {}

-- Локальные переменные в модуле вместо глобальных
local session_state = {
  current_mode = nil,
  saved_mode = nil,
}

-- Получение данных режима из централизованной системы иконок
local function get_mode_data(mode_name)
  if env_utils.is_valid_category(icons, mode_name) then
    return {
      icon = env_utils.get_icon(icons, mode_name),
      name = "",
      color = env_utils.get_color(icons, mode_name)
    }
  end
  
  -- Fallback для неизвестных режимов
  return {
    icon = "?",
    name = "",
    color = "#FFFFFF"
  }
end

local function log_status()
end

M.set_mode = function(mode_name)
  debug.log(wezterm, environment.locale.t, "session_status", "debug_set_mode_called", tostring(mode_name))
  session_state.current_mode = mode_name
  session_state.saved_mode = mode_name
  log_status()
end

M.clear_mode = function()
  debug.log(wezterm, environment.locale.t, "session_status", "debug_clear_mode_called")
  session_state.current_mode = nil
  -- НЕ очищаем saved_mode здесь - только при завершении операций
  log_status()
end

M.clear_saved_mode = function()
  session_state.current_mode = nil
  session_state.saved_mode = nil
  log_status()
end

M.clear_all_modes = function()
  session_state.current_mode = nil
  session_state.saved_mode = nil
  log_status()
end

M.get_status_elements = function()
  local elements = {}
  
  -- Показываем saved_mode если он есть
  local mode_to_show = session_state.saved_mode
  if mode_to_show then
    local mode = get_mode_data(mode_to_show)
    table.insert(elements, {
      type = "mode",
      icon = mode.icon,
      text = mode.name,
      color = mode.color
    })
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
  log_status()
end

M.delete_session_start = function(window) 
  log_status()
end

M.start_loading = function(window) end
M.stop_loading = function(window) end
M.show_notification = function(window, message, icon, color, duration, hide_mode) end

M.load_session_list_shown = function(window, count) 
  log_status()
end

M.delete_session_list_shown = function(window, count) 
  log_status()
end

-- Функции с очисткой SAVED_MODE ТОЛЬКО при завершении операций
M.load_session_success = function(window, name) 
  M.clear_saved_mode() 
end

M.delete_session_success = function(window, name) 
  M.clear_saved_mode() 
end

M.save_session_success = function(window, name) 
  M.clear_saved_mode() 
end

M.load_session_cancelled = function(window) 
  M.clear_saved_mode() 
end

M.delete_session_cancelled = function(window) 
  M.clear_saved_mode() 
end

M.load_session_error = function(window, error_msg) 
  M.clear_saved_mode() 
end

M.save_session_error = function(window, error_msg) 
  M.clear_saved_mode() 
end

M.delete_session_error = function(window, error_msg) 
  M.clear_saved_mode() 
end

return M
