local M = {}

M.meta = {
  title_key = "locale_manager_wezterm_title",
  icon_key = "locale_manager",
  description = "",
  tab_title_key = "locale_manager_title", 
  fuzzy = true
}

M.main_items = {
  { id = "current_lang", text_key = "locale_current_language", icon_key = "locale_current", target = "locale_manager" },
  { id = "regenerate", text_key = "locale_regenerate_cache", icon_key = "locale_refresh", target = "locale_manager" },
  { id = "emergency_fix", text_key = "locale_create_new", icon_key = "locale_emergency", target = "locale_manager" }
}

M.service_items = {}

return M
