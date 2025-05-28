-- cat > ~/.config/wezterm/config/bindings/keyboard.lua << 'EOF'
--
-- ОПИСАНИЕ: Настройки привязок клавиш с использованием утилит
-- ВСЕ биндинги определены в одном месте для удобства управления
-- Функции импортируются из utils.bindings для модульности.
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

-- ВСЕ КЛАВИШИ В ОДНОМ МЕСТЕ
local all_keys = {
   -- === ОБЩИЕ ФУНКЦИИ ===
   { key = 'F1',     mods = 'NONE',        action = 'ActivateCopyMode' },
   { key = 'F2',     mods = 'NONE',        action = act.ActivateCommandPalette },
   { key = 'F3',     mods = 'NONE',        action = act.ShowLauncher },
   { key = 'F4',     mods = 'NONE',        action = act.ShowTabNavigator },
   { key = 'F11',    mods = 'NONE',        action = act.ToggleFullScreen },
   { key = 'F12',    mods = 'NONE',        action = act.ShowDebugOverlay },
   { key = 'f',      mods = mod.SUPER,     action = act.Search({ CaseInSensitiveString = '' }) },

   -- === КОПИРОВАНИЕ/ВСТАВКА ===
   { key = 'c', mods = mod.SUPER, action = act.CopyTo('Clipboard') },
   { key = 'v', mods = mod.SUPER, action = act.PasteFrom('Clipboard') },

   -- === УПРАВЛЕНИЕ ВКЛАДКАМИ ===
   { key = 't', mods = mod.SUPER, action = act.SpawnTab('DefaultDomain') },
   { key = 'w', mods = mod.SUPER, action = act.CloseCurrentTab({ confirm = false }) },
   { key = 'w', mods = mod.SUPER_REV, action = act.CloseCurrentTab({ confirm = false }) },
   { key = 't', mods = "CTRL|SHIFT", action = wezterm.action.SpawnTab "CurrentPaneDomain" },
   { key = 'R', mods = 'CTRL|SHIFT', action = bindings_utils.rename_tab() },

   -- === НАВИГАЦИЯ МЕЖДУ ВКЛАДКАМИ ===
   { key = 'LeftArrow', mods = mod.SUPER, action = act.ActivateTabRelative(-1) },
   { key = 'RightArrow', mods = mod.SUPER, action = act.ActivateTabRelative(1) },
   { key = 'LeftArrow', mods = mod.SUPER_REV, action = act.MoveTabRelative(-1) },
   { key = 'RightArrow', mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },

   -- === УПРАВЛЕНИЕ ОКНАМИ ===
   { key = 'n', mods = mod.SUPER, action = act.SpawnWindow },
   { key = 'q', mods = mod.SUPER, action = act.QuitApplication },

   -- === WORKSPACE УПРАВЛЕНИЕ ===
   { key = "w", mods = "CTRL|SHIFT", action = bindings_utils.create_workspace() },
   { key = "w", mods = "CTRL|SHIFT|ALT", action = bindings_utils.create_workspace_new_window() },
   { key = "w", mods = "LEADER", action = wezterm.action.EmitEvent("workspace.switch") },
   { key = "W", mods = "LEADER", action = wezterm.action.EmitEvent("workspace.restore") },

   -- === ВНЕШНИЙ ВИД ===
   { key = '0', mods = 'CTRL', action = bindings_utils.cycle_opacity_forward() },
   { key = '9', mods = 'CTRL', action = bindings_utils.cycle_opacity_backward() },
   { key = 'h', mods = mod.SUPER_REV, action = bindings_utils.toggle_tab_bar() },
   { key = 'b', mods = 'SHIFT|' .. mod.SUPER, action = bindings_utils.change_background() },

   -- === KEY TABLES (ЛИДЕР РЕЖИМЫ) ===
   { key = 'p', mods = 'LEADER', action = bindings_utils.create_key_table_binding('pane_control') },
   { key = 'f', mods = 'LEADER', action = bindings_utils.create_key_table_binding('font_control') },
   { key = 's', mods = 'LEADER', action = bindings_utils.create_key_table_binding('session_control') },

   -- === СПЕЦИАЛЬНЫЕ СИМВОЛЫ (macOS) ===
}

-- Добавляем специальные символы только для macOS
if platform.is_mac then
   local special_chars = {
      { key = "'", mods = 'ALT', action = bindings_utils.send_special_char("\\") },
      { key = 'ñ', mods = 'ALT', action = bindings_utils.send_special_char("~") },
      { key = '1', mods = 'ALT', action = bindings_utils.send_special_char("|") },
      { key = 'º', mods = 'ALT', action = bindings_utils.send_special_char("\\") },
      { key = '+', mods = 'ALT', action = bindings_utils.send_special_char("]") },
      { key = '`', mods = 'ALT', action = bindings_utils.send_special_char("[") },
      { key = 'ç', mods = 'ALT', action = bindings_utils.send_special_char("}") },
      { key = '*', mods = 'ALT', action = bindings_utils.send_special_char("{") },
      { key = '3', mods = 'ALT', action = bindings_utils.send_special_char("#") },
   }
   
   for _, key in ipairs(special_chars) do
      table.insert(all_keys, key)
   end
end

-- Экспортируем настройки клавиатуры
return {
   disable_default_key_bindings = true,
   leader = leader,
   keys = all_keys,
   key_tables = key_tables,
}
-- EOF
