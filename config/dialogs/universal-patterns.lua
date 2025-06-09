-- УНИВЕРСАЛЬНЫЕ ПАТТЕРНЫ ДИАЛОГОВ

local M = {}

M.DIALOG_COLORS = {
  workspace = { border = "dialog_workspace_border", tab_color = "save_workspace_tab" },
  window = { border = "dialog_window_border", tab_color = "save_window_tab" },
  tab = { border = "dialog_tab_border", tab_color = "save_tab_tab" },
  load = { border = "dialog_load_border", tab_color = "list_picker_tab" },
  delete = { border = "dialog_delete_border", tab_color = "list_delete_tab" }
}

M.ACTION_ICONS = {
  save = "workspace", load = "list_picker_tab", delete = "list_delete_tab",
  settings = "system", debug = "debug", locale = "locale_manager"
}

M.DIALOG_SIZES = {
  small = { min_width = 40, max_width = 60 },
  medium = { min_width = 50, max_width = 80 },
  large = { min_width = 60, max_width = 100 }
}

M.STANDARD_COMMANDS = {
  exit = { id = "exit", icon_key = "exit", text_key = "exit" },
  back = { id = "back", icon_key = "exit", text_key = "back_to_main_menu" },
  help = { id = "help", icon_key = "tip", text_key = "help" }
}

return M
