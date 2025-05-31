-- cat > ~/.config/wezterm/config/environment/locale.lua << 'EOF'
--
-- ОПИСАНИЕ: Локализация и языковые настройки окружения WezTerm
-- Централизованное управление языковыми настройками интерфейса и переменными окружения.
-- Позволяет переопределить системную локаль для отображения даты/времени и предоставляет переводы интерфейса.
--
-- ЗАВИСИМОСТИ: wezterm, utils.environment

local wezterm = require('wezterm')
local env_utils = require('utils.environment')

-- Таблица переводов и языковых настроек
local available_languages = {
  ru = {
    -- === БАЗОВЫЕ НАСТРОЙКИ ЛОКАЛИ ===
    locale = "ru_RU.UTF-8",
    name = "Русский",
    
    -- === СИСТЕМНЫЕ СООБЩЕНИЯ ===
    -- Общие системные сообщения и статусы загрузки
    config_loaded_info = "✅ Конфигурация загружена",
    config_loaded = "Конфигурация загружена",
    config_reloaded = "Конфигурация перезагружена",
    platform_info = "💻 %s",
    set_env_var = "⚡ %s = %s",
    set_locale = "Установка локали",
    operation_completed = "Операция завершена",
    
    -- === ПЛАТФОРМА И ОКРУЖЕНИЕ ===
    -- Определение платформы и настройки редактора
    editor = "Редактор",
    platform = "Платформа",
    not_set = "не задан",
    macos = "macOS",
    linux = "Linux",
    windows = "Windows",
    unknown = "Неизвестно",
    unknown_platform = "Неизвестная платформа",
    
    -- === ИНТЕРФЕЙС ТЕРМИНАЛА ===
    -- Сообщения интерфейса, вкладки, окна
    welcome_message = "Добро пожаловать в WezTerm!",
    profile_description = "Основной профиль терминала",
    local_terminal = "Локальный терминал",
    main_font = "Основной шрифт",
    tab_title = "Вкладка",
    tab_active = "Активна",
    new_tab_tooltip = "Новая вкладка",
    open_new_tab = "Открыть новую вкладку",
    close_tab = "Закрыть вкладку",
    open_link_in_browser = "Открыть ссылку в браузере",
    launch_profile_error = "Ошибка запуска профиля",
    
    -- === ПОДСКАЗКИ И СОВЕТЫ ===
    -- Подсказки по использованию горячих клавиш
    tip_new_tab = "Используйте Ctrl+Shift+T для новой вкладки",
    tip_split_pane = "Используйте Ctrl+Shift+O для разделения панели",
    
    -- === РЕЖИМЫ РАБОТЫ ===
    -- Различные режимы терминала
    copy_mode = "Режим копирования",
    search_mode = "Режим поиска",
    
    -- === ВРЕМЯ И ДАТА ===
    -- Локализация времени и даты
    time_label = "Время",
    battery_label = "Заряд",
    days = {"Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"},
    months = {"янв", "фев", "мар", "апр", "май", "июн", "июл", "авг", "сен", "окт", "ноя", "дек"},
    
    -- === ВНЕШНИЙ ВИД ===
    -- Сообщения о смене тем, фонов, настроек отображения
    background_changed = "Смена фонового изображения",
    theme_changed = "Тема изменена на",
    background_load_error = "Ошибка загрузки изображения",
    
    -- === ПОЛЬЗОВАТЕЛЬСКИЙ ВВОД ===
    -- Диалоги ввода для различных операций
    enter_new_tab_name = "Введите новое имя для вкладки",
    enter_workspace_name = "Введите имя для нового workspace",
    enter_workspace_name_new_window = "Введите имя для нового workspace (новое окно)",
    
    -- === СИСТЕМА СЕССИЙ (RESURRECT) ===
    -- Сообщения сохранения и восстановления сессий
    session_restored = "Сессия восстановлена",
    session_restore_error = "Ошибка восстановления сессии",
    session_saved = "Сессия сохранена",
    enter_save_session_name = "Введите имя для сохранения сессии",
    current_workspace = "Текущая workspace: %s",
    enter_save_default = "Enter = сохранить как текущую | Esc = отмена | или введите новое имя",
    save_window_as = "Сохранить window как:",
    save_window_default = "По умолчанию: %s",
    save_window_instructions = "Enter = использовать по умолчанию | Esc = отмена",
    save_tab_as = "Сохранить tab как:",
    save_tab_default = "По умолчанию: %s",
    save_tab_instructions = "Enter = использовать по умолчанию | Esc = отмена",
    session_saved_as = "Сохранено как: %s",
    session_window_saved_as = "Window сохранено как: %s",
    session_tab_saved_as = "Tab сохранен как: %s",
    save_cancelled = "Сохранение отменено пользователем",
    
    -- === ДИАЛОГИ ЗАГРУЗКИ/УДАЛЕНИЯ СЕССИЙ ===
    loading_sessions_title = "Загрузка сессии",
    loading_sessions_description = "Выберите сессию для загрузки и нажмите Enter = загрузить, Esc = отмена, / = фильтр",
    loading_sessions_fuzzy = "Поиск сессии для загрузки: ",
    deleting_sessions_title = "Удаление сессии",
    deleting_sessions_description = "Выберите сессию для удаления и нажмите Enter = удалить, Esc = отмена, / = фильтр",
    deleting_sessions_fuzzy = "Поиск сессии для удаления: ",
    
    -- === ТИПЫ СЕССИЙ ===
    workspace_type = "рабочая область",
    window_type = "окно",
    tab_type = "вкладка",
    unknown_type = "неизвестно",
    
    -- === УПРАВЛЕНИЕ WORKSPACE ===
    -- Сообщения переключения и управления workspace
    workspace_switch_title = "🔄 Выберите workspace/путь/состояние",
    workspace_switch_description = "🟢=активная 💾=workspace 🪟=window 📑=tab 📁=путь | ESC=отмена",
    workspace_active_label = "🟢 %s (активная)",
    workspace_saved_label = "💾 %s (workspace)",
    window_saved_label = "🪟 %s (window)",
    tab_saved_label = "📑 %s (tab)",
    path_label = "📁 %s (путь)",
    no_workspaces_available = "❌ Нет доступных workspace",
    restoring_window_state = "⚙️ Восстанавливаем window состояние...",
    restoring_tab_state = "⚙️ Восстанавливаем tab состояние...",
    failed_to_load_state = "❌ Не удалось загрузить состояние: %s",
    create_workspace_new_window = "Создать workspace в новом окне",
    
    -- === СИСТЕМА ОТЛАДКИ ===
    -- Отладочные сообщения модулей
    debug_enabled_for_module = "Отладка включена для модуля: %s",
    debug_disabled_for_module = "Отладка выключена для модуля: %s",
    debug_all_enabled = "⊠ Все модули отладки включены",
    debug_all_disabled = "⊠ Все модули отладки выключены",
    debug_invalid_module = "❌ Неверный модуль. Доступные: ",
    debug_status_on = "ВКЛ",
    debug_status_off = "ВЫКЛ",
    debug_status_title = "⊠ Статус отладки:",
    debug_status_header = "⊠ Статус отладки:",
    debug_status_log = "Статус модулей отладки: %s",
    debug_modules_status = "📊 Модули отладки:\n%s",
    
    -- === МЕНЕДЖЕР ОТЛАДКИ ===
    -- Интерактивные команды отладки
    debug_help_text = "⊠ Команды менеджера отладки:\n:debug-enable <модуль>  - Включить отладку модуля\n:debug-disable <модуль> - Выключить отладку модуля\n:debug-all-on          - Включить отладку всех модулей\n:debug-all-off         - Выключить отладку всех модулей\n:debug-list           - Показать текущий статус отладки\n:debug-help           - Показать эту справку\n\nДоступные модули: %s",
    debug_manager_initialized = "⊠ Менеджер отладки инициализирован с модулями: %s",
    debug_manager_help_hint = "⊠ Используйте F12 и введите :debug-help для команд",
    
    -- === ПАНЕЛЬ ОТЛАДКИ ===
    -- Интерфейс панели управления отладкой
    debug_enable_all_modules = "Включить все модули",
    debug_disable_all_modules = "Выключить все модули",
    debug_save_and_exit = "Выйти",
    debug_panel_title = "Панель управления отладкой",
    debug_help_footer = "Нажмите Esc для возврата к панели отладки.",
    
    -- === СПРАВКА ПО ОТЛАДКЕ ===
    debug_help_title = "СИСТЕМА ОТЛАДКИ WEZTERM",
    debug_help_what = "Система отладки позволяет включать детальное логирование\nразличных модулей WezTerm для диагностики проблем.",
    debug_help_how = "КАК ИСПОЛЬЗОВАТЬ:",
    debug_help_step1 = "• Включите нужные модули отладки в панели управления",
    debug_help_step2 = "• Нажмите F12 для открытия Debug Overlay",
    debug_help_step3 = "• Выполните действия, которые хотите отладить",
    debug_help_step4 = "• Анализируйте сообщения отладки в консоли",
    debug_help_modules = "ОПИСАНИЕ МОДУЛЕЙ:",
    debug_help_appearance = "• appearance - отладка фонов, прозрачности, тем",
    debug_help_bindings = "• bindings - отладка горячих клавиш и биндингов",
    debug_help_global = "• global - общесистемная отладка WezTerm",
    debug_help_resurrect = "• resurrect - отладка сохранения/восстановления сессий",
    debug_help_session = "• session_status - отладка статуса сессий и режимов",
    debug_help_workspace = "• workspace - отладка рабочих пространств",
    
    -- === ДЕТАЛЬНЫЕ ОТЛАДОЧНЫЕ СООБЩЕНИЯ ===
    -- Конкретные сообщения отладки различных модулей
    debug_status_module_state = "СТАТУС МОДУЛЯ: current_mode=%s, saved_mode=%s",
    debug_set_mode_called = "SESSION-STATUS set_mode вызван: %s",
    debug_clear_mode_called = "SESSION-STATUS clear_mode вызван",
    debug_clear_saved_mode_called = "SESSION-STATUS clear_saved_mode вызван",
    debug_workspace_switch = "Переключение workspace: %s",
    debug_workspace_created = "Создан новый workspace: %s",
    debug_background_changed = "Фон изменен на: %s",
    debug_background_new_tab = "Фон для новой вкладки %s: %s",
    debug_window_centered = "Окно отцентрировано: %sx%s",
    debug_resurrect_save_start = "Начало сохранения состояния: %s",
    debug_resurrect_load_start = "Начало загрузки состояния: %s",
    debug_key_binding_triggered = "Горячая клавиша сработала: %s",
    debug_workspace_event_started = "Событие workspace.switch запущено",
    debug_workspace_switch_triggered = "🔥 СОБЫТИЕ workspace.switch СРАБОТАЛО!",
    debug_workspace_cancelled = "Выбор workspace отменён",
    debug_workspace_action_type = "Выбран тип действия: %s",
    debug_workspace_path_switch = "Переключение на путь: %s",
    debug_status_element = "Элемент #%s тип:%s значение:%s",
    debug_workspace_plugin_chosen = "Плагин выбрал workspace: %s, label: %s",
    debug_workspace_directory_not_found = "Директория workspace не найдена: %s",
    debug_workspace_found_saved = "Найдено сохранённых workspace: %s",
    debug_workspace_restoring_saved = "Восстанавливаем сохранённый workspace: %s",
    debug_workspace_restored_successfully = "Workspace восстановлен успешно: %s",
    debug_workspace_already_active = "Уже в workspace: %s, игнорируем",
    debug_workspace_window_activated = "Активировано окно с workspace: %s",
    
    -- === ОБРАБОТКА ОШИБОК ===
    -- Общие ошибки и исключения
    error = "Ошибка",
    division_by_zero = "Деление на ноль",
    cannot_get_tab_error = "Ошибка: невозможно получить вкладку",
    plugin_error = "Ошибка плагина или интерактивное приложение",
    cannot_get_state = "Не удалось получить состояние",
    
    -- === СПЕЦИФИЧНЫЕ ОШИБКИ ===
    -- Детальные ошибки различных модулей
    error_config_environment_paths = "Не удалось загрузить config.environment.paths: %s",
    error_utils_platform = "Не удалось загрузить utils.platform: %s",
    error_platform_initialization = "Не удалось инициализировать platform",
    error_get_files_in_directory = "Ошибка при получении файлов из директории: %s",
    error_get_workspace_elements = "Ошибка при получении workspace elements: %s",
    error_get_zoxide_elements = "Ошибка при получении zoxide elements: %s",
    error_window_parameter_nil = "Window parameter is nil",
    error_workspace_parameter_nil = "Workspace parameter is nil",
    error_extract_workspace_name = "Не удалось извлечь имя workspace из label: %s",
    error_config_resurrect = "Не удалось загрузить config.resurrect: %s",
    error_resurrect_not_found = "resurrect.resurrect не найден в модуле",
    error_load_state = "Ошибка при загрузке состояния: %s",
    error_active_pane_nil = "Не удалось получить active_pane",
    error_workspace_switch_failed = "Ошибка при переключении workspace",
    error_mux_window_nil = "Не удалось получить mux_window",
    error_workspace_restore_failed = "Ошибка при восстановлении workspace",
    error_load_state_failed = "Не удалось загрузить состояние для workspace: %s",
  },
  
  en = {
    -- === BASIC LOCALE SETTINGS ===
    locale = "en_US.UTF-8",
    name = "English",
    
    -- === SYSTEM MESSAGES ===
    -- General system messages and loading statuses
    config_loaded_info = "✅ Configuration loaded",
    config_loaded = "Configuration loaded",
    config_reloaded = "Configuration reloaded",
    platform_info = "💻 %s",
    set_env_var = "⚡ %s = %s",
    set_locale = "Set locale",
    operation_completed = "Operation completed",
    
    -- === PLATFORM AND ENVIRONMENT ===
    -- Platform detection and editor settings
    editor = "Editor",
    platform = "Platform",
    not_set = "not set",
    macos = "macOS",
    linux = "Linux",
    windows = "Windows",
    unknown = "Unknown",
    unknown_platform = "Unknown platform",
    
    -- === TERMINAL INTERFACE ===
    -- Interface messages, tabs, windows
    welcome_message = "Welcome to WezTerm!",
    profile_description = "Main terminal profile",
    local_terminal = "Local terminal",
    main_font = "Main font",
    tab_title = "Tab",
    tab_active = "Active",
    new_tab_tooltip = "New tab",
    open_new_tab = "Open new tab",
    close_tab = "Close tab",
    open_link_in_browser = "Open link in browser",
    launch_profile_error = "Profile launch error",
    
    -- === TIPS AND HINTS ===
    -- Hotkey usage tips
    tip_new_tab = "Use Ctrl+Shift+T for a new tab",
    tip_split_pane = "Use Ctrl+Shift+O to split pane",
    
    -- === OPERATING MODES ===
    -- Various terminal modes
    copy_mode = "Copy mode",
    search_mode = "Search mode",
    
    -- === TIME AND DATE ===
    -- Time and date localization
    time_label = "Time",
    battery_label = "Battery",
    days = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"},
    months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"},
    
    -- === APPEARANCE ===
    -- Theme, background, display settings messages
    background_changed = "Background image changed",
    theme_changed = "Theme changed to",
    background_load_error = "Background image load error",
    
    -- === USER INPUT ===
    -- Input dialogs for various operations
    enter_new_tab_name = "Enter new name for tab",
    enter_workspace_name = "Enter name for new workspace",
    enter_workspace_name_new_window = "Enter name for new workspace (new window)",
    
    -- === SESSION SYSTEM (RESURRECT) ===
    -- Session save and restore messages
    session_restored = "Session restored",
    session_restore_error = "Session restore error",
    session_saved = "Session saved",
    enter_save_session_name = "Enter name to save session",
    current_workspace = "Current workspace: %s",
    enter_save_default = "Enter = save as current | Esc = cancel | or enter new name",
    save_window_as = "Save window as:",
    save_window_default = "Default: %s",
    save_window_instructions = "Enter = use default | Esc = cancel",
    save_tab_as = "Save tab as:",
    save_tab_default = "Default: %s",
    save_tab_instructions = "Enter = use default | Esc = cancel",
    session_saved_as = "Saved as: %s",
    session_window_saved_as = "Window saved as: %s",
    session_tab_saved_as = "Tab saved as: %s",
    save_cancelled = "Save cancelled by user",
    
    -- === LOAD/DELETE SESSION DIALOGS ===
    loading_sessions_title = "Load session",
    loading_sessions_description = "Select session to load and press Enter = load, Esc = cancel, / = filter",
    loading_sessions_fuzzy = "Search session to load: ",
    deleting_sessions_title = "Delete session",
    deleting_sessions_description = "Select session to delete and press Enter = delete, Esc = cancel, / = filter",
    deleting_sessions_fuzzy = "Search session to delete: ",
    
    -- === SESSION TYPES ===
    workspace_type = "workspace",
    window_type = "window",
    tab_type = "tab",
    unknown_type = "unknown",
    
    -- === WORKSPACE MANAGEMENT ===
    -- Workspace switching and management messages
    workspace_switch_title = "🔄 Select workspace/path/state",
    workspace_switch_description = "🟢=active 💾=workspace 🪟=window 📑=tab 📁=path | ESC=cancel",
    workspace_active_label = "🟢 %s (active)",
    workspace_saved_label = "💾 %s (workspace)",
    window_saved_label = "🪟 %s (window)",
    tab_saved_label = "📑 %s (tab)",
    path_label = "📁 %s (path)",
    no_workspaces_available = "❌ No available workspaces",
    restoring_window_state = "⚙️ Restoring window state...",
    restoring_tab_state = "⚙️ Restoring tab state...",
    failed_to_load_state = "❌ Failed to load state: %s",
    create_workspace_new_window = "Create workspace in new window",
    
    -- === DEBUG SYSTEM ===
    -- Debug module messages
    debug_enabled_for_module = "Debug enabled for module: %s",
    debug_disabled_for_module = "Debug disabled for module: %s",
    debug_all_enabled = "⊠ All debug modules enabled",
    debug_all_disabled = "⊠ All debug modules disabled",
    debug_invalid_module = "❌ Invalid module. Available: ",
    debug_status_on = "ON",
    debug_status_off = "OFF",
    debug_status_title = "⊠ Debug status:",
    debug_status_header = "⊠ Debug Status:",
    debug_status_log = "Debug modules status: %s",
    debug_modules_status = "📊 Debug Modules:\n%s",
    
    -- === DEBUG MANAGER ===
    -- Interactive debug commands
    debug_help_text = "⊠ Debug Manager Commands:\n:debug-enable <module>  - Enable debug for module\n:debug-disable <module> - Disable debug for module\n:debug-all-on          - Enable debug for all modules\n:debug-all-off         - Disable debug for all modules\n:debug-list           - Show current debug status\n:debug-help           - Show this help\n\nAvailable modules: %s",
    debug_manager_initialized = "⊠ Debug Manager initialized with modules: %s",
    debug_manager_help_hint = "⊠ Use F12 and type :debug-help for commands",
    
    -- === DEBUG PANEL ===
    -- Debug control panel interface
    debug_enable_all_modules = "Enable all modules",
    debug_disable_all_modules = "Disable all modules",
    debug_save_and_exit = "Save and exit",
    debug_panel_title = "Debug Control Panel",
    debug_help_footer = "Press Esc to return to debug panel.",
    
    -- === DEBUG HELP ===
    debug_help_title = "WEZTERM DEBUG SYSTEM",
    debug_help_what = "Debug system allows enabling detailed logging\nof various WezTerm modules for problem diagnostics.",
    debug_help_how = "HOW TO USE:",
    debug_help_step1 = "• Enable needed debug modules in the control panel",
    debug_help_step2 = "• Press F12 to open Debug Overlay",
    debug_help_step3 = "• Perform actions you want to debug",
    debug_help_step4 = "• Analyze debug messages in console",
    debug_help_modules = "MODULE DESCRIPTIONS:",
    debug_help_appearance = "• appearance - debugging backgrounds, transparency, themes",
    debug_help_bindings = "• bindings - debugging hotkeys and bindings",
    debug_help_global = "• global - general WezTerm system debugging",
    debug_help_resurrect = "• resurrect - debugging session save/restore",
    debug_help_session = "• session_status - debugging session status and modes",
    debug_help_workspace = "• workspace - debugging workspaces",
    
    -- === DETAILED DEBUG MESSAGES ===
    -- Specific debug messages from various modules
    debug_status_module_state = "MODULE STATUS: current_mode=%s, saved_mode=%s",
    debug_set_mode_called = "SESSION-STATUS set_mode called: %s",
    debug_clear_mode_called = "SESSION-STATUS clear_mode called",
    debug_clear_saved_mode_called = "SESSION-STATUS clear_saved_mode called",
    debug_workspace_switch = "Workspace switching: %s",
    debug_workspace_created = "New workspace created: %s",
    debug_background_changed = "Background changed to: %s",
    debug_background_new_tab = "Background for new tab %s: %s",
    debug_window_centered = "Window centered: %sx%s",
    debug_resurrect_save_start = "State saving started: %s",
    debug_resurrect_load_start = "State loading started: %s",
    debug_key_binding_triggered = "Key binding triggered: %s",
    debug_workspace_event_started = "Workspace.switch event started",
    debug_workspace_switch_triggered = "🔥 workspace.switch EVENT TRIGGERED!",
    debug_workspace_cancelled = "Workspace selection cancelled",
    debug_workspace_action_type = "Selected action type: %s",
    debug_workspace_path_switch = "Switching to path: %s",
    debug_status_element = "Element #%s type:%s value:%s",
    debug_workspace_plugin_chosen = "Plugin selected workspace: %s, label: %s",
    debug_workspace_directory_not_found = "Workspace directory not found: %s",
    debug_workspace_found_saved = "Found saved workspaces: %s",
    debug_workspace_restoring_saved = "Restoring saved workspace: %s",
    debug_workspace_restored_successfully = "Workspace restored successfully: %s",
    debug_workspace_already_active = "Already in workspace: %s, ignoring",
    debug_workspace_window_activated = "Window activated with workspace: %s",
    
    -- === ERROR HANDLING ===
    -- General errors and exceptions
    error = "Error",
    division_by_zero = "Division by zero",
    cannot_get_tab_error = "Error: cannot get tab",
    plugin_error = "Plugin error or interactive application",
    cannot_get_state = "Failed to get state",
    
    -- === SPECIFIC ERRORS ===
    -- Detailed errors from various modules
    error_config_environment_paths = "Failed to load config.environment.paths: %s",
    error_utils_platform = "Failed to load utils.platform: %s",
    error_platform_initialization = "Failed to initialize platform",
    error_get_files_in_directory = "Error getting files from directory: %s",
    error_get_workspace_elements = "Error getting workspace elements: %s",
    error_get_zoxide_elements = "Error getting zoxide elements: %s",
    error_window_parameter_nil = "Window parameter is nil",
    error_workspace_parameter_nil = "Workspace parameter is nil",
    error_extract_workspace_name = "Failed to extract workspace name from label: %s",
    error_config_resurrect = "Failed to load config.resurrect: %s",
    error_resurrect_not_found = "resurrect.resurrect not found in module",
    error_load_state = "Error loading state: %s",
    error_active_pane_nil = "Failed to get active_pane",
    error_workspace_switch_failed = "Workspace switch failed",
    error_mux_window_nil = "Failed to get mux_window",
    error_workspace_restore_failed = "Workspace restore failed",
    error_load_state_failed = "Failed to load state for workspace: %s",
  }
}

-- Используем функции из utils/environment.lua
local M = {
  t = function(key, ...)
    return env_utils.translate(available_languages, key, ...)
  end,
  get_language_table = function()
    return env_utils.get_language_table(available_languages)
  end,
  settings = env_utils.create_locale_settings(available_languages, wezterm)
}

return M
