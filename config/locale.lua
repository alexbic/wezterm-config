-- cat > ~/.config/wezterm/config/locale.lua << 'EOF'
--
-- ОПИСАНИЕ: Настройки локали и языка для WezTerm
-- Централизованное управление языковыми настройками интерфейса.
-- Позволяет переопределить системную локаль для отображения даты/времени.
--
-- ЗАВИСИМОСТИ: Используется в utils.platform и events.right-status

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
  },
  de = {
    locale = "de_DE.UTF-8",
    name = "Deutsch",
    days = {"So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"},
    months = {"Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"},
  },
  fr = {
    locale = "fr_FR.UTF-8",
    name = "Français",
    days = {"Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"},
    months = {"Jan", "Fév", "Mar", "Avr", "Mai", "Jun", "Jul", "Aoû", "Sep", "Oct", "Nov", "Déc"},
  },
  es = {
    locale = "es_ES.UTF-8",
    name = "Español",
    days = {"Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"},
    months = {"Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"},
  },
  it = { locale = "it_IT.UTF-8", name = "Italiano" },
  pt = { locale = "pt_BR.UTF-8", name = "Português" },
  zh = { locale = "zh_CN.UTF-8", name = "中文" },
  ja = { locale = "ja_JP.UTF-8", name = "日本語" },
  ko = { locale = "ko_KR.UTF-8", name = "한국어" },
}

local M = {
  available_languages = available_languages,
  t = function(key)
    local lang = os.getenv("LANG") or "ru"
    lang = lang:match("^([a-z]+)") or "ru"
    return (available_languages[lang] and available_languages[lang][key]) or available_languages["ru"][key] or key
  end,
  get_language_table = function(lang)
    lang = lang or (os.getenv("LANG") or "ru")
    lang = lang:match("^([a-z]+)") or "ru"
    return available_languages[lang] or available_languages["ru"]
  end
}
return M
