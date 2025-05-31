-- cat > ~/.config/wezterm/utils/environment.lua << 'EOF'
--
-- ОПИСАНИЕ: Утилиты для работы с окружением WezTerm
-- Централизованные функции для работы с путями, локалью, переменными окружения и локализацией.
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

return M
