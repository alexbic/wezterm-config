-- German localization
return {
  locale = "de_DE.UTF-8",
  name = "German",
  
  -- === СИСТЕМНЫЕ СООБЩЕНИЯ ===
  config_loaded_info = "Конфигурация загружена", -- TODO: translate,
  config_loaded = "Конфигурация загружена", -- TODO: translate,
  config_reloaded = "Конфигурация перезагружена", -- TODO: translate,
  platform_info = "Информация о платформе", -- TODO: translate,
  set_env_var = "Переменная окружения установлена", -- TODO: translate,
  operation_completed = "Операция завершена", -- TODO: translate,
  
  -- === ВРЕМЯ И ДАТА ===
  days = {"Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"},
  months = {"янв", "фев", "мар", "апр", "май", "июн", "июл", "авг", "сен", "окт", "ноя", "дек"},
  
  -- === ИНТЕРФЕЙС ===
  enter_new_tab_name = "Введите новое имя для вкладки", -- TODO: translate,
  enter_workspace_name = "Введите имя workspace", -- TODO: translate,
  enter_workspace_name_new_window = "Введите имя workspace для нового окна", -- TODO: translate,
  
  -- === СЕССИИ ===
  loading_sessions_title = "Загрузка сессии", -- TODO: translate,
  loading_sessions_description = "Выберите сессию для загрузки", -- TODO: translate,
  deleting_sessions_title = "Удаление сессии", -- TODO: translate,
  deleting_sessions_description = "Выберите сессию для удаления", -- TODO: translate,
  
  -- === ТИПЫ ===
  workspace_type = "рабочая область", -- TODO: translate,
  window_type = "окно", -- TODO: translate, 
  tab_type = "вкладка", -- TODO: translate,
  
  -- === WORKSPACE УПРАВЛЕНИЕ ===
  workspace_switch_title = "Выберите workspace/путь/состояние", -- TODO: translate,
  workspace_switch_description = "активная workspace window tab путь ESC отмена", -- TODO: translate,
  no_workspaces_available = "Нет доступных workspace", -- TODO: translate,
  unknown_type = "неизвестно", -- TODO: translate,
  
  -- === МЕНЕДЖЕР СОСТОЯНИЙ ===
  state_manager_title = "Менеджер состояний", -- TODO: translate,
  state_manager_description = "Управление сохраненными состояниями WezTerm", -- TODO: translate,
  workspace_states_count = "Состояния Workspace", -- TODO: translate,
  window_states_count = "Состояния Window", -- TODO: translate,
  tab_states_count = "Состояния Tab", -- TODO: translate,
  view_workspace_states = "Просмотреть workspace состояния", -- TODO: translate,
  view_window_states = "Просмотреть window состояния", -- TODO: translate,
  view_tab_states = "Просмотреть tab состояния", -- TODO: translate,
  exit = "Выход", -- TODO: translate,
  back_to_main_menu = "Назад к главному меню", -- TODO: translate,
  
  -- === НАЗВАНИЯ ВКЛАДОК ===
  save_window_tab_title = "Сохранить окно", -- TODO: translate,
  save_tab_tab_title = "Сохранить вкладку", -- TODO: translate, 
  save_workspace_tab_title = "Сохранить сессию", -- TODO: translate,
  delete_session_tab_title = "Удалить сессию", -- TODO: translate,
  load_session_tab_title = "Загрузить сессию", -- TODO: translate,
  
  -- === ОТЛАДКА ===
  debug_panel_title = "Панель управления отладкой", -- TODO: translate,
  debug_enabled_for_module = "Отладка включена для модуля", -- TODO: translate,
  debug_all_enabled = "Все модули отладки включены", -- TODO: translate,
  debug_panel_short = "Отладка", -- TODO: translate,
  list_picker_short = "Выбор", -- TODO: translate,
  list_delete_short = "Удаление", -- TODO: translate,
  
  -- === БАЗОВЫЕ ===

  -- === МЕНЕДЖЕР ЛОКАЛИЗАЦИИ ===
  locale_manager_title = "УПРАВЛЕНИЕ ЛОКАЛИЗАЦИЕЙ",
  locale_manager_wezterm_title = "Менеджер локализации WezTerm", -- TODO: translate,
  locale_manager_description = "Выберите действие для управления языками", -- TODO: translate,
  locale_available_languages = "ДОСТУПНЫЕ ЯЗЫКИ:",
  locale_missing_languages = "НЕДОСТУПНЫЕ ЯЗЫКИ:",
  locale_current_language = "Текущий язык", -- TODO: translate,
  locale_regenerate_cache = "Перегенерировать кэш текущего языка", -- TODO: translate,
  locale_show_stats = "Показать статистику локализации", -- TODO: translate,
  locale_create_new = "Создать новую локаль", -- TODO: translate,
  error = "Ошибка", -- TODO: translate,
  loading = "Загрузка...", -- TODO: translate,
  success = "Успешно", -- TODO: translate,
  cancel = "Отмена", -- TODO: translate,
  -- === ДОПОЛНИТЕЛЬНЫЕ КЛЮЧИ ===
  cannot_get_state = "Не удалось получить состояние", -- TODO: translate,
  cannot_get_tab_error = "Ошибка: невозможно получить вкладку", -- TODO: translate,
  deleting_sessions_fuzzy = "Поиск сессии для удаления: ", -- TODO: translate,
  dialog_hint_save = "Enter: сохранить  Esc: отмена", -- TODO: translate,
  failed_to_load_state = "Не удалось загрузить состояние", -- TODO: translate,
  loading_sessions_fuzzy = "Поиск сессии для загрузки: ", -- TODO: translate,
  local_terminal = "Локальный терминал", -- TODO: translate,
  plugin_error = "Ошибка плагина или интерактивное приложение", -- TODO: translate,
  session_saved_as = "Сохранено успешно", -- TODO: translate,

  -- === ПЛАТФОРМА И СИСТЕМА ===
  set_locale = "Установка локали", -- TODO: translate,
  editor = "Редактор", -- TODO: translate,
  platform = "Платформа", -- TODO: translate,
  not_set = "не задан", -- TODO: translate,
  macos = "macOS",
  linux = "Linux", 
  windows = "Windows",
  unknown = "Неизвестно", -- TODO: translate,
  unknown_platform = "Неизвестная платформа", -- TODO: translate,
  
  -- === ИНТЕРФЕЙС ТЕРМИНАЛА ===
  welcome_message = "Добро пожаловать в WezTerm!", -- TODO: translate,
  profile_description = "Основной профиль терминала", -- TODO: translate,
  main_font = "Основной шрифт", -- TODO: translate,
  tab_title = "Вкладка", -- TODO: translate,
  tab_active = "Активна", -- TODO: translate,
  new_tab_tooltip = "Новая вкладка", -- TODO: translate,
  open_new_tab = "Открыть новую вкладку", -- TODO: translate,
  close_tab = "Закрыть вкладку", -- TODO: translate,
  open_link_in_browser = "Открыть ссылку в браузере", -- TODO: translate,
  launch_profile_error = "Ошибка запуска профиля", -- TODO: translate,
  tip_new_tab = "Используйте Ctrl+Shift+T для новой вкладки", -- TODO: translate,

  -- === ПОДСКАЗКИ И РЕЖИМЫ ===
  tip_split_pane = "Используйте Ctrl+Shift+O для разделения панели", -- TODO: translate,
  copy_mode = "Режим копирования", -- TODO: translate,
  search_mode = "Режим поиска", -- TODO: translate,
  time_label = "Время", -- TODO: translate,
  battery_label = "Заряд", -- TODO: translate,
  
  -- === ВНЕШНИЙ ВИД ===
  background_changed = "Смена фонового изображения", -- TODO: translate,
  theme_changed = "Тема изменена на", -- TODO: translate,
  background_load_error = "Ошибка загрузки изображения", -- TODO: translate,
  
  -- === СЕССИИ И СОХРАНЕНИЯ ===
  session_restored = "Сессия восстановлена", -- TODO: translate,
  session_restore_error = "Ошибка восстановления сессии", -- TODO: translate, 
  session_saved = "Сессия сохранена", -- TODO: translate,
  enter_save_session_name = "Введите имя для сохранения сессии", -- TODO: translate,
  current_workspace = "Текущая workspace", -- TODO: translate,
  enter_save_default = "Enter = сохранить как текущую | Esc = отмена | или введите новое имя", -- TODO: translate,
  save_window_as = "Сохранить window как:", -- TODO: translate,
  save_window_default = "По умолчанию", -- TODO: translate,
  save_window_instructions = "Enter = использовать по умолчанию | Esc = отмена", -- TODO: translate,
  save_tab_as = "Сохранить tab как:", -- TODO: translate,
  save_tab_default = "По умолчанию", -- TODO: translate,
  save_tab_instructions = "Enter = использовать по умолчанию | Esc = отмена", -- TODO: translate,

  -- === ПОДСКАЗКИ И РЕЖИМЫ ===
  -- ДУБЛИКАТ УДАЛЕН:   tip_split_pane = "Используйте Ctrl+Shift+O для разделения панели", -- TODO: translate,
  -- ДУБЛИКАТ УДАЛЕН:   copy_mode = "Режим копирования", -- TODO: translate,
  -- ДУБЛИКАТ УДАЛЕН:   search_mode = "Режим поиска", -- TODO: translate,
  -- ДУБЛИКАТ УДАЛЕН:   time_label = "Время", -- TODO: translate,
  -- ДУБЛИКАТ УДАЛЕН:   battery_label = "Заряд", -- TODO: translate,
  
  -- === ВНЕШНИЙ ВИД ===
  -- ДУБЛИКАТ УДАЛЕН:   background_changed = "Смена фонового изображения", -- TODO: translate,
  -- ДУБЛИКАТ УДАЛЕН:   theme_changed = "Тема изменена на", -- TODO: translate,
  -- ДУБЛИКАТ УДАЛЕН:   background_load_error = "Ошибка загрузки изображения", -- TODO: translate,
  
  -- === СЕССИИ И СОХРАНЕНИЯ ===
  -- ДУБЛИКАТ УДАЛЕН:   session_restored = "Сессия восстановлена", -- TODO: translate,
  -- ДУБЛИКАТ УДАЛЕН:   session_restore_error = "Ошибка восстановления сессии", -- TODO: translate, 
  -- ДУБЛИКАТ УДАЛЕН:   session_saved = "Сессия сохранена", -- TODO: translate,
  -- ДУБЛИКАТ УДАЛЕН:   enter_save_session_name = "Введите имя для сохранения сессии", -- TODO: translate,
  -- ДУБЛИКАТ УДАЛЕН:   current_workspace = "Текущая workspace", -- TODO: translate,
  -- ДУБЛИКАТ УДАЛЕН:   enter_save_default = "Enter = сохранить как текущую | Esc = отмена | или введите новое имя", -- TODO: translate,
  -- ДУБЛИКАТ УДАЛЕН:   save_window_as = "Сохранить window как:", -- TODO: translate,
  -- ДУБЛИКАТ УДАЛЕН:   save_window_default = "По умолчанию", -- TODO: translate,
  -- ДУБЛИКАТ УДАЛЕН:   save_window_instructions = "Enter = использовать по умолчанию | Esc = отмена", -- TODO: translate,
  -- ДУБЛИКАТ УДАЛЕН:   save_tab_as = "Сохранить tab как:", -- TODO: translate,
  -- ДУБЛИКАТ УДАЛЕН:   save_tab_default = "По умолчанию", -- TODO: translate,
  -- ДУБЛИКАТ УДАЛЕН:   save_tab_instructions = "Enter = использовать по умолчанию | Esc = отмена", -- TODO: translate,

  -- === СОХРАНЕНИЕ СЕССИЙ ===
  session_window_saved_as = "Window сохранено как", -- TODO: translate,
  session_tab_saved_as = "Tab сохранен как", -- TODO: translate, 
  save_cancelled = "Сохранение отменено пользователем", -- TODO: translate,
  
  -- === WORKSPACE LABELS ===
  workspace_active_label = "активная", -- TODO: translate,
  workspace_saved_label = "workspace",
  window_saved_label = "window",
  tab_saved_label = "tab",
  path_label = "путь", -- TODO: translate,
  restoring_window_state = "Восстанавливаем window состояние...", -- TODO: translate,
  restoring_tab_state = "Восстанавливаем tab состояние...", -- TODO: translate,
  create_workspace_new_window = "Создать workspace в новом окне", -- TODO: translate,
  
  -- === СИСТЕМА ОТЛАДКИ ===
  debug_disabled_for_module = "Отладка выключена для модуля", -- TODO: translate,
  debug_all_disabled = "Все модули отладки выключены", -- TODO: translate,
  debug_invalid_module = "Неверный модуль. Доступные:", -- TODO: translate,
  debug_status_on = "ВКЛ",
  debug_status_off = "ВЫКЛ", 
  debug_status_title = "Статус отладки:", -- TODO: translate,
  debug_status_header = "Статус отладки:", -- TODO: translate,
  debug_enable_all_modules = "Включить все модули", -- TODO: translate,
  debug_disable_all_modules = "Выключить все модули", -- TODO: translate,
  debug_save_and_exit = "Выйти", -- TODO: translate,
  debug_help_footer = "Нажмите Esc для возврата к панели отладки.", -- TODO: translate,
  
  -- === ОШИБКИ СИСТЕМЫ ===
  division_by_zero = "Деление на ноль", -- TODO: translate,
  error_config_environment_paths = "Не удалось загрузить config.environment.paths", -- TODO: translate,
  error_utils_platform = "Не удалось загрузить utils.platform", -- TODO: translate,
  error_platform_initialization = "Не удалось инициализировать platform", -- TODO: translate,
  error_workspace_switch_failed = "Ошибка при переключении workspace", -- TODO: translate,
  error_load_state_failed = "Не удалось загрузить состояние для workspace", -- TODO: translate,
}
