local M = {}
M.show_panel = function(window, pane)
  local dialogs = require('utils.dialogs')
  dialogs.show_debug_panel(require('wezterm'), window, pane)
end
M.create_panel = M.show_panel
return M
