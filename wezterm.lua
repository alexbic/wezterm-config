local wezterm = require 'wezterm'
local act = wezterm.action
local io = require 'io'
local os = require 'os'

-- Используем путь относительно конфигурации
local config_dir = wezterm.config_dir
local backgrounds_dir = config_dir .. "/backgrounds"

-- Включаем отладку в файл
local debug_file = "/tmp/wezterm_debug.log"
local function log(message)
  local file = io.open(debug_file, "a")
  if file then
    file:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. message .. "\n")
    file:close()
  end
end

log("\n\n=============== Перезагрузка конфигурации ===============")

-- Получение всех картинок из директории
local function get_files_from_dir(dir, extension)
  local files = {}
  local handle = io.popen('find "' .. dir .. '" -type f -name "*.' .. extension .. '" 2>/dev/null')
  if handle then
    for file in handle:lines() do
      table.insert(files, file)
    end
    handle:close()
  end
  return files
end

local background_files = {}
for _, ext in ipairs({'png', 'jpg'}) do
  local files = get_files_from_dir(backgrounds_dir, ext)
  for _, file in ipairs(files) do
    table.insert(background_files, file)
  end
end

log("Найдено " .. #background_files .. " фоновых изображений")

-- Средняя дефолтная прозрачность - 0.6 (60%)
local default_opacity = 0.6

-- Глобальное хранилище
if not wezterm.GLOBALS then wezterm.GLOBALS = {} end
if not wezterm.GLOBALS.tab_backgrounds then wezterm.GLOBALS.tab_backgrounds = {} end
if not wezterm.GLOBALS.last_active_tab then wezterm.GLOBALS.last_active_tab = {} end

-- Функция для получения случайного фона
local function get_random_background()
  if #background_files == 0 then return nil end
  math.randomseed(os.time())
  local index = math.random(1, #background_files)
  local bg = background_files[index]
  log("Выбран случайный фон: " .. bg)
  return bg
end

-- Упрощенная функция для получения фона вкладки
local function get_background_for_tab(tab_id)
  if not wezterm.GLOBALS.tab_backgrounds[tab_id] then
    wezterm.GLOBALS.tab_backgrounds[tab_id] = get_random_background()
    log("Создан новый фон для вкладки " .. tab_id .. ": " .. wezterm.GLOBALS.tab_backgrounds[tab_id])
  end
  return wezterm.GLOBALS.tab_backgrounds[tab_id]
end

-- Функция устанавливает фон для окна на основе активной вкладки
local function set_background_for_window(window)
  local tab = window:active_tab()
  if not tab then
    log("Активная вкладка не найдена")
    return
  end
  
  local tab_id = tab:tab_id()
  local bg = get_background_for_tab(tab_id)
  
  -- Устанавливаем фон для окна
  local overrides = window:get_config_overrides() or {}
  overrides.window_background_image = bg
  window:set_config_overrides(overrides)
  
  -- Сохраняем информацию о последней активной вкладке
  local window_id = window:window_id()
  wezterm.GLOBALS.last_active_tab[window_id] = tab_id
  
  log("Установлен фон " .. bg .. " для вкладки " .. tab_id .. " в окне " .. window_id)
end

-- Функция принудительно меняет фон для текущей вкладки
local function force_change_tab_background(window)
  local tab = window:active_tab()
  if not tab then
    log("Активная вкладка не найдена при смене фона")
    return
  end
  
  local tab_id = tab:tab_id()
  wezterm.GLOBALS.tab_backgrounds[tab_id] = get_random_background()
  log("Принудительно изменен фон для вкладки " .. tab_id .. ": " .. wezterm.GLOBALS.tab_backgrounds[tab_id])
  
  -- Применяем новый фон
  set_background_for_window(window)
end

-- Установка прозрачности окна
local function set_opacity(window, value)
  local overrides = window:get_config_overrides() or {}
  overrides.window_background_opacity = value
  overrides.window_background_image_hsb = {
    brightness = 0.3,
    saturation = 1.0,
    hue = 1.0,
  }
  window:set_config_overrides(overrides)
  window:set_title("Opacity: " .. math.floor(value * 100) .. "%")
  log("Установлена прозрачность " .. value)
end

-- Установка чёрного фона (непрозрачный, с более ярким изображением)
local function set_black_background(window)
  local overrides = window:get_config_overrides() or {}
  overrides.window_background_opacity = 1.0  -- Полностью непрозрачный
  overrides.window_background_image_hsb = {
    brightness = 0.4,    -- Повышаем яркость картинки
    saturation = 1.0,
    hue = 1.0,
  }
  window:set_config_overrides(overrides)
  window:set_title("Solid Background (картинка на черном фоне)")
  log("Установлен черный фон с картинкой")
end

-- Возврат к настройкам по умолчанию
local function reset_to_defaults(window)
  local overrides = window:get_config_overrides() or {}
  overrides.window_background_opacity = default_opacity
  overrides.window_background_image_hsb = {
    brightness = 0.3,
    saturation = 1.0,
    hue = 1.0,
  }
  window:set_config_overrides(overrides)
  window:set_title("Default Settings (прозрачность " .. math.floor(default_opacity * 100) .. "%)")
  log("Сброс к настройкам по умолчанию")
end

-- Функция для получения имени хоста из SSH-соединения
local function get_ssh_host_info(pane)
  -- Пытаемся получить информацию о SSH-соединении
  local ssh_info = nil
  local process_name = pane:get_foreground_process_name() or ""
  
  -- Проверяем, является ли процесс SSH-соединением
  if process_name:find("ssh") then
    local process_cmd = pane:get_foreground_process_info()
    if process_cmd then
      local cmd_line = process_cmd.cmdline or {}
      for i, arg in ipairs(cmd_line) do
        -- Ищем аргумент, который не начинается с "-" и содержит "@"
        if arg:find("@") and not arg:find("^%-") then
          ssh_info = arg
          break
        end
        -- Или берем последний аргумент, если он не является флагом
        if i == #cmd_line and not arg:find("^%-") then
          ssh_info = arg
        end
      end
    end
  end
  
  return ssh_info
end

-- Периодическая проверка и применение фона (основной механизм)
wezterm.on('update-status', function(window, pane)
  -- Проверяем, изменилась ли активная вкладка
  local tab = window:active_tab()
  if not tab then return end
  
  local tab_id = tab:tab_id()
  local window_id = window:window_id()
  
  -- Если вкладка изменилась или это первый запуск
  if wezterm.GLOBALS.last_active_tab[window_id] ~= tab_id then
    log("Обнаружена смена вкладки: " .. 
        tostring(wezterm.GLOBALS.last_active_tab[window_id]) .. " -> " .. tab_id)
    set_background_for_window(window)
  end
  
  -- Получаем текущее время
  local current_time = wezterm.strftime("%H:%M:%S")
  
  -- Получаем информацию о SSH-соединении
  local ssh_info = get_ssh_host_info(pane)
  local status_elements = {}
  
  -- Добавляем текущее время
  table.insert(status_elements, "🕒 " .. current_time)
  
  -- Добавляем информацию о SSH-соединении, если она есть
  if ssh_info then
    table.insert(status_elements, "🖥️ SSH: " .. ssh_info)
  end
  
  -- Объединяем все элементы в статусную строку
  local status_text = table.concat(status_elements, " | ")
  
  -- Устанавливаем статусную строку
  window:set_right_status(wezterm.format({
    { Foreground = { Color = "#8be9fd" } },
    { Text = status_text },
  }))
end)

-- Обработчики событий для прозрачности
wezterm.on('set-opacity-0.00', function(window, pane) set_opacity(window, 0.00) end)
wezterm.on('set-opacity-0.05', function(window, pane) set_opacity(window, 0.05) end)
wezterm.on('set-opacity-0.15', function(window, pane) set_opacity(window, 0.15) end)
wezterm.on('set-opacity-0.25', function(window, pane) set_opacity(window, 0.25) end)
wezterm.on('set-opacity-0.4', function(window, pane) set_opacity(window, 0.4) end)
wezterm.on('set-opacity-0.6', function(window, pane) set_opacity(window, 0.6) end)
wezterm.on('set-opacity-0.8', function(window, pane) set_opacity(window, 0.8) end)
wezterm.on('set-black-background', function(window, pane) set_black_background(window) end)
wezterm.on('reset-to-defaults', function(window, pane) reset_to_defaults(window) end)

-- Обработчик смены фона текущей вкладки
wezterm.on('change-background', function(window, pane)
  log("Событие смены фона")
  force_change_tab_background(window)
end)

-- Командная палитра
wezterm.on('augment-command-palette', function(window, pane)
  return {
    { brief = 'Прозрачность 0% (полностью прозрачный)', action = act.EmitEvent('set-opacity-0.00') },
    { brief = 'Прозрачность 5%', action = act.EmitEvent('set-opacity-0.05') },
    { brief = 'Прозрачность 15%', action = act.EmitEvent('set-opacity-0.15') },
    { brief = 'Прозрачность 25%', action = act.EmitEvent('set-opacity-0.25') },
    { brief = 'Прозрачность 40%', action = act.EmitEvent('set-opacity-0.4') },
    { brief = 'Прозрачность 60% (по умолчанию)', action = act.EmitEvent('set-opacity-0.6') },
    { brief = 'Прозрачность 80%', action = act.EmitEvent('set-opacity-0.8') },
    { brief = 'Сбросить настройки по умолчанию (Alt+A, 9)', action = act.EmitEvent('reset-to-defaults') },
    { brief = 'Сменить фоновое изображение', action = act.EmitEvent('change-background') },
    { brief = 'Черный фон + картинка (Ctrl+0)', action = act.EmitEvent('set-black-background') },
  }
end)

-- Формат заголовка вкладки с улучшенным отображением активной вкладки
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local pane = tab.active_pane
  local title = pane.title
  if title == nil or #title == 0 then
    title = pane.foreground_process_name
  end
  
  -- Отображаем номер вкладки и добавляем индикатор для активной вкладки
  if tab.is_active then
    return {
      {Text=" ★ " .. (tab.tab_index + 1) .. ": " .. title .. " "},
    }
  else
    return {
      {Text=" " .. (tab.tab_index + 1) .. ": " .. title .. " "},
    }
  end
end)

-- Конфигурация
local config = {}

config.font = wezterm.font('Menlo')
config.font_size = 14.0
config.color_scheme = 'Dracula'

-- Настройки панели вкладок
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false  -- Панель вкладок СВЕРХУ
config.show_new_tab_button_in_tab_bar = true
config.show_tab_index_in_tab_bar = true
config.tab_max_width = 25

-- Добавляем кнопки управления в панель вкладок
config.show_tabs_in_tab_bar = true

-- Частота обновления статусной строки (мс) - устанавливаем 1 секунду
config.status_update_interval = 1000

-- Кнопки в строке вкладок
config.tab_bar_style = {
  new_tab = wezterm.format {
    { Background = { Color = '#282a36' } },
    { Foreground = { Color = '#f8f8f2' } },
    { Text = '  + ' },
  },
  new_tab_hover = wezterm.format {
    { Background = { Color = '#6272a4' } },
    { Foreground = { Color = '#f8f8f2' } },
    { Text = '  + ' },
  },
}

-- Настройки окна
config.window_decorations = 'INTEGRATED_BUTTONS | RESIZE'
config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }
config.window_frame = {
  font = wezterm.font { family = 'Menlo', weight = 'Bold' },
  font_size = 12.0,
  active_titlebar_bg = '#282a36',
  inactive_titlebar_bg = '#1e1f29',
}

-- Выбираем случайное изображение для начального фона
config.window_background_image = get_random_background()
config.window_background_opacity = default_opacity
config.window_background_image_hsb = {
  brightness = 0.3,
  saturation = 1.0,
  hue = 1.0,
}

-- Размытие на macOS / Wayland
config.macos_window_background_blur = 30

-- Настройка цветов панели вкладок с улучшенным визуальным отображением активной вкладки
config.colors = {
  foreground = '#ffffff',
  background = '#000000',
  cursor_bg = '#ffffff',
  cursor_fg = '#000000',
  
  -- Цвета панели вкладок
  tab_bar = {
    background = '#282a36',
    active_tab = {
      bg_color = '#bd93f9',  -- Яркий фиолетовый из палитры Dracula
      fg_color = '#f8f8f2',  -- Белый текст
      intensity = 'Bold',
      underline = 'Single',  -- Добавляем подчеркивание для активной вкладки
      italic = false,
      strikethrough = false,
    },
    inactive_tab = {
      bg_color = '#282a36',
      fg_color = '#6272a4',
    },
    inactive_tab_hover = {
      bg_color = '#44475a',
      fg_color = '#f8f8f2',
    },
    new_tab = {
      bg_color = '#282a36',
      fg_color = '#6272a4',
    },
    new_tab_hover = {
      bg_color = '#44475a',
      fg_color = '#f8f8f2',
    },
  },
}

-- Изменяем leader key с Ctrl+A на Alt+A чтобы избежать конфликта с tmux
config.leader = { key = 'a', mods = 'ALT', timeout_milliseconds = 1000 }

-- Клавиши с обновленным leader key
config.keys = {
  { key = 'p', mods = 'CMD|SHIFT', action = act.ActivateCommandPalette },
  
  -- Полноэкранный режим
  { key = 'f', mods = 'CMD', action = wezterm.action.ToggleFullScreen },

  -- Различные уровни прозрачности (Alt+A, затем цифра)
  { key = '0', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.00') },
  { key = '1', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.05') },
  { key = '2', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.15') },
  { key = '3', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.25') },
  { key = '4', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.4') },
  { key = '5', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.6') },
  { key = '6', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.8') },
  { key = '9', mods = 'LEADER', action = act.EmitEvent('reset-to-defaults') },
  { key = 'b', mods = 'LEADER', action = act.EmitEvent('change-background') },
  
  -- Черный фон с хорошо видимой картинкой (Ctrl+0)
  { key = '0', mods = 'CTRL', action = act.EmitEvent('set-black-background') },
  
  -- Управление вкладками - создание новой вкладки через SpawnTab
  { key = 't', mods = 'CMD', action = act.SpawnTab 'CurrentPaneDomain' },
  
  { key = 'w', mods = 'CMD', action = act.CloseCurrentTab { confirm = true } },
  { key = '[', mods = 'CMD', action = act.ActivateTabRelative(-1) },
  { key = ']', mods = 'CMD', action = act.ActivateTabRelative(1) },
  
  -- Горячие клавиши для смены фона
  { key = 'r', mods = 'CMD|SHIFT', action = act.EmitEvent('change-background') },
  { key = 'b', mods = 'CMD|SHIFT', action = act.EmitEvent('change-background') },
}

log("Конфигурация загружена успешно")
return config
