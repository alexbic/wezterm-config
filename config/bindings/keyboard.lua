-- cat > ~/.config/wezterm/config/bindings/keyboard.lua << 'EOF'
--
-- ОПИСАНИЕ: Настройки привязок клавиш с использованием утилит
-- Определяет сочетания клавиш для различных действий: управление вкладками,
-- окнами, копирование/вставка, поиск, изменение внешнего вида.
-- Использует централизованные функции из utils.bindings для модульности.
--
-- ЗАВИСИМОСТИ: wezterm, utils.platform, utils.bindings, config.bindings.keyboard-tables

local wezterm = require('wezterm')
local platform = require('utils.platform')()
local bindings_utils = require('utils.bindings')
local act = wezterm.action
local key_tables = require('config.bindings.keyboard-tables')
local environment = require('config.environment')

-- Получаем модификаторы для текущей платформы
local mod = bindings_utils.get_modifiers()

-- Устанавливаем лидер-клавишу Alt+A для специальных функций
local leader = { key = 'a', mods = 'ALT', timeout_milliseconds = 750 }

-- Базовые клавиши для основных функций
local base_keys = {
   -- Общие функции --
   { key = 'F1',     mods = 'NONE',        action = 'ActivateCopyMode' },
   { key = 'F2',     mods = 'NONE',        action = act.ActivateCommandPalette },
   { key = 'F3',     mods = 'NONE',        action = act.ShowLauncher },
   { key = 'F4',     mods = 'NONE',        action = act.ShowTabNavigator },
   { key = 'F11',    mods = 'NONE',        action = act.ToggleFullScreen },
   { key = 'F12',    mods = 'NONE',        action = act.ShowDebugOverlay },
   { key = 'f',      mods = mod.SUPER,     action = act.Search({ CaseInSensitiveString = '' }) },

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

   -- Переименование вкладки
   { key = 'R', mods = 'CTRL|SHIFT', action = bindings_utils.rename_tab() },

   {
     key = "t",
     mods = "CTRL|SHIFT",
     action = wezterm.action.SpawnTab "CurrentPaneDomain",
     description = environment.locale.t("open_new_tab"),
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
  for _, key in ipairs(bindings_utils.generate_appearance_bindings(mod)) do
    table.insert(keys, key)
  end
  
  -- Добавляем клавиши key tables
  for _, key in ipairs(bindings_utils.generate_key_table_bindings(mod)) do
    table.insert(keys, key)
  end
  
  -- Добавляем специальные символы (только для macOS)
  if platform.is_mac then
    for _, key in ipairs(bindings_utils.generate_special_char_bindings()) do
      table.insert(keys, key)
    end
  end
  
  -- Добавляем workspace клавиши
  for _, key in ipairs(bindings_utils.generate_workspace_bindings(mod)) do
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
-- EOF
