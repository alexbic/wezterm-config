local wezterm = require('wezterm')  
local bindings_utils = require('utils.bindings')
local act = wezterm.action
local key_tables = require('config.bindings.keyboard-tables')
local environment = require('config.environment')
local create_platform_info = require('utils.platform')
local platform = create_platform_info(wezterm.target_triple)

-- Объявления один раз в начале файла
local debug = require("utils.debug")
local locale_cache = require("config.environment.locale")

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
   { key = 'F1', mods = 'NONE', action = 'ActivateCopyMode' },
   { key = 'F2', mods = 'NONE', action = act.ActivateCommandPalette },
   { key = 'F3', mods = 'NONE', action = act.ShowLauncher },
   { key = 'F4', mods = 'NONE', action = act.ShowTabNavigator },
   
   -- F5-F8 с правильным обращением к кэшу через .t
   { key = "F5", mods = "NONE", action = wezterm.action_callback(function(window, pane)
       local message = "F5 " .. locale_cache.t.unused_key_not_used
       debug.log(wezterm, nil, "bindings", message)
   end) },
   
   { key = "F6", mods = "NONE", action = wezterm.action_callback(function(window, pane)
       local message = "F6 " .. locale_cache.t.unused_key_not_used
       debug.log(wezterm, nil, "bindings", message)
   end) },
   
   { key = "F7", mods = "NONE", action = wezterm.action_callback(function(window, pane)
       local message = "F7 " .. locale_cache.t.unused_key_not_used
       debug.log(wezterm, nil, "bindings", message)
   end) },
   
   { key = "F8", mods = "NONE", action = wezterm.action_callback(function(window, pane)
       local message = "F8 " .. locale_cache.t.unused_key_not_used
       debug.log(wezterm, nil, "bindings", message)
   end) },
   
   { key = "F9", mods = "NONE", action = bindings_utils.create_locale_manager_action(wezterm) },
   { key = "F10", mods = "NONE", action = bindings_utils.create_f10_settings_action(wezterm) },
   { key = 'F11', mods = 'NONE', action = act.ToggleFullScreen },
   { key = 'F12', mods = 'NONE', action = act.ShowDebugOverlay },
   { key = "F12", mods = "SHIFT", action = bindings_utils.create_shift_f12_debug_action(wezterm) },
   
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
   { key = '1', mods = mod.SUPER, action = act.ActivateTab(0) },
   { key = '2', mods = mod.SUPER, action = act.ActivateTab(1) },
   { key = '3', mods = mod.SUPER, action = act.ActivateTab(2) },
   { key = '4', mods = mod.SUPER, action = act.ActivateTab(3) },
   { key = '5', mods = mod.SUPER, action = act.ActivateTab(4) },
   { key = '6', mods = mod.SUPER, action = act.ActivateTab(5) },
   { key = '7', mods = mod.SUPER, action = act.ActivateTab(6) },
   { key = '8', mods = mod.SUPER, action = act.ActivateTab(7) },
   { key = '9', mods = mod.SUPER, action = act.ActivateTab(8) },
   { key = '0', mods = mod.SUPER, action = act.ActivateTab(9) },
}

local keys = bindings_utils.build_keys(wezterm, base_keys, mod, platform, locale_t)

return {
  disable_default_key_bindings = false,
  leader = leader,
  keys = keys,
  key_tables = key_tables,
}
