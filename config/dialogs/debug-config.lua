local M = {}

M.meta = {
  title_key = "debug_panel_title",
  description = "",
  tab_title_key = "debug_panel_short", 
  fuzzy = true
}

M.main_items = {
  { id = "appearance", text_key = "appearance_settings_description", icon_key = "appearance", target = "debug_manager" },
  { id = "bindings", text_key = "keybind_settings_description", icon_key = "pane_control", target = "debug_manager" },
  { id = "global", text_key = "global_settings_description", icon_key = "system", target = "debug_manager" },
  { id = "resurrect", text_key = "states_manager_description", icon_key = "session", target = "debug_manager" },
  { id = "session_status", text_key = "debug_panel_description", icon_key = "mode", target = "debug_manager" },
  { id = "workspace", text_key = "workspace_switch_description", icon_key = "workspace", target = "debug_manager" }
}

M.service_items = {
  { id = "enable_all", text_key = "debug_enable_all_modules", icon_key = "system", target = "debug_manager" },
  { id = "disable_all", text_key = "debug_disable_all_modules", icon_key = "error", target = "debug_manager" }
}

return M
