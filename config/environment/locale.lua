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
    -- Отладочные сообщения
    debug_status_module_state = "СТАТУС МОДУЛЯ: current_mode=%s, saved_mode=%s",
    debug_set_mode_called = "SESSION-STATUS set_mode вызван: %s",
    debug_clear_mode_called = "SESSION-STATUS clear_mode вызван",
    debug_clear_saved_mode_called = "SESSION-STATUS clear_saved_mode вызван",
    debug_workspace_switch = "Переключение workspace: %s",
    debug_workspace_created = "Создан новый workspace: %s",
    debug_background_changed = "Фон изменен на: %s",
    debug_window_centered = "Окно отцентрировано: %sx%s",
    debug_resurrect_save_start = "Начало сохранения состояния: %s",
    debug_resurrect_load_start = "Начало загрузки состояния: %s",
    debug_key_binding_triggered = "Горячая клавиша сработала: %s",    error = "Ошибка",
    -- Описания биндингов
    enter_new_tab_name = "Введите новое имя для вкладки",
    enter_workspace_name = "Введите имя для нового workspace",
    enter_workspace_name_new_window = "Введите имя для нового workspace (новое окно)",    -- Описания биндингов
    enter_new_tab_name = "Введите новое имя для вкладки",
    enter_workspace_name = "Введите имя для нового workspace",
    enter_workspace_name_new_window = "Введите имя для нового workspace (новое окно)",    debug_enabled_for_module = "Отладка включена для модуля: %s",
    debug_disabled_for_module = "Отладка выключена для модуля: %s",
    debug_enabled_all = "Отладка включена для всех модулей",
    debug_disabled_all = "Отладка выключена для всех модулей",  },
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
    -- Debug messages
    debug_status_module_state = "MODULE STATUS: current_mode=%s, saved_mode=%s",
    debug_set_mode_called = "SESSION-STATUS set_mode called: %s",
    debug_clear_mode_called = "SESSION-STATUS clear_mode called",
    debug_clear_saved_mode_called = "SESSION-STATUS clear_saved_mode called",
    debug_workspace_switch = "Workspace switching: %s",
    debug_workspace_created = "New workspace created: %s",
    debug_background_changed = "Background changed to: %s",
    debug_window_centered = "Window centered: %sx%s",
    debug_resurrect_save_start = "State saving started: %s",
    debug_resurrect_load_start = "State loading started: %s",
    debug_key_binding_triggered = "Key binding triggered: %s",    error = "Error",
    -- Binding descriptions
    enter_new_tab_name = "Enter new name for tab",
    enter_workspace_name = "Enter name for new workspace",
    enter_workspace_name_new_window = "Enter name for new workspace (new window)",    -- Binding descriptions
    enter_new_tab_name = "Enter new name for tab",
    enter_workspace_name = "Enter name for new workspace",
    enter_workspace_name_new_window = "Enter name for new workspace (new window)",    debug_enabled_for_module = "Debug enabled for module: %s",
    debug_disabled_for_module = "Debug disabled for module: %s",
    debug_enabled_all = "Debug enabled for all modules",
    debug_disabled_all = "Debug disabled for all modules",  }
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
