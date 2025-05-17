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
if not wezterm.GLOBALS.hide_tabs then wezterm.GLOBALS.hide_tabs = false end

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
    log("Создан новый фон для вкладки " .. tab_id .. ": " .. (wezterm.GLOBALS.tab_backgrounds[tab_id] or "нет"))
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
  
  log("Установлен фон " .. (bg or "нет") .. " для вкладки " .. tab_id .. " в окне " .. window_id)
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
  log("Принудительно изменен фон для вкладки " .. tab_id .. ": " .. (wezterm.GLOBALS.tab_backgrounds[tab_id] or "нет"))
  
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

-- Функция для переключения видимости интерфейса
local function toggle_interface(window, pane)
  -- Переключаем состояние
  wezterm.GLOBALS.hide_tabs = not wezterm.GLOBALS.hide_tabs
  
  local overrides = window:get_config_overrides() or {}
  
  if wezterm.GLOBALS.hide_tabs then
    -- Скрываем интерфейс
    overrides.enable_tab_bar = false
    overrides.window_decorations = "RESIZE"  -- Только изменение размера, без кнопок
    window:set_config_overrides(overrides)
    
    -- Переключаем в полноэкранный режим, если еще не в нем
    if not window:is_full_screen() then
      window:perform_action(wezterm.action.ToggleFullScreen, pane)
    end
    
    log("Интерфейс скрыт")
  else
    -- Показываем интерфейс
    overrides.enable_tab_bar = true
    overrides.window_decorations = "RESIZE"  -- ИЗМЕНЕНО: убраны кнопки
    window:set_config_overrides(overrides)
    
    -- Выходим из полноэкранного режима, если находимся в нем
    if window:is_full_screen() then
      window:perform_action(wezterm.action.ToggleFullScreen, pane)
    end
    
    log("Интерфейс восстановлен")
  end
end

-- Переключатель режима скрытия интерфейса 
wezterm.on('toggle-interface', function(window, pane)
  toggle_interface(window, pane)
end)

-- Периодическая проверка активной вкладки
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
    { brief = 'Переключить видимость интерфейса (Cmd+Shift+H)', action = act.EmitEvent('toggle-interface') },
    { brief = 'Перезагрузить конфигурацию', action = wezterm.action.ReloadConfiguration },
  }
end)

-- Формат заголовка вкладки
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local pane = tab.active_pane
  if not pane then
    return { {Text = " " .. (tab.tab_index + 1) .. ": ? "} }
  end
  
  local title = pane.title
  if title == nil or #title == 0 then
    title = pane.foreground_process_name or "terminal"
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

-- Частота обновления статусной строки (мс)
config.status_update_interval = 1000

-- Кнопки в строке вкладок
config.tab_bar_style = {
  new_tab = wezterm.format {
    { Background = { Color = '#bd93f9' } },  -- ИЗМЕНЕНО: Яркий фиолетовый из палитры Dracula
    { Foreground = { Color = '#f8f8f2' } },
    { Text = '  + ' },
  },
  new_tab_hover = wezterm.format {
    { Background = { Color = '#ff79c6' } },  -- ИЗМЕНЕНО: Розовый из палитры Dracula
    { Foreground = { Color = '#f8f8f2' } },
    { Text = '  + ' },
  },
}

-- ИЗМЕНЕНО: Настройки окна - убраны кнопки управления и добавлена обводка
config.window_decorations = 'RESIZE'  -- Только изменение размера, без кнопок
config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }

-- ИЗМЕНЕНО: Добавляем обводку окна в 1 пиксель
config.window_frame = {
  font = wezterm.font { family = 'Menlo', weight = 'Bold' },
  font_size = 12.0,
  active_titlebar_bg = '#bd93f9',  -- ИЗМЕНЕНО: светлый фиолетовый (Dracula)
  inactive_titlebar_bg = '#6272a4',  -- Синеватый (Dracula)
  
  -- Обводка окна
  border_left_width = '1px',
  border_right_width = '1px',
  border_bottom_width = '1px',
  border_top_width = '1px',
  border_left_color = '#bd93f9',  -- Фиолетовый (Dracula)
  border_right_color = '#bd93f9',
  border_bottom_color = '#bd93f9',
  border_top_color = '#bd93f9',
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

-- Настройка цветов панели вкладок - Светлая тема Dracula
config.colors = {
  foreground = '#ffffff',
  background = '#000000',
  cursor_bg = '#ffffff',
  cursor_fg = '#000000',
  
  -- Цвета панели вкладок - светлые цвета Dracula
  tab_bar = {
    background = '#bd93f9',  -- ИЗМЕНЕНО: светлый фиолетовый
    active_tab = {
      bg_color = '#000000',  -- Чёрный для активной вкладки
      fg_color = '#f8f8f2',  -- Белый текст
      intensity = 'Bold',
      underline = 'Single',
      italic = false,
      strikethrough = false,
    },
    inactive_tab = {
      bg_color = '#44475a',  -- Тёмно-серый
      fg_color = '#f8f8f2',  -- Светлый текст
    },
    inactive_tab_hover = {
      bg_color = '#6272a4',  -- Синеватый при наведении
      fg_color = '#f8f8f2',  -- Светлый текст
    },
    new_tab = {
      bg_color = '#bd93f9',  -- Фиолетовый
      fg_color = '#f8f8f2',  -- Светлый текст
    },
    new_tab_hover = {
      bg_color = '#ff79c6',  -- Розовый при наведении
      fg_color = '#f8f8f2',  -- Светлый текст
    },
  },
}

-- Изменяем leader key с Ctrl+A на Alt+A чтобы избежать конфликта с tmux
config.leader = { key = 'a', mods = 'ALT', timeout_milliseconds = 1000 }

-- Расширенная поддержка испанской клавиатуры для MacBook Air
config.use_dead_keys = false
config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = false

-- Поддержка разных раскладок клавиатуры
config.enable_csi_u_key_encoding = false

-- Настраиваем горячие клавиши и специальные символы
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
  
  -- Управление вкладками
  { key = 't', mods = 'CMD', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CMD', action = act.CloseCurrentTab { confirm = true } },
  { key = '[', mods = 'CMD', action = act.ActivateTabRelative(-1) },
  { key = ']', mods = 'CMD', action = act.ActivateTabRelative(1) },
  
  -- Горячие клавиши для смены фона
  { key = 'r', mods = 'CMD|SHIFT', action = act.EmitEvent('change-background') },
  { key = 'b', mods = 'CMD|SHIFT', action = act.EmitEvent('change-background') },
  
  -- Мгновенная вставка из буфера обмена
  { key = 'v', mods = 'CMD', action = wezterm.action.PasteFrom 'Clipboard' },
  
  -- Переключение видимости интерфейса
  { key = 'h', mods = 'CMD|SHIFT', action = act.EmitEvent('toggle-interface') },
  
  -- Перезагрузка конфигурации
  { key = 'r', mods = 'CMD|CTRL', action = wezterm.action.ReloadConfiguration },
  
  -- Отправка специальных символов через Alt (Option)
  { key = "'", mods = 'ALT', action = wezterm.action.SendString("\\") },
  { key = 'ñ', mods = 'ALT', action = wezterm.action.SendString("~") },
  { key = '1', mods = 'ALT', action = wezterm.action.SendString("|") },
  { key = 'º', mods = 'ALT', action = wezterm.action.SendString("\\") },
  { key = '+', mods = 'ALT', action = wezterm.action.SendString("]") },
  { key = '`', mods = 'ALT', action = wezterm.action.SendString("[") },
  { key = 'ç', mods = 'ALT', action = wezterm.action.SendString("}") },
  { key = '*', mods = 'ALT', action = wezterm.action.SendString("{") },
}

-- Настройка SSH
config.ssh_backend = "Ssh2"

-- Используем стандартный тип терминала
config.term = "xterm-256color"

-- Поддержка более широкого набора действий
config.disable_default_key_bindings = false
config.skip_close_confirmation_for_processes_named = {
  'bash', 'sh', 'zsh', 'fish', 'tmux'
}

-- Вывести сообщение о загрузке конфигурации
log("Конфигурация загружена успешно")

return config
