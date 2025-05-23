-- cat > ~/.config/wezterm/config/appearance/events.lua << 'EOF'
--
-- ОПИСАНИЕ: Обработчики событий внешнего вида WezTerm
-- Реализует события для смены прозрачности, фона, панели вкладок и др.
-- Используется для динамического управления внешним видом через события.
--
-- ЗАВИСИМОСТИ: wezterm, config.appearance.transparency

local wezterm = require('wezterm')
local transparency = require('config.appearance.transparency')
local colors = require('config.environment.colors')
local scheme = colors.colorscheme
local mocha = colors.mocha

local M = {}

function M.register_opacity_events()
  wezterm.on("cycle-opacity-forward", function(window, pane)
    wezterm.GLOBALS.current_opacity_index = (wezterm.GLOBALS.current_opacity_index + 1) % #transparency.opacity_settings
    local settings = transparency.opacity_settings[wezterm.GLOBALS.current_opacity_index + 1]
    local overrides = window:get_config_overrides() or {}
    overrides.window_background_opacity = settings.opacity
    window:set_config_overrides(overrides)
    window:set_title(settings.title)
  end)

  wezterm.on("cycle-opacity-backward", function(window, pane)
    wezterm.GLOBALS.current_opacity_index = (wezterm.GLOBALS.current_opacity_index - 1)
    if wezterm.GLOBALS.current_opacity_index < 0 then
      wezterm.GLOBALS.current_opacity_index = #transparency.opacity_settings - 1
    end
    local settings = transparency.opacity_settings[wezterm.GLOBALS.current_opacity_index + 1]
    local overrides = window:get_config_overrides() or {}
    overrides.window_background_opacity = settings.opacity
    window:set_config_overrides(overrides)
    window:set_title(settings.title)
  end)
end

return M

