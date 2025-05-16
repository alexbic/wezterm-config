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

-- Улучшенная функция для определения, запущен ли tmux
local function is_tmux_running(pane)
  if not pane then
    log("Не удалось проверить tmux: панель не существует")
    return false
  end
  
  -- Логируем доступную информацию о панели
  local process_name = pane.foreground_process_name or "неизвестно"
  local title = pane.title or "неизвестно"
  local cwd = pane.current_working_dir and pane.current_working_dir.file_path or "неизвестно"
  
  log("Проверка tmux: процесс=" .. process_name .. ", заголовок=" .. title .. ", cwd=" .. cwd)
  
  -- Проверяем содержимое переменной $TERM_PROGRAM
  local success, stdout, stderr = wezterm.run_child_process({"sh", "-c", "echo $TERM_PROGRAM"})
  if success then
    log("TERM_PROGRAM=" .. stdout)
    if stdout:find("tmux") then
      log("Tmux обнаружен через TERM_PROGRAM")
      return true
    end
  end
  
  -- Проверка через командную строку
  success, stdout, stderr = wezterm.run_child_process({"sh", "-c", "ps -p $$ -o ppid= | xargs ps -o comm= -p"})
  if success then
    log("Родительский процесс: " .. stdout)
    if stdout:find("tmux") then
      log("Tmux обнаружен через ps")
      return true
    end
  end
  
  -- Проверяем переменную окружения TMUX
  success, stdout, stderr = wezterm.run_child_process({"sh", "-c", "echo $TMUX"})
  if success and stdout and #stdout > 0 and stdout ~= "\n" then
    log("TMUX=" .. stdout)
    log("Tmux обнаружен через переменную TMUX")
    return true
  end
  
  -- Проверяем по имени процесса
  if process_name:find("tmux") then
    log("Tmux обнаружен через foreground_process_name")
    return true
  end
  
  -- Проверяем по заголовку
  if title:find("tmux") then
    log("Tmux обнаружен через title")
    return true
  end
  
  -- Принудительно скрываем вкладки, если нажата клавиша F11
  -- Это позволит вам вручную переключать видимость панели вкладок
  if wezterm.GLOBALS.hide_tabs_by_f11 then
    log("Tmux имитирован через F11")
    return true
  end
  
  log("Tmux не обнаружен")
  return false
end

-- Переключатель режима скрытия интерфейса
wezterm.on('toggle-tabs', function(window, pane)
  wezterm.GLOBALS.hide_tabs_by_f11 = not wezterm.GLOBALS.hide_tabs_by_f11
  
  local status = wezterm.GLOBALS.hide_tabs_by_f11 and "скрыт" or "показан"
  log("Интерфейс " .. status .. " вручную")
  
  -- Применяем изменения видимости панели вкладок
  local overrides = window:get_config_overrides() or {}
  overrides.enable_tab_bar = not wezterm.GLOBALS.hide_tabs_by_f11
  window:set_config_overrides(overrides)
  
  -- Переключаем в полноэкранный режим без декораций
  if wezterm.GLOBALS.hide_tabs_by_f11 then
    window:perform_action(wezterm.action.ToggleFullScreen, pane)
  else
    -- Если уже в полноэкранном режиме, выходим из него
    if window:is_full_screen() then
      window:perform_action(wezterm.action.ToggleFullScreen, pane)
    end
  end
end)

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
  
  -- Проверяем, запущен ли tmux, и скрываем панель вкладок
  local active_pane = tab.active_pane
  if active_pane and is_tmux_running(active_pane) then
    -- Скрываем панель вкладок при работе с tmux
    local overrides = window:get_config_overrides() or {}
    overrides.enable_tab_bar = false
    window:set_config_overrides(overrides)
    
    -- Переключаем в полноэкранный режим без декораций, если еще не в нем
    if not window:is_full_screen() then
      window:perform_action(wezterm.action.ToggleFullScreen, pane)
    end
    
    log("Интерфейс скрыт (tmux обнаружен)")
  else
    -- Восстанавливаем видимость панели вкладок
    if not wezterm.GLOBALS.hide_tabs_by_f11 then
      local overrides = window:get_config_overrides() or {}
      overrides.enable_tab_bar = true
      window:set_config_overrides(overrides)
      
      -- Если в полноэкранном режиме, выходим из него
      if window:is_full_screen() then
        window:perform_action(wezterm.action.ToggleFullScreen, pane)
      end
      
      log("Интерфейс показан (tmux не обнаружен)")
    end
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
    { brief = 'Переключить видимость интерфейса', action = act.EmitEvent('toggle-tabs') },
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

-- Отключаем dead keys для испанской клавиатуры
config.use_dead_keys = false

-- Обработчик нажатий клавиш для проверки, запущен ли tmux
wezterm.on('key-down', function(window, pane, key, mods, event)
  -- Вручную переключаем видимость панели вкладок и системных кнопок по F11
  if key == 'F11' and mods:contains('NONE') then
    window:perform_action(act.EmitEvent('toggle-tabs'), pane)
    return false
  end
  
  -- Если нажаты клавиши для создания новой вкладки/окна
  if (key == 't' and mods:contains('CMD')) or
     (key == 'n' and mods:contains('CMD')) then
    
    -- Проверяем, запущен ли tmux
    if is_tmux_running(pane) then
      -- Если tmux запущен, отменяем стандартную обработку
      log("Блокировка создания новой вкладки/окна (tmux)")
      return false
    end
  end
  
  -- Пропускаем стандартную обработку для других клавиш
  return true
end)

-- Настраиваем обработку клавиш Ñ для испанской клавиатуры
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
  
  -- Управление вкладками - будет работать только если не запущен tmux
  { key = 't', mods = 'CMD', action = act.SpawnTab 'CurrentPaneDomain' },
  
  { key = 'w', mods = 'CMD', action = act.CloseCurrentTab { confirm = true } },
  { key = '[', mods = 'CMD', action = act.ActivateTabRelative(-1) },
  { key = ']', mods = 'CMD', action = act.ActivateTabRelative(1) },
  
  -- Горячие клавиши для смены фона
  { key = 'r', mods = 'CMD|SHIFT', action = act.EmitEvent('change-background') },
  { key = 'b', mods = 'CMD|SHIFT', action = act.EmitEvent('change-background') },
  
  -- Отправка тильды ~ через Alt+Ñ для испанской клавиатуры
  { key = "ñ", mods = "ALT", action = wezterm.action.SendString("~") },
  { key = "Ñ", mods = "ALT", action = wezterm.action.SendString("~") },
  
  -- Мгновенная вставка из буфера обмена
  { key = 'v', mods = 'CMD', action = wezterm.action.PasteFrom 'Clipboard' },
  
  -- Переключение видимости панели вкладок вручную
  { key = 'F11', mods = 'NONE', action = act.EmitEvent('toggle-tabs') },
}

-- Дополнительные ключевые привязки для испанской клавиатуры
-- Определяем дополнительные символы, которые могут быть сложными для ввода
config.key_tables = {
  -- Таблица для специальных символов
  spanish_fixes = {
    { key = "n", mods = "NONE", action = wezterm.action.SendString("~") },
    { key = "Escape", action = "PopKeyTable" },
    { key = "Return", action = "PopKeyTable" },
  },
}

-- Добавляем специальную комбинацию для входа в режим ввода специальных символов
table.insert(config.keys, { 
  key = "n", 
  mods = "ALT", 
  action = wezterm.action.ActivateKeyTable { 
    name = "spanish_fixes", 
    one_shot = true,
  } 
})

-- Настройка SSH
config.ssh_backend = "Ssh2"

log("Конфигурация загружена успешно")
return config
