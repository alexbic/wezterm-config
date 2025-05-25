local wezterm = require('wezterm')
local M = {}

-- Инициализация ТОЛЬКО если еще не существует
if not wezterm.GLOBALS then wezterm.GLOBALS = {} end
if not wezterm.GLOBALS.session_status then
  wezterm.GLOBALS.session_status = {
    current_mode = nil,
    saved_mode = nil,
  }
end

-- Иконки режимов
local mode_icons = {
  session_control = { icon = "◎", name = "", color = "#4ECDC4" },
  pane_control = { icon = "◫", name = "", color = "#4ECDC4" },
  font_control = { icon = "ƒ", name = "", color = "#4ECDC4" }
}

M.set_mode = function(mode_name)
  wezterm.GLOBALS.session_status.current_mode = mode_name
  wezterm.GLOBALS.session_status.saved_mode = mode_name
end

M.clear_mode = function()
  wezterm.GLOBALS.session_status.current_mode = nil
end

M.clear_saved_mode = function()
  wezterm.GLOBALS.session_status.current_mode = nil
  wezterm.GLOBALS.session_status.saved_mode = nil
end

M.clear_all_modes = function()
  -- Заглушка - не делаем ничего
end

M.get_status_elements = function()
  local status = wezterm.GLOBALS.session_status
  local elements = {}
  
  local mode_to_show = status.saved_mode
  if mode_to_show and mode_icons[mode_to_show] then
    local mode = mode_icons[mode_to_show]
    table.insert(elements, {
      type = "mode",
      icon = mode.icon,
      text = mode.name,
      color = mode.color
    })
  end
  
  return elements
end

-- Минимальные заглушки для операций
M.load_session_start = function(window) end
M.delete_session_start = function(window) end
M.start_loading = function(window) end
M.stop_loading = function(window) end
M.show_notification = function(window, message, icon, color, duration, hide_mode) end

-- Функции с очисткой режима
M.load_session_success = function(window, name) M.clear_saved_mode() end
M.delete_session_success = function(window, name) M.clear_saved_mode() end
M.save_session_success = function(window, name) M.clear_saved_mode() end
M.load_session_cancelled = function(window) M.clear_saved_mode() end
M.delete_session_cancelled = function(window) M.clear_saved_mode() end
M.load_session_error = function(window, error_msg) M.clear_saved_mode() end
M.save_session_error = function(window, error_msg) M.clear_saved_mode() end
M.delete_session_error = function(window, error_msg) M.clear_saved_mode() end

return M
