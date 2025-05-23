-- cat > ~/.config/wezterm/config/environment/locale.lua << 'EOF'
--
-- ОПИСАНИЕ: Локализация и языковые настройки окружения WezTerm
-- Централизованное управление языковыми настройками интерфейса и переменными окружения.
-- Позволяет переопределить системную локаль для отображения даты/времени и предоставляет переводы интерфейса.
--
-- ЗАВИСИМОСТИ: wezterm, используется в utils.platform, events.right-status, config.environment

local wezterm = require('wezterm')

-- Таблица переводов и языковых настроек (см. предыдущий полный пример)
local available_languages = {
  ru = {
    locale = "ru_RU.UTF-8",
    name = "Русский",
    set_env_var = "Установка переменной окружения",
    set_locale = "Установка локали",
    editor = "Редактор",
    platform = "Платформа",
    not_set = "не задан",
    macos = "macOS",
    linux = "Linux",
    windows = "Windows",
    unknown = "Неизвестно",
    unknown_platform = "Неизвестная платформа",
    welcome_message = "Добро пожаловать в WezTerm!",
    profile_description = "Основной профиль терминала",
    tip_new_tab = "Используйте Ctrl+Shift+T для новой вкладки",
    tip_split_pane = "Используйте Ctrl+Shift+O для разделения панели",
    background_changed = "Смена фонового изображения",
    theme_changed = "Тема изменена на",
    background_load_error = "Ошибка загрузки изображения",
    time_label = "Время",
    battery_label = "Заряд",
    days = {"Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"},
    months = {"янв", "фев", "мар", "апр", "май", "июн", "июл", "авг", "сен", "окт", "ноя", "дек"},
    tab_title = "Вкладка",
    tab_active = "Активна",
    new_tab_tooltip = "Новая вкладка",
    session_restored = "Сессия восстановлена",
    session_restore_error = "Ошибка восстановления сессии",
    session_saved = "Сессия сохранена",
    division_by_zero = "Деление на ноль",
    open_new_tab = "Открыть новую вкладку",
    local_terminal = "Локальный терминал",
    main_font = "Основной шрифт",
    config_loaded = "Конфигурация загружена",
    launch_profile_error = "Ошибка запуска профиля",
    open_link_in_browser = "Открыть ссылку в браузере",
    close_tab = "Закрыть вкладку",
    copy_mode = "Режим копирования",
    search_mode = "Режим поиска",
    operation_completed = "Операция завершена",
    error = "Ошибка",
  },
  en = {
    locale = "en_US.UTF-8",
    name = "English",
    set_env_var = "Set environment variable",
    set_locale = "Set locale",
    editor = "Editor",
    platform = "Platform",
    not_set = "not set",
    macos = "macOS",
    linux = "Linux",
    windows = "Windows",
    unknown = "Unknown",
    unknown_platform = "Unknown platform",
    welcome_message = "Welcome to WezTerm!",
    profile_description = "Main terminal profile",
    tip_new_tab = "Use Ctrl+Shift+T for a new tab",
    tip_split_pane = "Use Ctrl+Shift+O to split pane",
    background_changed = "Background image changed",
    theme_changed = "Theme changed to",
    background_load_error = "Background image load error",
    time_label = "Time",
    battery_label = "Battery",
    days = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"},
    months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"},
    tab_title = "Tab",
    tab_active = "Active",
    new_tab_tooltip = "New tab",
    session_restored = "Session restored",
    session_restore_error = "Session restore error",
    session_saved = "Session saved",
    division_by_zero = "Division by zero",
    open_new_tab = "Open new tab",
    local_terminal = "Local terminal",
    main_font = "Main font",
    config_loaded = "Configuration loaded",
    launch_profile_error = "Profile launch error",
    open_link_in_browser = "Open link in browser",
    close_tab = "Close tab",
    copy_mode = "Copy mode",
    search_mode = "Search mode",
    operation_completed = "Operation completed",
    error = "Error",
  }
}

local default_language = os.getenv("WEZTERM_LANG") or "ru"
local lang_table = available_languages[default_language] or available_languages["ru"]

local function t(key)
  return lang_table[key] or key
end

local locale_config = {
  force_language = default_language,
  force_locale = lang_table.locale or "ru_RU.UTF-8"
}

wezterm.log_info(t("set_locale") .. ": " .. locale_config.force_locale)

local M = {
  t = t,
  get_language_table = function() return lang_table end,
  settings = {
    LANG = locale_config.force_locale,
    LC_ALL = locale_config.force_locale,
    LC_TIME = locale_config.force_locale,
    LC_NUMERIC = locale_config.force_locale,
    LC_MONETARY = locale_config.force_locale,
  }
}

return M
