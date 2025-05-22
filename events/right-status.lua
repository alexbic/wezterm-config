-- cat > ~/.config/wezterm/events/right-status.lua << 'EOF'
--
-- ОПИСАНИЕ: Настройка строки состояния
-- Выводит информацию в правой части строки состояния, включая 
-- статус режима, часы, дату, календарь, индикатор загрузки и др.
--
-- ЗАВИСИМОСТИ: utils.platform, utils.session-status

local wezterm = require('wezterm')
local platform_module = require('utils.platform')
local session_status = require('utils.session-status')
local platform = platform_module()

-- Локализованные названия дней недели и месяцев
local localized_strings = {
  -- Русский
  ru = {
    days = {"Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"},
    months = {"янв", "фев", "мар", "апр", "май", "июн", 
              "июл", "авг", "сен", "окт", "ноя", "дек"}
  },
  -- Английский
  en = {
    days = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"},
    months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
              "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
  },
  -- Немецкий
  de = {
    days = {"So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"},
    months = {"Jan", "Feb", "Mär", "Apr", "Mai", "Jun",
              "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"}
  },
  -- Французский
  fr = {
    days = {"Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"},
    months = {"Jan", "Fév", "Mar", "Avr", "Mai", "Jun",
              "Jul", "Aoû", "Sep", "Oct", "Nov", "Déc"}
  },
  -- Испанский
  es = {
    days = {"Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"},
    months = {"Ene", "Feb", "Mar", "Abr", "May", "Jun",
              "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"}
  },
}

-- Переменные для отслеживания инициализации и кэширования
local locale_initialized = false
local cached_date_lang = nil
local last_active_key_table = nil

-- Функция для получения локализованной даты
local function get_localized_date()
  local lang = cached_date_lang or platform.language
  
  if not cached_date_lang or cached_date_lang ~= lang then
    cached_date_lang = lang
    wezterm.log_info("Язык для даты установлен: " .. lang .. " (локаль: " .. platform.locale .. ")")
  end
  
  local day_of_week = tonumber(wezterm.strftime("%w"))
  local day_of_month = wezterm.strftime("%d")
  local month_num = tonumber(wezterm.strftime("%m")) - 1
  
  local strings = localized_strings[lang]
  if strings then
    local day_name = strings.days[day_of_week + 1]
    local month_name = strings.months[month_num + 1]
    return day_name .. ", " .. day_of_month .. " " .. month_name
  else
    return wezterm.strftime("%a, %d %b")
  end
end

local function setup()
  if not locale_initialized then
    platform:refresh_locale()
    locale_initialized = true
    
    wezterm.log_info("=== ИНИЦИАЛИЗАЦИЯ ЛОКАЛИ ===")
    wezterm.log_info("Платформа: " .. (platform.is_mac and "macOS" or platform.is_win and "Windows" or platform.is_linux and "Linux" or "Unknown"))
    wezterm.log_info("Итоговая локаль: " .. platform.locale)
    wezterm.log_info("Итоговый язык: " .. platform.language)
    wezterm.log_info("=== КОНЕЦ ИНИЦИАЛИЗАЦИИ ===")
  end

  -- Основной обработчик обновления строки состояния
  wezterm.on('update-right-status', function(window, pane)
    -- Получаем текущую активную таблицу клавиш
    local current_key_table = window:active_key_table()
    
    -- Обновляем режим если таблица изменилась
    if current_key_table ~= last_active_key_table then
      if current_key_table then
        session_status.set_mode(current_key_table)
        wezterm.log_info("🎯 Активирована таблица клавиш: " .. current_key_table)
      else
        -- Очищаем ТОЛЬКО текущий режим при выходе из таблицы клавиш
        session_status.clear_mode()
        wezterm.log_info("🎯 Таблица клавиш деактивирована")
      end
      last_active_key_table = current_key_table
    end
    
    -- Получаем элементы статуса сессий
    local status_elements = session_status.get_status_elements()
    
    -- Получаем текущую дату и время
    local time = wezterm.strftime("%H:%M:%S")
    local date = get_localized_date()
    local calendar_icon = "📅"
    
    -- Формируем элементы для отображения
    local display_elements = {}
    
    -- ПОРЯДОК: [анимация] [режим] [уведомление] | 📅 дата время
    
    local has_elements = false
    
    -- 1. Добавляем анимацию загрузки (самый левый элемент)
    for _, element in ipairs(status_elements) do
      if element.type == "loading" then
        table.insert(display_elements, { Foreground = { Color = element.color } })
        table.insert(display_elements, { Text = element.icon .. " " })
        has_elements = true
        break
      end
    end
    
    -- 2. Добавляем режим (справа от анимации)
    for _, element in ipairs(status_elements) do
      if element.type == "mode" then
        table.insert(display_elements, { Foreground = { Color = element.color } })
        table.insert(display_elements, { Text = element.icon .. " " .. element.text .. " " })
        has_elements = true
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
        has_elements = true
        break
      end
    end
    
    -- 4. Добавляем разделитель если есть элементы
    if has_elements then
      table.insert(display_elements, { Foreground = { Color = "#666666" } })
      table.insert(display_elements, { Text = "| " })
    end
    
    -- 5. Добавляем календарь и дату (самый правый блок)
    table.insert(display_elements, { Foreground = { Color = '#8BE9FD' } })
    table.insert(display_elements, { Text = calendar_icon .. " " })
    table.insert(display_elements, { Foreground = { Color = '#BD93F9' } })
    table.insert(display_elements, { Text = date .. " " })
    table.insert(display_elements, { Foreground = { Color = '#F8F8F2' } })
    table.insert(display_elements, { Text = time })
    
    window:set_right_status(wezterm.format(display_elements))
  end)
  
  -- Добавляем горячую клавишу для принудительной остановки анимации (для отладки)
  wezterm.on('stop-loading-debug', function(window, pane)
    wezterm.log_info("🚨 Горячая клавиша: принудительная остановка анимации")
    session_status.force_stop_loading(window)
  end)
  
  -- Обработчик для принудительного обновления статуса
  wezterm.on('force-update-status', function(window, pane)
    wezterm.log_info("Событие force-update-status")
    
    if window then
      window:set_right_status("")
      locale_initialized = false
      cached_date_lang = nil
      last_active_key_table = nil
      session_status.clear_all_modes() -- Очищаем ВСЕ режимы
      wezterm.emit('update-right-status', window, pane)
    end
  end)
  
  -- Обработчик для отображения уведомлений при перезагрузке конфигурации
  wezterm.on('window-config-reloaded', function(window, pane)
    locale_initialized = false
    cached_date_lang = nil
    last_active_key_table = nil
    session_status.clear_all_modes() -- Очищаем ВСЕ режимы при перезагрузке
    
    local success_msg = wezterm.format({
      {Foreground = {Color = "#00FF00"}},
      {Text = "✓ "},
      {Foreground = {Color = "#FFFFFF"}},
      {Text = "Конфигурация перезагружена"}
    })
    
    window:set_right_status(success_msg)
    
    wezterm.time.call_after(3, function()
      if window then
        window:set_right_status("")
        window:perform_action(
          wezterm.action.EmitEvent("force-update-status"),
          nil
        )
      end
    end)
  end)
end

return {
  setup = setup
}
