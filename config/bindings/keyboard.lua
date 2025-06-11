local wezterm = require('wezterm')  
local bindings_utils = require('utils.bindings')
local act = wezterm.action
local key_tables = require('config.bindings.keyboard-tables')
local environment = require('config.environment')

local create_platform_info = require('utils.platform')
local platform = create_platform_info(wezterm.target_triple)

local mod = {}
if platform.is_mac then
  mod.SUPER = 'SUPER'
  mod.SUPER_REV = 'SUPER|CTRL'
elseif platform.is_win then
  mod.SUPER = 'ALT'
  mod.SUPER_REV = 'ALT|CTRL'
else
  mod.SUPER = 'ALT'
  mod.SUPER_REV = 'ALT|CTRL'
end

local leader = { key = 'a', mods = 'ALT', timeout_milliseconds = 750 }
local locale_t = (environment.locale and environment.locale.t) or {}

local base_keys = {
   { key = 'F1',     mods = 'NONE',        action = 'ActivateCopyMode' },
   { key = 'F2',     mods = 'NONE',        action = act.ActivateCommandPalette },
   { key = 'F3',     mods = 'NONE',        action = act.ShowLauncher },
   { key = 'F4',     mods = 'NONE',        action = act.ShowTabNavigator },
   { key = 'F11',    mods = 'NONE',        action = act.ToggleFullScreen },
   { key = 'F12',    mods = 'NONE',        action = act.ShowDebugOverlay },
   { key = "F12", mods = "SHIFT", action = bindings_utils.create_shift_f12_debug_action(wezterm) },
   { key = "F10", mods = "NONE", action = bindings_utils.create_f10_settings_action(wezterm) },
   { key = "F8", mods = "NONE", action = bindings_utils.create_debug_panel_action(wezterm) },
   { key = "F9", mods = "NONE", action = bindings_utils.create_locale_manager_action(wezterm) },
   { key = 'f', mods = mod.SUPER, action = act.Search({ CaseInSensitiveString = '' }) },
   { key = 'r', mods = 'SHIFT|' .. mod.SUPER, action = bindings_utils.create_force_reload_action(wezterm) },
   { key = 'c', mods = mod.SUPER, action = act.CopyTo('Clipboard') },
   { key = 'v', mods = mod.SUPER, action = act.PasteFrom('Clipboard') },
   { key = 't', mods = mod.SUPER, action = act.SpawnTab('DefaultDomain') },
   { key = 'w', mods = mod.SUPER, action = act.CloseCurrentTab({ confirm = false }) },
   { key = 'w', mods = mod.SUPER_REV, action = act.CloseCurrentTab({ confirm = false }) },
   { key = 'LeftArrow', mods = mod.SUPER, action = act.ActivateTabRelative(-1) },
   { key = 'RightArrow', mods = mod.SUPER, action = act.ActivateTabRelative(1) },
   { key = 'LeftArrow', mods = mod.SUPER_REV, action = act.MoveTabRelative(-1) },
   { key = 'RightArrow', mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },
   { key = 'n', mods = mod.SUPER, action = act.SpawnWindow },
   { key = 'q', mods = mod.SUPER, action = act.QuitApplication },
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

local function build_keys()
  local keys = {}

  for _, key in ipairs(base_keys) do
    table.insert(keys, key)
  end

  for _, key in ipairs(bindings_utils.generate_appearance_bindings(wezterm, mod)) do
    table.insert(keys, key)
  end

  for _, key in ipairs(bindings_utils.generate_key_table_bindings(wezterm, mod)) do
    table.insert(keys, key)
  end

  if platform.is_mac then
    for _, key in ipairs(bindings_utils.generate_special_char_bindings(wezterm)) do
      table.insert(keys, key)
    end
  end

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

return {
   disable_default_key_bindings = true,
   leader = leader,
   keys = build_keys(),
   key_tables = key_tables,
}
