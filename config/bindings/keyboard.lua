-- cat > ~/.config/wezterm/config/bindings/keyboard.lua << 'EOF'
--
-- ОПИСАНИЕ: Настройки привязок клавиш с использованием утилит
-- Определяет сочетания клавиш для различных действий: управление вкладками,
-- окнами, копирование/вставка, поиск, изменение внешнего вида.
-- Использует централизованные функции из utils.bindings для модульности.
--
-- ЗАВИСИМОСТИ: wezterm, utils.bindings, config.bindings.keyboard-tables

local wezterm = require('wezterm')  
local bindings_utils = require('utils.bindings')
local act = wezterm.action
local key_tables = require('config.bindings.keyboard-tables')
local environment = require('config.environment')

-- Создаем platform_info используя utils.platform
local create_platform_info = require('utils.platform')
local platform = create_platform_info(wezterm.target_triple)

-- Получаем модификаторы для текущей платформы
local mod = {}
if platform.is_mac then
  mod.SUPER = 'SUPER'  -- Command (⌘) на macOS
  mod.SUPER_REV = 'SUPER|CTRL'  -- Command (⌘) + Control на macOS
elseif platform.is_win then
  mod.SUPER = 'ALT'  -- Используем ALT вместо WIN на Windows
  mod.SUPER_REV = 'ALT|CTRL'
else
  mod.SUPER = 'ALT'  -- Используем ALT на Linux
  mod.SUPER_REV = 'ALT|CTRL'
end

-- Устанавливаем лидер-клавишу Alt+A для специальных функций
local leader = { key = 'a', mods = 'ALT', timeout_milliseconds = 750 }

-- Получаем тексты из статических данных локализации (с fallback)
local locale_t = (environment.locale and environment.locale.t) or {}

-- Базовые клавиши для основных функций
local base_keys = {
   -- Общие функции --
   { key = 'F1',     mods = 'NONE',        action = 'ActivateCopyMode' },
   { key = 'F2',     mods = 'NONE',        action = act.ActivateCommandPalette },
   { key = 'F3',     mods = 'NONE',        action = act.ShowLauncher },
   { key = 'F4',     mods = 'NONE',        action = act.ShowTabNavigator },
   { key = 'F11',    mods = 'NONE',        action = act.ToggleFullScreen },
   { key = 'F12',    mods = 'NONE',        action = act.ShowDebugOverlay },
   { key = "F12", mods = "SHIFT", action = bindings_utils.activate_debug_mode_with_panel(wezterm) },
   { key = "F10", mods = "NONE", action = bindings_utils.activate_state_manager(wezterm) },
   { key = "F9", mods = "NONE", action = wezterm.action_callback(function(window, pane)
     local locale_manager = require("config.dialogs.locale-manager")
     locale_manager.show_locale_manager(window, pane)
   end) },
   { key = 'f',      mods = mod.SUPER,     action = act.Search({ CaseInSensitiveString = '' }) },

   -- Принудительная перезагрузка конфигурации
   { key = 'r', mods = 'SHIFT|' .. mod.SUPER, action = wezterm.action_callback(function(window, pane)
     local env_utils = require("utils.environment")
     env_utils.force_config_reload(wezterm)
   end) },

   -- Копирование/Вставка
   { key = 'c', mods = mod.SUPER, action = act.CopyTo('Clipboard') },
   { key = 'v', mods = mod.SUPER, action = act.PasteFrom('Clipboard') },

   -- Управление вкладками --
   { key = 't', mods = mod.SUPER, action = act.SpawnTab('DefaultDomain') },
   { key = 'w', mods = mod.SUPER, action = act.CloseCurrentTab({ confirm = false }) },
   { key = 'w', mods = mod.SUPER_REV, action = act.CloseCurrentTab({ confirm = false }) },

   -- Навигация между вкладками
   { key = 'LeftArrow', mods = mod.SUPER, action = act.ActivateTabRelative(-1) },
   { key = 'RightArrow', mods = mod.SUPER, action = act.ActivateTabRelative(1) },
   { key = 'LeftArrow', mods = mod.SUPER_REV, action = act.MoveTabRelative(-1) },
   { key = 'RightArrow', mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },

   -- Управление окнами --
   { key = 'n', mods = mod.SUPER, action = act.SpawnWindow },
   { key = 'q', mods = mod.SUPER, action = act.QuitApplication },

   -- ИСПРАВЛЕНО: Переименование вкладки
   { key = 'R', mods = 'CTRL|SHIFT', action = bindings_utils.rename_tab(wezterm, locale_t.enter_new_tab_name or "Введите новое имя вкладки") },

   {
     key = "t",
     mods = "CTRL|SHIFT",
     action = wezterm.action.SpawnTab "CurrentPaneDomain",
     description = locale_t.open_new_tab or "Открыть новую вкладку",
   },
   {
     key = "w",
     mods = "CTRL|SHIFT|ALT",
     action = bindings_utils.create_workspace_new_window(wezterm, locale_t.enter_workspace_name_new_window or "Введите имя workspace для нового окна"),
     description = locale_t.create_workspace_new_window or "Создать workspace в новом окне",
   },
}

-- Собираем все клавиши из утилит
local function build_keys()
  local keys = {}

  -- Добавляем базовые клавиши
  for _, key in ipairs(base_keys) do
    table.insert(keys, key)
  end

  -- Добавляем клавиши внешнего вида
  for _, key in ipairs(bindings_utils.generate_appearance_bindings(wezterm, mod)) do
    table.insert(keys, key)
  end

  -- Добавляем клавиши key tables
  for _, key in ipairs(bindings_utils.generate_key_table_bindings(wezterm, mod)) do
    table.insert(keys, key)
  end

  -- Добавляем специальные символы (только для macOS)
  if platform.is_mac then
    for _, key in ipairs(bindings_utils.generate_special_char_bindings(wezterm)) do
      table.insert(keys, key)
    end
  end

  -- ИСПРАВЛЕНО: Добавляем workspace клавиши с текстами
  for _, key in ipairs(bindings_utils.generate_workspace_bindings(
    wezterm, 
    mod, 
    locale_t.enter_workspace_name or "Введите имя workspace:",
    locale_t.enter_workspace_name_new_window or "Введите имя workspace для нового окна:"
  )) do
    table.insert(keys, key)
  end

  return keys
end

-- Экспортируем настройки клавиатуры
return {
   disable_default_key_bindings = true,
   leader = leader,
   keys = build_keys(),
   key_tables = key_tables,
}
