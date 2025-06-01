-- cat > ~/.config/wezterm/config/environment/colors.lua << 'EOF'
--
-- ОПИСАНИЕ: Цветовые схемы и переменные для командной строки и интерфейса
-- Содержит пользовательскую цветовую схему (catppuccin mocha), переменные для ls/grep,
-- и цвета для всех элементов интерфейса WezTerm включая заголовки вкладок.
-- Иконки вынесены в отдельный файл config/environment/icons.lua
-- Функции для работы с цветами находятся в utils/environment.lua
--
-- ЗАВИСИМОСТИ: используется в config.appearance

-- === ПОЛЬЗОВАТЕЛЬСКАЯ ЦВЕТОВАЯ СХЕМА CATPPUCCIN MOCHA ===
local mocha = {
   rosewater = "#f5e0dc",
   flamingo = "#f2cdcd",
   pink = "#f5c2e7",
   mauve = "#cba6f7",
   red = "#f38ba8",
   maroon = "#eba0ac",
   peach = "#fab387",
   yellow = "#f9e2af",
   green = "#a6e3a1",
   teal = "#94e2d5",
   sky = "#89dceb",
   sapphire = "#74c7ec",
   blue = "#89b4fa",
   lavender = "#b4befe",
   text = "#cdd6f4",
   subtext1 = "#bac2de",
   subtext0 = "#a6adc8",
   overlay2 = "#9399b2",
   overlay1 = "#7f849c",
   overlay0 = "#6c7086",
   surface2 = "#585b70",
   surface1 = "#45475a",
   surface0 = "#313244",
   base = "#1f1f28",
   mantle = "#181825",
   crust = "#11111b",
}

-- === ОСНОВНАЯ ЦВЕТОВАЯ СХЕМА ТЕРМИНАЛА ===
local colorscheme = {
   foreground = mocha.text,
   background = mocha.base,
   cursor_bg = mocha.rosewater,
   cursor_border = mocha.rosewater,
   cursor_fg = mocha.crust,
   selection_bg = mocha.surface2,
   selection_fg = mocha.text,
   ansi = {
      "#0C0C0C", "#C50F1F", "#13A10E", "#C19C00",
      "#0037DA", "#881798", "#3A96DD", "#CCCCCC",
   },
   brights = {
      "#767676", "#E74856", "#16C60C", "#F9F1A5",
      "#3B78FF", "#B4009E", "#61D6D6", "#F2F2F2",
   },
   tab_bar = {
      background = "#313244",
      active_tab = {
         bg_color = mocha.surface2,
         fg_color = mocha.text,
      },
      inactive_tab = {
         bg_color = mocha.surface0,
         fg_color = mocha.subtext1,
      },
      inactive_tab_hover = {
         bg_color = mocha.surface0,
         fg_color = mocha.text,
      },
      new_tab = {
         bg_color = mocha.base,
         fg_color = mocha.text,
      },
      new_tab_hover = {
         bg_color = mocha.mantle,
         fg_color = mocha.text,
         italic = true,
      },
   },
   -- 🟠 ОРАНЖЕВЫЙ VISUAL BELL для copy_mode
   visual_bell = "#FF8C00",
   indexed = {
      [16] = mocha.peach,
      [17] = mocha.rosewater,
   },
   scrollbar_thumb = mocha.surface2,
   split = mocha.overlay0,
   compose_cursor = mocha.flamingo,
}

-- === ЦВЕТА ПО КАТЕГОРИЯМ (HEX) ===
-- Пастельные цвета для каждой категории иконок
local COLORS = {
  -- === КАТЕГОРИИ СООБЩЕНИЙ ДЛЯ ЛОГИРОВАНИЯ ===
  system = "#A8CCE8",     -- пастельный голубой
  platform = "#C8A8E8",   -- пастельный фиолетовый
  ui = "#8FB8E8",         -- пастельный синий
  tip = "#F0E68C",        -- пастельный желтый
  mode = "#F4A460",       -- пастельный оранжевый
  time = "#D3D3D3",       -- светло-серый
  appearance = "#F0B8C8", -- пастельный розовый
  input = "#98E4AA",      -- пастельный зеленый
  session = "#A8E6CF",    -- мятный
  workspace = "#B8A8E8",  -- лавандовый
  window = "#F9E2AF",      -- желтый для окон
  tab = "#F8A0A0",         -- красный для вкладок
  debug = "#F4A682",      -- коралловый
  error = "#F8A0A0",      -- пастельный красный
  exit = "#D3D3D3",        -- светло-серый
  
  -- === ЦВЕТА ДЛЯ СЛУЖЕБНЫХ ОКОН ===
  -- Окна которые перекрывают экран
  debug_panel_tab = "#FF6B6B",         -- красный для отладки
  list_picker_tab = "#98E4AA",         -- пастельный зеленый для выбора
  list_delete_tab = "#F8A0A0",         -- пастельный красный для удаления
  save_workspace_tab = "#B8A8E8",      -- лавандовый для workspace
  save_window_tab = "#F9E2AF",         -- желтый для window
  save_tab_tab = "#F8A0A0",            -- красный для tab
  
  -- === ЦВЕТА ДЛЯ РЕЖИМОВ УПРАВЛЕНИЯ ===
  -- Отображаются в строке состояния
  session_control = "#4ECDC4",  -- бирюзовый
  pane_control = "#4ECDC4",     -- бирюзовый
  font_control = "#4ECDC4",     -- бирюзовый
  debug_control = "#F4A682",    -- коралловый
  workspace_search = "#F1FA8C", -- желтый
  
  -- === ЦВЕТА ДЛЯ ЗАГОЛОВКОВ ВКЛАДОК ===
  -- Фон и текст заголовков вкладок терминала
  tab_default_bg = "#589220",         -- фон обычной вкладки (зеленый)
  tab_active_bg = "#dac835",          -- фон активной вкладки (желтый)
  tab_hover_bg = "#79c92e",           -- фон при наведении
  tab_admin_bg = "#FF6B6B",           -- фон вкладки администратора
  tab_unseen_output = "#FFA066",      -- цвет индикатора непрочитанного вывода (оранжевый)
  
  -- Цвета текста для заголовков вкладок
  tab_default_fg = "#1c1b19",    -- текст обычной вкладки (темный)
  tab_active_fg = "#11111b",     -- текст активной вкладки (черный)
  tab_hover_fg = "#1c1b19",      -- текст при наведении
  tab_service_fg = "#000000",    -- текст служебной вкладки (черный для контраста)
}

-- === ANSI КОДЫ ЦВЕТОВ ===
-- 256-цветные ANSI коды для терминала
local ANSI_COLORS = {
  -- === КАТЕГОРИИ СООБЩЕНИЙ ДЛЯ ЛОГИРОВАНИЯ ===
  system = "152",      -- пастельный голубой
  platform = "183",   -- пастельный фиолетовый
  ui = "117",         -- пастельный синий
  tip = "229",        -- пастельный желтый
  mode = "216",       -- пастельный оранжевый
  time = "250",       -- светло-серый
  appearance = "217", -- пастельный розовый
  input = "157",      -- пастельный зеленый
  session = "158",    -- мятный
  workspace = "189",  -- лавандовый
  window = "228",      -- желтый для окон
  tab = "203",         -- красный для вкладок
  debug = "210",      -- коралловый
  error = "203",      -- пастельный красный
  exit = "250",        -- светло-серый
  
  -- === ANSI ЦВЕТА ДЛЯ СЛУЖЕБНЫХ ОКОН ===
  debug_panel_tab = "203",         -- красный для отладки
  list_picker_tab = "157",         -- пастельный зеленый для выбора
  list_delete_tab = "203",         -- пастельный красный для удаления
  save_workspace_tab = "189",      -- лавандовый для workspace
  save_window_tab = "228",         -- желтый для window
  save_tab_tab = "203",            -- красный для tab
  
  -- === ANSI ЦВЕТА ДЛЯ РЕЖИМОВ УПРАВЛЕНИЯ ===
  session_control = "80",   -- бирюзовый
  pane_control = "80",      -- бирюзовый
  font_control = "80",      -- бирюзовый
  debug_control = "210",    -- коралловый
  workspace_search = "228", -- желтый
  
  -- === ANSI ЦВЕТА ДЛЯ ЗАГОЛОВКОВ ВКЛАДОК ===
  tab_default_bg = "64",          -- фон обычной вкладки
  tab_active_bg = "185",          -- фон активной вкладки
  tab_hover_bg = "113",           -- фон при наведении
  tab_admin_bg = "203",           -- фон вкладки администратора
  tab_unseen_output = "215",      -- индикатор непрочитанного вывода
}

-- === ПЕРЕМЕННЫЕ ДЛЯ КОМАНДНОЙ СТРОКИ ===
local CLI_VARS = {
  CLICOLOR = '1',
  LSCOLORS = 'ExFxBxDxCxegedabagacad',
  LS_COLORS = 'di=1;34:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43',
  GREP_COLOR = '1;32',
  GREP_OPTIONS = '--color=auto',
}

return {
  mocha = mocha,
  colorscheme = colorscheme,
  COLORS = COLORS,
  ANSI_COLORS = ANSI_COLORS,
  CLI_VARS = CLI_VARS,
}
