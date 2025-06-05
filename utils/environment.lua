-- cat > ~/.config/wezterm/utils/environment.lua << 'EOF'
--
-- ОПИСАНИЕ: Утилиты для работы с окружением WezTerm
-- Централизованные функции для работы с путями, локалью, переменными окружения, локализацией и иконками.
-- САМОДОСТАТОЧНЫЙ МОДУЛЬ - НЕ ТРЕБУЕТ ДРУГИХ МОДУЛЕЙ
--
-- ЗАВИСИМОСТИ: НЕТ

local M = {}

-- ========================================
-- РАБОТА С ФАЙЛОВОЙ СИСТЕМОЙ
-- ========================================

-- Функция для проверки существования директории
M.dir_exists = function(path)
  local ok, err, code = os.rename(path, path)
  if not ok then
    if code == 13 then
      return true -- Permission denied, but exists
    end
    return false
  end
  return true
end

-- Функция для получения переменной окружения
M.getenv = function(var)
  return os.getenv(var)
end

-- ========================================
-- СКАНИРОВАНИЕ ФАЙЛОВ ЛОКАЛЕЙ
-- ========================================

-- Функция автосканирования файлов локалей (САМОДОСТАТОЧНАЯ)
M.scan_locale_files = function(config_dir, platform_utils)
  local available_languages = {}
  local locales_dir = config_dir .. "/config/locales"
  
  -- Проверяем существование директории
  if not platform_utils.directory_exists(locales_dir) then
    return available_languages
  end
  
  -- Получаем все .lua файлы
  local lua_files = platform_utils.get_files_in_directory(locales_dir, "*.lua")
  
  for _, file_path in ipairs(lua_files) do
    local filename = file_path:match("([^/\\]+)%.lua$")
    
    -- Пропускаем служебные файлы
    if filename and not filename:match("manager") and not filename:match("init") then
      local success, locale_data = pcall(dofile, file_path)
      
      if success and locale_data and locale_data.locale and locale_data.name then
        available_languages[filename] = locale_data
      end
    end
  end
  
  return available_languages
end

-- Функция получения статистики локализации (САМОДОСТАТОЧНАЯ)
M.get_locale_stats = function(available_languages)
  local stats = {
    total_languages = 0,
    languages = {},
    total_keys = 0
  }
  
  for code, data in pairs(available_languages) do
    local key_count = 0
    for _ in pairs(data) do
      key_count = key_count + 1
    end
    key_count = key_count - 2 -- Исключаем locale и name
    
    stats.languages[code] = {
      name = data.name,
      locale = data.locale,
      keys = key_count
    }
    stats.total_languages = stats.total_languages + 1
    stats.total_keys = math.max(stats.total_keys, key_count)
  end
  
  return stats
end

-- ========================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ДЛЯ КЭШИРОВАНИЯ
-- ========================================

-- ИСПРАВЛЕННАЯ функция преобразования таблицы в строку Lua
M.table_to_lua_string = function(tbl, indent)
  indent = indent or 0
  local spaces = string.rep("  ", indent)
  local result = "{\n"
  
  for k, v in pairs(tbl) do
    local key_str
    if type(k) == "string" then
      -- Проверяем, является ли ключ валидным идентификатором Lua
      if k:match("^[a-zA-Z_][a-zA-Z0-9_]*$") then
        key_str = k  -- Простой идентификатор без кавычек
      else
        key_str = '["' .. k:gsub('"', '\\"') .. '"]'  -- С кавычками и экранированием
      end
    else
      key_str = "[" .. tostring(k) .. "]"
    end
    
    local value_str
    if type(v) == "string" then
      value_str = '"' .. v:gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
    elseif type(v) == "table" then
      value_str = M.table_to_lua_string(v, indent + 1)
    elseif type(v) == "boolean" then
      value_str = tostring(v)
    elseif type(v) == "number" then
      value_str = tostring(v)
    else
      value_str = '"' .. tostring(v) .. '"'
    end
    
    result = result .. spaces .. "  " .. key_str .. " = " .. value_str .. ",\n"
  end
  
  result = result .. spaces .. "}"
  return result
end

-- Создание настроек локали из данных языка
M.create_locale_settings_from_data = function(language_data)
  return {
    LANG = language_data.locale,
    LC_ALL = language_data.locale,
    LC_TIME = language_data.locale,
    LC_NUMERIC = language_data.locale,
    LC_MONETARY = language_data.locale,
  }
end

-- ========================================
-- СИСТЕМА КЭШИРОВАНИЯ ЛОКАЛИЗАЦИИ
-- ========================================

-- Генерация кэшированного файла локализации
M.generate_locale_cache = function(config_dir, platform_utils, language_code)
  local available_languages = M.scan_locale_files(config_dir, platform_utils)
  local target_language = available_languages[language_code]
  
  if not target_language then
    return false, "Language not found: " .. language_code
  end
  
  -- Создаем кэшированную таблицу
  local cache_content = {
    current_language = language_code,
    t = {},
    settings = M.create_locale_settings_from_data(target_language)
  }
  
  -- Копируем все ключи кроме служебных
  for key, value in pairs(target_language) do
    if key ~= "locale" and key ~= "name" then
      cache_content.t[key] = value
    end
  end
  
  return cache_content
end

-- ИСПРАВЛЕННАЯ функция перезаписи файла кэша локализации
M.rebuild_locale_cache_file = function(config_dir, platform_utils, language_code)
  local cache_content, error_msg = M.generate_locale_cache(config_dir, platform_utils, language_code)
  
  if not cache_content then
    return false, error_msg
  end
  
  local locale_file_path = config_dir .. "/config/environment/locale.lua"
  
  local file_content = string.format([[-- Кэшированная локализация WezTerm
-- Текущий язык: %s
-- Сгенерировано: %s

return {
  current_language = "%s",
  t = %s,
  settings = %s
}
]], cache_content.current_language, os.date("%Y-%m-%d %H:%M:%S"), 
    cache_content.current_language, 
    M.table_to_lua_string(cache_content.t),
    M.table_to_lua_string(cache_content.settings))
  
  local file = io.open(locale_file_path, "w")
  if not file then
    return false, "Cannot write to file: " .. locale_file_path
  end
  
  file:write(file_content)
  file:close()
  
  return true
end

-- Переключение языка с перестройкой кэша
M.switch_language_and_rebuild = function(config_dir, platform_utils, new_language)
  local success, error_msg = M.rebuild_locale_cache_file(config_dir, platform_utils, new_language)
  if not success then
    return false, error_msg or "Unknown error during cache rebuild"
  end
  return true
end

-- ========================================
-- ЛОКАЛИЗАЦИЯ И ПЕРЕВОДЫ (СТАРЫЕ ФУНКЦИИ)
-- ========================================

-- Функция перевода ключей
M.translate = function(available_languages, key, ...)
  local default_language = os.getenv("WEZTERM_LANG") or "ru"
  local lang_table = available_languages[default_language] or available_languages["ru"]
  local template = lang_table[key] or key
  
  if ... then
    return string.format(template, ...)
  else
    return template
  end
end

-- Функция получения языковой таблицы
M.get_language_table = function(available_languages)
  local default_language = os.getenv("WEZTERM_LANG") or "ru"
  return available_languages[default_language] or available_languages["ru"]
end
-- Функция создания настроек локали (БЕЗ логирования)
end
M.create_locale_settings = function(available_languages)
  local default_language = os.getenv("WEZTERM_LANG") or "ru"
  local lang_table = available_languages[default_language] or available_languages["ru"]
  local locale_config = {
    force_language = default_language,
    force_locale = lang_table.locale or "ru_RU.UTF-8"
  }
  
  return {
    LANG = locale_config.force_locale,
    LC_ALL = locale_config.force_locale,
    LC_TIME = locale_config.force_locale,
    LC_NUMERIC = locale_config.force_locale,
    LC_MONETARY = locale_config.force_locale,
  }
end

-- ========================================
-- РАБОТА С ИКОНКАМИ И ФОРМАТИРОВАНИЕМ
-- ========================================

-- Получить иконку для категории
end
M.get_icon = function(icons_data, category)
  return icons_data.ICONS[category] or "?"
end

-- Получить HEX цвет для категории из отдельного модуля colors
end
M.get_color = function(colors_data, category)
  return colors_data.COLORS[category] or "#FFFFFF"
end

-- Получить ANSI код цвета для категории из отдельного модуля colors
M.get_ansi_color = function(colors_data, category)
  return colors_data.ANSI_COLORS[category] or "15"
end

-- Создать простое сообщение с иконкой (только иконки)
end
M.format_message = function(icons_data, category, message)
  local icon = M.get_icon(icons_data, category)
  return icon .. " " .. message
end

-- ========================================
-- РАБОТА С ПУТЯМИ И ДИРЕКТОРИЯМИ
-- ========================================

-- Константы путей
M.BACKDROPS_DIR = "backdrops"
M.RESURRECT_STATE_PATH = "plugins/resurrect.wezterm/state"

-- Функция создания путей для окружения (принимает home_dir, config_dir, platform как параметры)
M.create_environment_paths = function(home_dir, config_dir, platform)
  local paths = {
    home = home_dir,
    config = config_dir,
  }
  
  local separator = platform.is_win and "\\" or "/"
  
  -- Общие пути для всех платформ
  paths.backdrops = config_dir .. separator .. M.BACKDROPS_DIR
  paths.resurrect_state_dir = config_dir .. separator .. M.RESURRECT_STATE_PATH .. separator
  
  -- Платформо-специфичные пути
  if platform.is_win then
    paths.program_files = "C:\\Program Files"
    paths.appdata = os.getenv("APPDATA") or ""
  elseif platform.is_mac then
    paths.brew = "/opt/homebrew"
    paths.applications = "/Applications"
  else
    paths.local_bin = home_dir .. "/.local/bin"
    paths.usr_local = "/usr/local"
  end
  
  return paths
end

return M

-- ========================================
-- УПРАВЛЕНИЕ СОСТОЯНИЕМ КОНФИГУРАЦИИ
-- ========================================

-- Проверка, загружена ли конфигурация окружения
M.config_env_loaded = function(wezterm)
  local session_dir = wezterm.config_dir .. "/session-state"
  
  -- Проверяем существование любого файла сессии (свежее 5 секунд)
  local current_time = os.time()
  local cmd = 'find "' .. session_dir .. '" -name ".config-env-*.lua" -newermt "$(date -v-5S)" 2>/dev/null | head -1'
  local handle = io.popen(cmd)
  if handle then
    local result = handle:read("*line")
    handle:close()
    if result and result ~= "" then
      return true -- Найден свежий файл - блокируем повторное логирование
    end
  end
  
  -- Создаем новый файл маркер загрузки
  local session_file = session_dir .. "/.config-env-" .. tostring(os.time()) .. ".lua"
  local file = io.open(session_file, "w")
  if file then
    file:write(string.format([[{
  config_loaded = %d,
  created = "%s",
  environment_initialized = true
}]], current_time, os.date("%Y-%m-%d %H:%M:%S")))
    file:close()
  end
  
  return false -- Первая загрузка - разрешаем логирование
end

-- Принудительная перезагрузка конфигурации (очистка файлов состояния)
M.force_config_reload = function(wezterm)
  local session_dir = wezterm.config_dir .. "/session-state"
  -- Удаляем все файлы состояния конфигурации
  local cmd = 'rm -f "' .. session_dir .. '"/.config-env-*.lua 2>/dev/null'
  os.execute(cmd)
  -- Перезагружаем конфигурацию
  wezterm.reload_configuration()
end

-- Функция для определения типа служебного окна (БЕЗ require config/)
M.detect_service_window_type = function(static_title, active_title, process_name, locale_function)
  local title = static_title or active_title or ""
  
  -- Если передана функция локализации, используем её
  if locale_function then
    -- Ищем точные совпадения с локализованными заголовками
    if title == locale_function("debug_panel_title") then
      return "debug_panel_tab"
    elseif title == locale_function("load_session_tab_title") then
      return "list_picker_tab"
    elseif title == locale_function("delete_session_tab_title") then
      return "list_delete_tab"
    elseif title == locale_function("save_window_tab_title") then
      return "save_window_tab"
    elseif title == locale_function("save_tab_tab_title") then
      return "save_tab_tab"
    elseif title == locale_function("save_workspace_tab_title") then
      return "save_workspace_tab"
    end
  end
  
  return nil
end
end
return M
