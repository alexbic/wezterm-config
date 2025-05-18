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

-- Инициализация списка фоновых изображений
local background_files = {}
log("\n\n=============== Перезагрузка конфигурации ===============")
for _, ext in ipairs({'png', 'jpg'}) do
  local files = get_files_from_dir(backgrounds_dir, ext)
  for _, file in ipairs(files) do
    table.insert(background_files, file)
  end
end
log("Найдено " .. #background_files .. " фоновых изображений")

-- Функция для получения случайного фона
local function get_random_background()
  if #background_files == 0 then return nil end
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

-- Получаем фон для вкладки
local function get_background_for_tab(tab_id)
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

-- Регистрируем обработчики событий
local function register_handlers()
  -- Обработчик смены фона при смене вкладки
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

  -- Использование универсальной функции для всех настроек внешнего вида
  
  -- Настройки прозрачности
  wezterm.on('set-opacity-0.00', set_appearance({
    opacity = 0.00,
    title = "Opacity: 0%",
    log_message = "Установка прозрачности 0.00"
  }))
  
  wezterm.on('set-opacity-0.05', set_appearance({
    opacity = 0.05,
    title = "Opacity: 5%",
    log_message = "Установка прозрачности 0.05"
  }))
  
  wezterm.on('set-opacity-0.15', set_appearance({
    opacity = 0.15,
    title = "Opacity: 15%",
    log_message = "Установка прозрачности 0.15"
  }))
  
  wezterm.on('set-opacity-0.25', set_appearance({
    opacity = 0.25,
    title = "Opacity: 25%",
    log_message = "Установка прозрачности 0.25"
  }))
  
  wezterm.on('set-opacity-0.4', set_appearance({
    opacity = 0.4,
    title = "Opacity: 40%",
    log_message = "Установка прозрачности 0.4"
  }))
  
  wezterm.on('set-opacity-0.6', set_appearance({
    opacity = 0.6,
    title = "Opacity: 60%",
    log_message = "Установка прозрачности 0.6"
  }))
  
  wezterm.on('set-opacity-0.8', set_appearance({
    opacity = 0.8,
    title = "Opacity: 80%",
    log_message = "Установка прозрачности 0.8"
  }))

  -- Установка черного фона
  wezterm.on('set-black-background', set_appearance({
    opacity = 1.0,
    hsb = {
      brightness = 0.4,
      saturation = 1.0,
      hue = 1.0,
    },
    title = "Solid Background (картинка на черном фоне)",
    log_message = "Установка черного фона"
  }))

  -- Сброс к настройкам по умолчанию
  wezterm.on('reset-to-defaults', set_appearance({
    opacity = 1.0,  -- Изменено на 1.0 для непрозрачного фона
    hsb = {
      brightness = 0.4,
      saturation = 1.0,
      hue = 1.0,
    },
    title = "Default Settings (непрозрачный фон)",
    log_message = "Сброс к настройкам по умолчанию"
  }))

  -- Командная палитра с командами для управления прозрачностью
  wezterm.on('augment-command-palette', function(window, pane)
    return {
      { brief = 'Прозрачность 0% (полностью прозрачный)', action = wezterm.action.EmitEvent('set-opacity-0.00') },
      { brief = 'Прозрачность 5%', action = wezterm.action.EmitEvent('set-opacity-0.05') },
      { brief = 'Прозрачность 15%', action = wezterm.action.EmitEvent('set-opacity-0.15') },
      { brief = 'Прозрачность 25%', action = wezterm.action.EmitEvent('set-opacity-0.25') },
      { brief = 'Прозрачность 40%', action = wezterm.action.EmitEvent('set-opacity-0.4') },
      { brief = 'Прозрачность 60%', action = wezterm.action.EmitEvent('set-opacity-0.6') },
      { brief = 'Прозрачность 80%', action = wezterm.action.EmitEvent('set-opacity-0.8') },
      { brief = 'Сбросить настройки по умолчанию', action = wezterm.action.EmitEvent('reset-to-defaults') },
      { brief = 'Сменить фоновое изображение', action = wezterm.action.EmitEvent('change-background') },
      { brief = 'Черный фон + картинка', action = wezterm.action.EmitEvent('set-black-background') },
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

   -- background
   window_background_opacity = 1.0,  -- Изменено на 1.0 (непрозрачный)
   window_background_image = get_random_background(), -- Добавляем случайный фон при запуске
   window_background_image_hsb = {
     brightness = 0.4,  -- Увеличена яркость для лучшей видимости
     saturation = 1.0,
     hue = 1.0,
   },

   -- scrollbar
   enable_scroll_bar = true,
   min_scroll_bar_height = '3cell',
   colors = {
      scrollbar_thumb = '#454545',
   },

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
   window_decorations = 'INTEGRATED_BUTTONS|RESIZE',
   integrated_title_button_style = 'Windows',
   integrated_title_button_color = 'auto',
   integrated_title_button_alignment = 'Right',
   initial_cols = 120,
   initial_rows = 24,
   window_padding = {
      left = 5,
      right = 10,
      top = 12,
      bottom = 7,
   },
   window_close_confirmation = 'AlwaysPrompt',
   window_frame = {
      active_titlebar_bg = '#090909',
      -- font = fonts.font,
      -- font_size = fonts.font_size,
   },
   inactive_pane_hsb = { saturation = 1.0, brightness = 1.0 },
}

return appearance
