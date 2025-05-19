local wezterm = require('wezterm')
local colors = require('colors.custom')
local gpus = wezterm.gui.enumerate_gpus()
local io = require('io')
local os = require('os')

-- Используем путь относительно конфигурации
local config_dir = wezterm.config_dir
local backgrounds_dir = config_dir .. "/backgrounds"

-- Функция для логгирования
local debug_file = "/tmp/wezterm_debug.log"
local function log(message)
  local file = io.open(debug_file, "a")
  if file then
    file:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. message .. "\n")
    file:close()
  end
end

-- Проверка существования директории
local function directory_exists(path)
  local ok, err, code = os.rename(path, path)
  if not ok and code == 13 then
    -- Код 13 означает "Permission denied", но директория существует
    return true
  end
  return ok
end

-- Имеет ли директория файлы изображений
local has_background_images = false

-- Получение всех картинок из директории
local function get_files_from_dir(dir, extension)
  if not directory_exists(dir) then
    log("Директория " .. dir .. " не существует")
    return {}
  end
  
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

-- Инициализация списка фоновых изображений
local background_files = {}
log("\n\n=============== Перезагрузка конфигурации ===============")

if directory_exists(backgrounds_dir) then
  for _, ext in ipairs({'png', 'jpg', 'jpeg'}) do
    local files = get_files_from_dir(backgrounds_dir, ext)
    for _, file in ipairs(files) do
      table.insert(background_files, file)
    end
  end
  log("Найдено " .. #background_files .. " фоновых изображений")
  has_background_images = #background_files > 0
else
  log("Директория фонов не существует: " .. backgrounds_dir)
end

-- Функция для получения случайного фона
local function get_random_background()
  if not has_background_images then return nil end
  
  math.randomseed(os.time())
  local index = math.random(1, #background_files)
  local bg = background_files[index]
  log("Выбран случайный фон: " .. bg)
  return bg
end

-- Глобальное хранилище для фонов вкладок
if not wezterm.GLOBALS then wezterm.GLOBALS = {} end
if not wezterm.GLOBALS.tab_backgrounds then wezterm.GLOBALS.tab_backgrounds = {} end
if not wezterm.GLOBALS.last_active_tab then wezterm.GLOBALS.last_active_tab = {} end
if not wezterm.GLOBALS.current_opacity_index then wezterm.GLOBALS.current_opacity_index = 6 end -- Начинаем с непрозрачного (индекс 6)

-- Получаем фон для вкладки
local function get_background_for_tab(tab_id)
  if not has_background_images then return nil end
  
  if not wezterm.GLOBALS.tab_backgrounds[tab_id] then
    wezterm.GLOBALS.tab_backgrounds[tab_id] = get_random_background()
    log("Создан новый фон для вкладки " .. tab_id .. ": " .. (wezterm.GLOBALS.tab_backgrounds[tab_id] or "нет"))
  end
  return wezterm.GLOBALS.tab_backgrounds[tab_id]
end

-- Универсальная функция для настройки внешнего вида
local function set_appearance(config)
  return function(window, pane)
    local log_message = config.log_message or "Изменение настроек внешнего вида"
    log(log_message)
    
    local overrides = window:get_config_overrides() or {}
    
    -- Устанавливаем прозрачность, если указана
    if config.opacity ~= nil then
      overrides.window_background_opacity = config.opacity
    end
    
    -- Устанавливаем настройки HSB для изображения, если указаны
    if config.hsb then
      overrides.window_background_image_hsb = config.hsb
    end
    
    -- Устанавливаем изображение фона, если указано
    if config.background_image then
      overrides.window_background_image = config.background_image
    end
    
    -- Применяем все настройки
    window:set_config_overrides(overrides)
    
    -- Устанавливаем заголовок окна, если указан
    if config.title then
      window:set_title(config.title)
    end
  end
end

-- Настройки для циклической смены прозрачности
local opacity_settings = {
  -- индекс 0: 10% непрозрачности (минимальная прозрачность)
  {
    opacity = 0.1,
    hsb = has_background_images and {
      brightness = 0.4,
      saturation = 1.0,
      hue = 1.0
    } or nil,
    title = "Opacity: 10%"
  },
  -- индекс 1: 20% непрозрачности
  {
    opacity = 0.2,
    hsb = has_background_images and {
      brightness = 0.4,
      saturation = 1.0,
      hue = 1.0
    } or nil,
    title = "Opacity: 20%"
  },
  -- индекс 2: 35% непрозрачности
  {
    opacity = 0.35,
    hsb = has_background_images and {
      brightness = 0.4,
      saturation = 1.0,
      hue = 1.0
    } or nil,
    title = "Opacity: 35%"
  },
  -- индекс 3: 50% непрозрачности
  {
    opacity = 0.5,
    hsb = has_background_images and {
      brightness = 0.4,
      saturation = 1.0,
      hue = 1.0
    } or nil,
    title = "Opacity: 50%"
  },
  -- индекс 4: 65% непрозрачности
  {
    opacity = 0.65,
    hsb = has_background_images and {
      brightness = 0.4,
      saturation = 1.0,
      hue = 1.0
    } or nil,
    title = "Opacity: 65%"
  },
  -- индекс 5: 80% непрозрачности
  {
    opacity = 0.8,
    hsb = has_background_images and {
      brightness = 0.4,
      saturation = 1.0,
      hue = 1.0
    } or nil,
    title = "Opacity: 80%"
  },
  -- индекс 6: 100% непрозрачности (черный фон для изображения)
  {
    opacity = 1.0,
    hsb = has_background_images and {
      brightness = 0.4,
      saturation = 1.0,
      hue = 1.0
    } or nil,
    title = "Opacity: 100%"
  }
}

-- Обработчик для переключения видимости панели закладок
wezterm.on("toggle-tab-bar", function(window, pane)
  local overrides = window:get_config_overrides() or {}
  overrides.enable_tab_bar = not overrides.enable_tab_bar
  window:set_config_overrides(overrides)
  log("Переключение видимости панели закладок: " .. tostring(overrides.enable_tab_bar))
end)

-- Обработчик для циклического переключения прозрачности вперед
wezterm.on("cycle-opacity-forward", function(window, pane)
  -- Увеличиваем индекс и обрабатываем переход к началу
  wezterm.GLOBALS.current_opacity_index = (wezterm.GLOBALS.current_opacity_index + 1) % #opacity_settings
  local settings = opacity_settings[wezterm.GLOBALS.current_opacity_index + 1]
  
  -- Применяем новые настройки
  local overrides = window:get_config_overrides() or {}
  overrides.window_background_opacity = settings.opacity
  
  if has_background_images and settings.hsb then
    overrides.window_background_image_hsb = settings.hsb
  end
  
  window:set_config_overrides(overrides)
  
  -- Выводим информацию о прозрачности
  window:set_title(settings.title)
  log("Установка прозрачности (вперед): " .. settings.opacity .. " (" .. settings.title .. ")")
end)

-- Обработчик для циклического переключения прозрачности назад
wezterm.on("cycle-opacity-backward", function(window, pane)
  -- Уменьшаем индекс и обрабатываем переход к концу
  wezterm.GLOBALS.current_opacity_index = (wezterm.GLOBALS.current_opacity_index - 1)
  if wezterm.GLOBALS.current_opacity_index < 0 then
    wezterm.GLOBALS.current_opacity_index = #opacity_settings - 1
  end
  
  local settings = opacity_settings[wezterm.GLOBALS.current_opacity_index + 1]
  
  -- Применяем новые настройки
  local overrides = window:get_config_overrides() or {}
  overrides.window_background_opacity = settings.opacity
  
  if has_background_images and settings.hsb then
    overrides.window_background_image_hsb = settings.hsb
  end
  
  window:set_config_overrides(overrides)
  
  -- Выводим информацию о прозрачности
  window:set_title(settings.title)
  log("Установка прозрачности (назад): " .. settings.opacity .. " (" .. settings.title .. ")")
end)

-- Регистрируем обработчики событий
local function register_handlers()
  -- Обработчик смены фона при смене вкладки
  wezterm.on('update-status', function(window, pane)
    if not has_background_images then return end
    
    -- Проверяем, изменилась ли активная вкладка
    local tab = window:active_tab()
    if not tab then return end
    
    local tab_id = tab:tab_id()
    local window_id = window:window_id()
    
    -- Если вкладка изменилась или это первый запуск
    if wezterm.GLOBALS.last_active_tab[window_id] ~= tab_id then
      log("Обнаружена смена вкладки: " .. 
          tostring(wezterm.GLOBALS.last_active_tab[window_id]) .. " -> " .. tab_id)
      
      local bg = get_background_for_tab(tab_id)
      
      -- Устанавливаем фон для окна
      local overrides = window:get_config_overrides() or {}
      overrides.window_background_image = bg
      window:set_config_overrides(overrides)
      
      -- Сохраняем информацию о последней активной вкладке
      wezterm.GLOBALS.last_active_tab[window_id] = tab_id
      
      log("Установлен фон " .. (bg or "нет") .. " для вкладки " .. tab_id .. " в окне " .. window_id)
    end
  end)

  -- Обработчик смены фона
  wezterm.on('change-background', function(window, pane)
    if not has_background_images then
      log("Смена фона невозможна - нет доступных изображений")
      return
    end
    
    log("Событие смены фона")
    local tab = window:active_tab()
    if not tab then
      log("Активная вкладка не найдена при смене фона")
      return
    end
    
    local tab_id = tab:tab_id()
    wezterm.GLOBALS.tab_backgrounds[tab_id] = get_random_background()
    log("Принудительно изменен фон для вкладки " .. tab_id .. ": " .. (wezterm.GLOBALS.tab_backgrounds[tab_id] or "нет"))
    
    -- Применяем новый фон
    local overrides = window:get_config_overrides() or {}
    overrides.window_background_image = wezterm.GLOBALS.tab_backgrounds[tab_id]
    window:set_config_overrides(overrides)
  end)

  -- Командная палитра с командами для управления
  wezterm.on('augment-command-palette', function(window, pane)
    return {
      { brief = 'Циклическое переключение прозрачности (вперед)', action = wezterm.action.EmitEvent('cycle-opacity-forward') },
      { brief = 'Циклическое переключение прозрачности (назад)', action = wezterm.action.EmitEvent('cycle-opacity-backward') },
      { brief = 'Сменить фоновое изображение', action = wezterm.action.EmitEvent('change-background') },
      { brief = 'Переключить видимость панели закладок', action = wezterm.action.EmitEvent('toggle-tab-bar') },
    }
  end)
end

-- Вызываем регистрацию всех обработчиков
register_handlers()

-- Оригинальная конфигурация с добавлением начального фона
local appearance = {
   term = 'xterm-256color',
   animation_fps = 60,
   max_fps = 60,
   webgpu_preferred_adapter = gpus[1],
   front_end = 'WebGpu', -- WebGpu OpenGL
   webgpu_power_preference = 'HighPerformance',

   -- color scheme
   -- colors = colors,
   -- color_scheme = 'Gruvbox dark, medium (base16)',
   color_scheme = 'Tangoesque (terminal.sexy)',

   -- Настройки окна - улучшение поддержки полноэкранного режима
   window_decorations = 'INTEGRATED_BUTTONS|RESIZE',
   adjust_window_size_when_changing_font_size = true,
   
   -- Настройки для правильного заполнения экрана в полноэкранном режиме
   maximized_workspace_usage = true,
   native_fullscreen = true, -- Использовать нативный полноэкранный режим ОС

   -- background
   window_background_opacity = 1.0,  -- Изменено на 1.0 (непрозрачный)
   window_background_image = has_background_images and get_random_background() or nil, -- Добавляем случайный фон при запуске
   window_background_image_hsb = has_background_images and {
     brightness = 0.4,  -- Увеличена яркость для лучшей видимости
     saturation = 1.0,
     hue = 1.0,
   } or nil,

   -- Полностью отключаем скроллбар
   enable_scroll_bar = false,
   
   -- tab bar
   enable_tab_bar = true,
   hide_tab_bar_if_only_one_tab = false,
   use_fancy_tab_bar = true,
   tab_max_width = 25,
   show_tab_index_in_tab_bar = true,
   switch_to_last_active_tab_when_closing_tab = true,

   -- cursor
   default_cursor_style = 'BlinkingBlock',
   cursor_blink_ease_in = 'Constant',
   cursor_blink_ease_out = 'Constant',
   cursor_blink_rate = 700,

   -- window
   integrated_title_button_style = 'Windows',
   integrated_title_button_color = 'auto',
   integrated_title_button_alignment = 'Right',
   initial_cols = 120,
   initial_rows = 24,
   window_padding = {
      left = 20,   -- Уменьшаем до нуля для максимального места контенту
      right = 20,  -- Уменьшаем до нуля для максимального места контенту
      top = 2,    -- Уменьшаем до нуля для максимального места контенту
      bottom = 2, -- Уменьшаем до нуля для максимального места контенту
   },
   window_close_confirmation = 'AlwaysPrompt',
   inactive_pane_hsb = { saturation = 1.0, brightness = 1.0 },
}

return appearance
