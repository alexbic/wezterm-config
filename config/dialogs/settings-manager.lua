-- config/dialogs/settings-manager.lua  
-- ОПИСАНИЕ: Главное меню F10 единого центра управления (ТОЛЬКО ДАННЫЕ)
-- АРХИТЕКТУРА: Все иконки только через environment.icons.t.key

local M = {}

-- === ОСНОВНЫЕ ДАННЫЕ МЕНЮ F10 ===
M.title_key = "settings_manager_title"
M.description_key = "settings_manager_description"

-- === СТРУКТУРА МЕНЮ F10 ===
M.menu_items = {
  -- ГОТОВЫЕ МОДУЛИ  
  {
    id = "locale_settings",
    icon_key = "locale_manager",
    title_key = "locale_manager_title", 
    description_key = "locale_manager_description",
    status = "ready",
    module_type = "existing",
    target = "locale_manager"
  },
  
  {
    id = "debug_settings", 
    icon_key = "debug",
    title_key = "debug_panel_title",
    description_key = "debug_panel_description", 
    status = "ready",
    module_type = "existing", 
    target = "debug_manager"
  },
  
  {
    id = "state_settings",
    icon_key = "session", 
    title_key = "state_manager_title",
    description_key = "state_manager_description",
    status = "ready",
    module_type = "existing",
    target = "state_manager"
  },
  
  -- МОДУЛИ В РАЗРАБОТКЕ
  {
    id = "keybind_settings",
    icon_key = "pane_control",
    title_key = "keybind_settings_title",
    description_key = "keybind_settings_description", 
    status = "planned",
    module_type = "planned"
  },
  
  {
    id = "appearance_settings",
    icon_key = "appearance", 
    title_key = "appearance_settings_title",
    description_key = "appearance_settings_description",
    status = "planned",
    module_type = "planned"
  },
  
  {
    id = "global_settings",
    icon_key = "system",
    title_key = "global_settings_title", 
    description_key = "global_settings_description",
    status = "planned",
    module_type = "planned"
  },
  
  {
    id = "export_import",
    icon_key = "input",
    title_key = "export_import_title",
    description_key = "export_import_description",
    status = "planned", 
    module_type = "planned"
  },
  
  {
    id = "help_f1_f12",
    icon_key = "tip",
    title_key = "help_f1_f12_title",
    description_key = "help_f1_f12_description",
    status = "planned",
    module_type = "planned"
  },
  
  -- МОДУЛИ V2.0  
  {
    id = "ai_settings",
    icon_key = "platform",
    title_key = "ai_settings_title",
    description_key = "ai_settings_description",
    status = "v2_0",
    module_type = "future"
  }
}

-- === НАСТРОЙКИ ИНТЕРФЕЙСА ===
M.interface_config = {
  show_header = false,
  fuzzy_search = true,
  show_descriptions = true,
  group_by_status = false,
  show_status_icons = true,
  remove_numbering = true
}

-- === КЛЮЧИ СТАТУСОВ (для функций в utils/dialogs.lua) ===
M.status_config = {
  ready_icon_key = "system",      -- environment.icons.t.system
  planned_icon_key = "mode",      -- environment.icons.t.mode  
  v2_0_icon_key = "platform"     -- environment.icons.t.platform
}

return M
