--
-- ОПИСАНИЕ: UI управления локализацией с fallback защитой
--
local wezterm = require('wezterm')
local environment = require("config.environment")
local env_utils = require('utils.environment')
local globals = require('config.environment.globals')
local dialog = require('utils.dialog')

local M = {}

-- FALLBACK тексты на случай поломки локализации
local FALLBACK_TEXTS = {
  locale_manager_title = "Управление локализацией",
  locale_manager_wezterm_title = "Менеджер локализации WezTerm", 
  locale_manager_description = "Выберите действие для управления языками",
  locale_current_language = "Текущий язык",
  locale_create_new = "Создать новую локаль",
  locale_regenerate_cache = "Перегенерировать кэш текущего языка",
  locale_show_stats = "Показать статистику локализации",
  exit = "Выход"
}

-- Безопасная функция получения текста с fallback
local function safe_get_text(key, ...)
  local text = (environment.locale and environment.locale.t and environment.locale.t[key]) or FALLBACK_TEXTS[key] or key
  if ... then
    return string.format(text, ...)
  else
    return text
  end
end

-- Главная функция показа менеджера локализации
M.show_locale_manager = function(window, pane)
  local create_platform_info = require('utils.platform')
  local platform = create_platform_info(wezterm.target_triple)
  
  -- Получаем данные о языках
  local available_languages = env_utils.scan_locale_files(wezterm.config_dir, platform)
  local stats = env_utils.get_locale_stats(available_languages)
  local current_language = (environment.locale and environment.locale.current_language) or "ru"
  
  -- Создаем choices с fallback защитой
  local choices = {}
  
  -- Заголовок
  table.insert(choices, dialog.create_choice({
    id = "header",
    icon = environment.icons.t."system",
    text = safe_get_text("locale_manager_title"),
    colored = true,
    color = "#BD93F9"
  }))
  
  -- Текущий язык
  table.insert(choices, dialog.create_choice({
    id = "current", 
    icon = environment.icons.t."locale_current",
    text = safe_get_text("locale_current_language", current_language)
  }))
  
  -- Команда экстренного восстановления
  table.insert(choices, dialog.create_choice({
    id = "emergency_fix",
    icon = environment.icons.t."locale_emergency",
    text = "Экстренное восстановление ru.lua"
  }))
  
  -- Доступные языки
  for _, lang_code in ipairs(globals.SUPPORTED_LANGUAGES) do
    if available_languages[lang_code] then
      local lang_data = available_languages[lang_code]
      local key_count = stats.languages[lang_code] and stats.languages[lang_code].keys or 0
      local status_icon = (lang_code == current_language) and "🟢" or "⚪"
      
      table.insert(choices, dialog.create_choice({
        id = "switch_" .. lang_code,
        icon = status_icon,
        text = string.format("%s (%s) - %d ключей", lang_data.name, lang_code, key_count)
      }))
    else
      table.insert(choices, dialog.create_choice({
        id = "create_" .. lang_code,
        icon = environment.icons.t."locale_create", 
        text = safe_get_text("locale_create_new", lang_code)
      }))
    end
  end
  
  -- Управляющие команды
  table.insert(choices, dialog.create_choice({
    id = "regenerate",
    icon = environment.icons.t."locale_refresh",
    text = safe_get_text("locale_regenerate_cache")
  }))
  
  table.insert(choices, dialog.create_choice({
    id = "exit",
    icon = environment.icons.t."exit", 
    text = safe_get_text("exit")
  }))
  
  -- Создаем InputSelector
  local selector_config = dialog.create_input_selector({
    title = safe_get_text("locale_manager_wezterm_title"),
    description = safe_get_text("locale_manager_description"),
    choices = choices,
    action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
      if not id or id == "exit" or id == "header" or id == "current" then
        return
      end
      
      if id == "emergency_fix" then
        -- ЭКСТРЕННОЕ ВОССТАНОВЛЕНИЕ
        local success = env_utils.rebuild_locale_cache_file(wezterm.config_dir, platform, "ru")
        if success then
          inner_window:toast_notification("Восстановление", "Восстановлено на русский язык", nil, 3000)
          wezterm.reload_configuration()
        end
        
      elseif id:match("^switch_") then
        -- Переключение языка с пересозданием
        local lang_code = id:match("^switch_(.+)$")
        if lang_code and lang_code ~= current_language then
          -- ПЕРЕСОЗДАЕМ локаль перед переключением
          if lang_code ~= "ru" then
            local script_path = wezterm.config_dir .. "/scripts/create-locale.sh"
            local ru_path = wezterm.config_dir .. "/config/locales/ru.lua"
            local cmd = script_path .. " " .. ru_path .. " " .. lang_code
            os.execute(cmd)
          end
          
          local success = env_utils.switch_language_and_rebuild(wezterm.config_dir, platform, lang_code)
          if success then
            inner_window:toast_notification("Локализация", "Язык переключен на: " .. lang_code, nil, 3000)
            wezterm.reload_configuration()
          end
        end
        
      elseif id:match("^create_") then
        -- Создание нового языка  
        local lang_code = id:match("^create_(.+)$")
        local script_path = wezterm.config_dir .. "/scripts/create-locale.sh"
        local ru_path = wezterm.config_dir .. "/config/locales/ru.lua"
        local cmd = script_path .. " " .. ru_path .. " " .. lang_code
        local handle = io.popen(cmd .. " 2>&1")
        if handle then
          local result = handle:read("*a")
          local success = handle:close()
          if success then
            inner_window:toast_notification("Успех", "Локаль создана", nil, 3000)
            env_utils.switch_language_and_rebuild(wezterm.config_dir, platform, lang_code)
            wezterm.reload_configuration()
          end
        end
        
      elseif id == "regenerate" then
        -- Перегенерация кэша
        local success = env_utils.rebuild_locale_cache_file(wezterm.config_dir, platform, current_language)
        if success then
          inner_window:toast_notification("Локализация", "Кэш перегенерирован", nil, 3000)
          wezterm.reload_configuration()
        end
      end
    end)
  })
  
  window:perform_action(wezterm.action.InputSelector(selector_config), pane)
end

return M
