-- Шаблон InputSelector диалогов (списки с выбором)
local M = {}

-- СТРУКТУРА ДАННЫХ для InputSelector
M.structure = {
  -- Метаданные диалога
  meta = {
    title_key = "",           -- ключ заголовка в локализации
    description = "",         -- описание диалога
    tab_title_key = "",       -- ключ названия вкладки
    fuzzy = true             -- поиск в диалоге
  },
  
  -- БЛОК 1: Основные пункты (в рамках, с нумерацией 1-N)
  main_items = {
    -- { 
    --   id = "module_name", 
    --   text_key = "ключ_в_локализации",
    --   icon_key = "ключ_иконки",
    --   state_check = "function_name", -- функция проверки состояния
    --   color_active = "#FFFFFF",      -- цвет когда активно
    --   color_inactive = "#808080"     -- цвет когда неактивно
    -- }
  },
  
  -- БЛОК 2: Служебные команды (под рамкой, БЕЗ нумерации)
  service_items = {
    -- {
    --   id = "enable_all",
    --   text_key = "ключ_команды",
    --   icon_key = "ключ_иконки", 
    --   color = "#50FA7B"
    -- }
  },
  
  -- Стандартные служебные команды (автоматически добавляются)
  standard_commands = {
    exit = { id = "exit", text_key = "exit", icon_key = "exit", color = "#FFFFFF" }
  },
  
  -- ЦВЕТОВАЯ СХЕМА
  colors = {
    separator = "#FFFFFF",
    border = "#FFFFFF"
  }
}

-- Пример конфигурации отладки
M.debug_config = {
  meta = {
    title_key = "debug_panel_title",
    description = "",
    tab_title_key = "debug_panel_short",
    fuzzy = true
  },
  
  main_items = {
    { id = "appearance", text_key = "appearance_debug_desc", icon_key = "system", state_check = "debug.DEBUG_CONFIG.appearance" },
    { id = "bindings", text_key = "bindings_debug_desc", icon_key = "system", state_check = "debug.DEBUG_CONFIG.bindings" },
    { id = "global", text_key = "global_debug_desc", icon_key = "system", state_check = "debug.DEBUG_CONFIG.global" },
    { id = "resurrect", text_key = "resurrect_debug_desc", icon_key = "system", state_check = "debug.DEBUG_CONFIG.resurrect" },
    { id = "session_status", text_key = "session_debug_desc", icon_key = "system", state_check = "debug.DEBUG_CONFIG.session_status" },
    { id = "workspace", text_key = "workspace_debug_desc", icon_key = "system", state_check = "debug.DEBUG_CONFIG.workspace" }
  },
  
  service_items = {
    { id = "enable_all", text_key = "debug_enable_all_modules", icon_key = "system", color = "#FFFFFF" },
    { id = "disable_all", text_key = "debug_disable_all_modules", icon_key = "error", color = "#FFFFFF" }
  }
}

return M
