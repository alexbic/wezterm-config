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
-- ЛОКАЛИЗАЦИЯ И ПЕРЕВОДЫ
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
M.create_locale_settings = function(available_languages, wezterm)
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

-- === БАЗОВЫЕ ФУНКЦИИ ПОЛУЧЕНИЯ ДАННЫХ ===

-- Получить иконку для категории
M.get_icon = function(icons_data, category)
  return icons_data.ICONS[category] or "?"
end

-- Получить HEX цвет для категории
M.get_color = function(icons_data, category)
  return icons_data.COLORS[category] or "#FFFFFF"
end

-- Получить ANSI код цвета для категории
M.get_ansi_color = function(icons_data, category)
  return icons_data.ANSI_COLORS[category] or "15"
end

-- === ФУНКЦИИ ФОРМАТИРОВАНИЯ СООБЩЕНИЙ ===

-- Создать простое сообщение с иконкой
M.format_message = function(icons_data, category, message)
  local icon = M.get_icon(icons_data, category)
  return icon .. " " .. message
end

-- Создать ANSI форматированное сообщение для терминала
M.format_ansi_message = function(icons_data, category, message)
  local icon = M.get_icon(icons_data, category)
  local color = M.get_ansi_color(icons_data, category)
  return string.format("\033[38;5;%sm%s\033[0m %s", color, icon, message)
end

-- Создать HTML форматированное сообщение
M.format_html_message = function(icons_data, category, message)
  local icon = M.get_icon(icons_data, category)
  local color = M.get_color(icons_data, category)
  return string.format('<span style="color: %s">%s</span> %s', color, icon, message)
end

-- Создать сообщение для WezTerm логирования
M.format_wezterm_log = function(wezterm, icons_data, category, message)
  local formatted = M.format_message(icons_data, category, message)
  wezterm.log_info(formatted)
end

-- === СОВМЕСТИМОСТЬ СО СТАРОЙ СИСТЕМОЙ РЕЖИМОВ ===

-- Функция для получения данных режима в старом формате (для events/session-status.lua)
M.get_mode_data = function(icons_data, mode_name)
  return {
    icon = M.get_icon(icons_data, mode_name) or "?",
    name = "",
    color = M.get_color(icons_data, mode_name) or "#FFFFFF"
  }
end

-- === ФУНКЦИИ ВАЛИДАЦИИ ИКОНОК ===

-- Проверить, существует ли категория
M.is_valid_category = function(icons_data, category)
  return icons_data.ICONS[category] ~= nil
end

-- Получить список всех доступных категорий
M.get_categories = function(icons_data)
  local categories = {}
  for category, _ in pairs(icons_data.ICONS) do
    table.insert(categories, category)
  end
  table.sort(categories)
  return categories
end

-- Получить список категорий сообщений (без режимов управления)
M.get_message_categories = function()
  return {"system", "platform", "ui", "tip", "mode", "time", "appearance", "input", "session", "workspace", "debug", "error"}
end

-- Получить список режимов управления
M.get_control_modes = function()
  return {"session_control", "pane_control", "font_control", "debug_control", "workspace_search"}
end

-- === ДЕМОНСТРАЦИЯ И ТЕСТИРОВАНИЕ ИКОНОК ===

-- Функция для демонстрации всех иконок и цветов
M.demo_icons = function(icons_data)
  print("=== ДЕМОНСТРАЦИЯ ИКОНОК И ЦВЕТОВ ===")
  
  print("\n--- КАТЕГОРИИ СООБЩЕНИЙ ---")
  local message_categories = M.get_message_categories()
  
  for _, category in ipairs(message_categories) do
    if M.is_valid_category(icons_data, category) then
      local message = M.format_ansi_message(icons_data, category, category .. "_* - " .. category .. " сообщения")
      print(message)
    end
  end
  
  print("\n--- РЕЖИМЫ УПРАВЛЕНИЯ ---")
  local control_modes = M.get_control_modes()
  
  for _, mode in ipairs(control_modes) do
    if M.is_valid_category(icons_data, mode) then
      local message = M.format_ansi_message(icons_data, mode, mode .. " - режим управления")
      print(message)
    end
  end
  
  print("\n=== ВСЕ ИКОНКИ ВМЕСТЕ ===")
  local all_categories = M.get_categories(icons_data)
  local all_icons = ""
  for _, category in ipairs(all_categories) do
    local color = M.get_ansi_color(icons_data, category)
    local icon = M.get_icon(icons_data, category)
    all_icons = all_icons .. string.format("\033[38;5;%sm%s\033[0m", color, icon)
  end
  print(all_icons)
end

-- Функция для тестирования конкретной категории
M.test_category = function(icons_data, category, test_message)
  test_message = test_message or "Тестовое сообщение"
  
  if not M.is_valid_category(icons_data, category) then
    print("❌ Категория '" .. category .. "' не найдена!")
    return false
  end
  
  print("=== ТЕСТ КАТЕГОРИИ: " .. category .. " ===")
  print("Простое: " .. M.format_message(icons_data, category, test_message))
  print("ANSI:    " .. M.format_ansi_message(icons_data, category, test_message))
  print("HTML:    " .. M.format_html_message(icons_data, category, test_message))
  return true
end

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

return M
