-- cat > ~/.config/wezterm/events/session-status.lua << 'EOF'
--
-- ОПИСАНИЕ: Управление статусом сессий и строки состояния
-- Объединенный модуль для управления режимами терминала и отображения строки состояния.
-- Отслеживает current_key_table, управляет состоянием режимов и обновляет правую строку статуса.
--
-- ЗАВИСИМОСТИ: utils.debug, config.environment.icons, config.environment.colors, utils.environment

local wezterm = require('wezterm')
local debug = require("utils.debug")
local icons = require("config.environment.icons")
local colors = require("config.environment.colors")
local env_utils = require("utils.environment")
local environment = require('config.environment')

local M = {}

-- Переменные для отслеживания инициализации и кэширования
local platform = nil
local cached_date_lang = nil
local last_active_key_table = nil
local locale_initialized = false

-- Локальные переменные состояния сессий
local session_state = {
  current_mode = nil,
  saved_mode = nil,
  dialog_active = false,  -- Флаг активного диалога
}

-- Получение дней и месяцев из locale
local function get_localized_strings(lang)
  local l = { days = environment.locale.t.days or {}, months = environment.locale.t.months or {} }
  return {
    days = l.days or {},
    months = l.months or {},
  }
end

-- Функция для получения локализованной даты
local function get_localized_date()
  local lang = cached_date_lang or platform.language

  if not cached_date_lang or cached_date_lang ~= lang then
    cached_date_lang = lang
  end

  local day_of_week = tonumber(wezterm.strftime("%w"))
  local day_of_month = wezterm.strftime("%d")
  local month_num = tonumber(wezterm.strftime("%m")) - 1

  local strings = get_localized_strings(lang)
  if #strings.days > 0 and #strings.months > 0 then
    local day_name = strings.days[day_of_week + 1]
    local month_name = strings.months[month_num + 1]
    return day_name .. ", " .. day_of_month .. " " .. month_name
  else
    return wezterm.strftime("%a, %d %b")
  end
end

-- Получение данных режима из централизованной системы иконок
local function get_mode_data(mode_name)
  local env_utils = require('utils.environment')
  local colors = require("config.environment.colors")
  local icons = require("config.environment.icons")
  
  if env_utils.is_valid_category(icons, colors, mode_name) then
    return {
      icon = icons.t[mode_name] or "?",
      name = "",
      color = env_utils.get_color(colors, mode_name)
    }
  end
  
  -- Fallback для неизвестных режимов
  return {
    icon = "?",
    name = "",
    color = "#FFFFFF"
  }
end
-- Функция для получения красивого имени режима с локализацией
local function get_mode_display_name(mode_name)
  local mode_names = {
    session_control = "Управление сессиями",
    pane_control = "Управление панелями",
    font_control = "Управление шрифтами",
    debug_control = "Панель отладки",
    copy_mode = "Режим копирования",
    search_mode = "Режим поиска",
    workspace_search = "Поиск workspace",
  }
  return mode_names[mode_name] or "неизвестный режим"
end

local function log_status()
end

-- Функция обновления строки состояния
local function update_status_display(window)
  if not window then return end
  
  -- Получаем элементы статуса сессий
  local status_elements = M.get_status_elements()
  
  -- Получаем текущую дату и время
  local time = wezterm.strftime("%H:%M:%S")
  local date = get_localized_date()
  
  -- Формируем элементы для отображения
  local display_elements = {}
  
  local has_mode_elements = false
  
  -- 1. Добавляем анимацию загрузки (самый левый элемент)
  for _, element in ipairs(status_elements) do
    if element.type == "loading" then
      table.insert(display_elements, { Foreground = { Color = element.color } })
      table.insert(display_elements, { Text = element.icon .. " " })
      has_mode_elements = true
      break
    end
  end
  
  -- 2. Добавляем режим (справа от анимации)
  for _, element in ipairs(status_elements) do
    if element.type == "mode" then
      table.insert(display_elements, { Foreground = { Color = element.color } })
      table.insert(display_elements, { Foreground = { Color = "#666666" } })
      table.insert(display_elements, { Text = "| " })
      table.insert(display_elements, { Foreground = { Color = element.color } })
      table.insert(display_elements, { Text = element.icon .. " " })
      has_mode_elements = true
      break
    end
  end
  
  -- 3. Добавляем уведомления о результатах (справа от режима)
  for _, element in ipairs(status_elements) do
    if element.type == "notification" then
      table.insert(display_elements, { Foreground = { Color = element.color } })
      table.insert(display_elements, { Text = element.icon .. " " })
      table.insert(display_elements, { Foreground = { Color = "#FFFFFF" } })
      table.insert(display_elements, { Text = element.text .. " " })
      has_mode_elements = true
      break
    end
  end
  
  -- 4. Добавляем разделитель если есть элементы режима
  if has_mode_elements then
    table.insert(display_elements, { Foreground = { Color = "#666666" } })
    table.insert(display_elements, { Text = "| " })
  end
  
  -- 5. Добавляем дату с иконкой из централизованной системы
  table.insert(display_elements, { Background = { Color = "#313244" } })
  table.insert(display_elements, { Foreground = { Color = env_utils.get_color(colors, "time") } })
  table.insert(display_elements, { Foreground = { Color = '#BD93F9' } })
  table.insert(display_elements, { Text = date .. " " })
  table.insert(display_elements, { Foreground = { Color = '#F8F8F2' } })
  table.insert(display_elements, { Text = time })
  
  -- Устанавливаем статус
  window:set_right_status(wezterm.format(display_elements))
end

-- ========================== ПУБЛИЧНЫЕ ФУНКЦИИ ==========================

M.set_mode = function(mode_name)
  -- Логируем только если режим действительно изменился
  if session_state.current_mode ~= mode_name then
    local display_name = get_mode_display_name(mode_name)
    local activation_icon = environment.icons.t.mode_activated
    local message = activation_icon .. " Активирован режим: " .. display_name
    wezterm.log_info("[session_status] " .. message)
  end
  
  session_state.current_mode = mode_name
  session_state.saved_mode = mode_name
  log_status()
end

M.clear_mode = function()
  -- ИСПРАВЛЕНО: Очищаем ВСЁ при таймауте
  local deactivation_icon = environment.icons.t.mode_deactivated
  local timeout_icon = environment.icons.t.timeout_exit
  local main_message = deactivation_icon .. " Деактивирован режим"
  local detail_message = "   " .. timeout_icon .. " Режим завершён по таймауту"
  
  wezterm.log_info("[session_status] " .. main_message)
  wezterm.log_info(detail_message)
  
  session_state.current_mode = nil
  session_state.saved_mode = nil
  log_status()
end

M.clear_saved_mode = function()
  local deactivation_icon = environment.icons.t.mode_deactivated
  local manual_icon = environment.icons.t.manual_exit
  local main_message = deactivation_icon .. " Деактивирован режим"
  local detail_message = "   " .. manual_icon .. " Режим завершён вручную"
  
  wezterm.log_info("[session_status] " .. main_message)
  wezterm.log_info(detail_message)
  
  session_state.current_mode = nil
  session_state.saved_mode = nil
  session_state.dialog_active = false  -- Сбрасываем флаг диалога
  log_status()
end

M.clear_all_modes = function()
  -- Тихая очистка БЕЗ логирования (для перезагрузки конфигурации)
  session_state.current_mode = nil
  session_state.saved_mode = nil
  session_state.dialog_active = false
  log_status()
end

M.start_dialog = function()
  session_state.dialog_active = true
  log_status()
end

M.end_dialog = function()
  session_state.dialog_active = false
  log_status()
end

M.get_status_elements = function()
  local elements = {}
  
  -- Показываем saved_mode если он есть
  local mode_to_show = session_state.saved_mode
  if mode_to_show then
    local mode = get_mode_data(mode_to_show)
    table.insert(elements, {
      type = "mode",
      icon = mode.icon,
      text = mode.name,
      color = mode.color
    })
  end
  
  return elements
end

-- Функция для отладки - возвращает текущее состояние
M.get_debug_state = function()
  return {
    current_mode = session_state.current_mode,
    saved_mode = session_state.saved_mode,
    dialog_active = session_state.dialog_active
  }
end

-- ========================== ИНИЦИАЛИЗАЦИЯ И СОБЫТИЯ ==========================

M.setup = function()
  -- Инициализируем platform
  local create_platform_info = require('utils.platform')
  platform = create_platform_info(wezterm.target_triple)
  
  if not locale_initialized then
    platform:refresh_locale()
    locale_initialized = true
  end

  -- Основной обработчик обновления строки состояния
  wezterm.on('update-right-status', function(window, pane)
    -- Проверяем валидность окна
    if not window then return end
    local ok, current_key_table = pcall(function() return window:active_key_table() end)
    if not ok then return end
    
    -- Обрабатываем copy_mode рамку
    local copy_mode_active = (current_key_table == 'copy_mode')
    local overrides = window:get_config_overrides() or {}
    
    if copy_mode_active then
      -- COPY MODE: добавляем толстую оранжевую рамку
      overrides.window_frame = {
        border_left_width = '6px',
        border_right_width = '6px',
        border_bottom_height = '6px',
        border_top_height = '6px',
        border_left_color = '#FF8C00',
        border_right_color = '#FF8C00',
        border_bottom_color = '#FF8C00',
        border_top_color = '#FF8C00',
      }
    else
      -- ОБЫЧНЫЙ РЕЖИМ: убираем рамку
      overrides.window_frame = {
        border_left_width = '0px',
        border_right_width = '0px',
        border_bottom_width = '0px',
        border_top_height = '0px',
      }
    end
    
    window:set_config_overrides(overrides)
    
    -- ОСНОВНАЯ ЛОГИКА: Обрабатываем смену key table
    if current_key_table ~= last_active_key_table then
      if current_key_table then
        -- Активируем новый режим
        M.set_mode(current_key_table)
      elseif last_active_key_table then
        -- Деактивируем предыдущий режим
        -- Всегда завершаем режим при выходе из key_table
      end
      last_active_key_table = current_key_table
    end
    
    -- Обновляем отображение статуса
    update_status_display(window)
  end)
  
  -- Обработчик для принудительного обновления статуса
  wezterm.on('force-update-status', function(window, pane)
    if window then
      window:set_right_status("")
      cached_date_lang = nil
      last_active_key_table = nil
      wezterm.emit('update-right-status', window, pane)
    end
  end)
  
  -- Обработчик перезагрузки конфигурации
  wezterm.on('window-config-reloaded', function(window, pane)
    cached_date_lang = nil
    last_active_key_table = nil
    M.clear_all_modes()
    
    local success_msg = wezterm.format({
      {Foreground = {Color = env_utils.get_color(colors, "system")}},
      {Text = environment.icons.t.system .. " "},
      {Foreground = {Color = "#FFFFFF"}},
      {Text = environment.locale.t.config_reloaded}
    })
    
    window:set_right_status(success_msg)
    
    wezterm.time.call_after(3, function()
      if window then
        window:set_right_status("")
        wezterm.emit('force-update-status', window, pane)
      end
    end)
  end)
end

-- Минимальные заглушки для совместимости с resurrect
M.load_session_start = function(window) 
  M.start_dialog()
  log_status() 
end

M.delete_session_start = function(window) 
  M.start_dialog()
  log_status() 
end

M.start_loading = function(window) end
M.stop_loading = function(window) end
M.show_notification = function(window, message, icon, color, duration, hide_mode) end
M.load_session_list_shown = function(window, count) log_status() end
M.delete_session_list_shown = function(window, count) log_status() end

M.load_session_success = function(window, name) 
  M.end_dialog()
  M.clear_saved_mode() 
end

M.delete_session_success = function(window, name) 
  M.end_dialog()
  M.clear_saved_mode() 
end

M.save_session_success = function(window, name) 
  M.end_dialog()
  M.clear_saved_mode() 
end

M.load_session_cancelled = function(window) 
  M.end_dialog()
  M.clear_saved_mode() 
end

M.delete_session_cancelled = function(window) 
  M.end_dialog()
  M.clear_saved_mode() 
end

M.load_session_error = function(window, error_msg) 
  M.end_dialog()
  M.clear_saved_mode() 
end

M.save_session_error = function(window, error_msg) 
  M.end_dialog()
  M.clear_saved_mode() 
end

M.delete_session_error = function(window, error_msg) 
  M.end_dialog()
  M.clear_saved_mode() 
end

return M
