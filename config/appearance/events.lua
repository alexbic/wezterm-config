local debug = require("utils.debug")
-- cat > ~/.config/wezterm/config/appearance/events.lua << 'EOF'
-- ОПИСАНИЕ: Обработчики событий внешнего вида WezTerm (только регистрация)

local wezterm = require('wezterm')

local function register_appearance_events()
  local transparency = require('config.appearance.transparency')
  local appearance = require('utils.appearance')
  local backgrounds = require('config.appearance.backgrounds')
  
  -- Регистрируем события прозрачности
  appearance.register_opacity_events(wezterm, transparency)
  
  -- Инициализируем глобальную таблицу для фонов вкладок
  if not wezterm.GLOBALS then wezterm.GLOBALS = {} end
  if not wezterm.GLOBALS.tab_backgrounds then 
    wezterm.GLOBALS.tab_backgrounds = {} 
  end
  
  -- Событие для установки случайного фона при создании новой вкладки
  wezterm.on('update-status', function(window, pane)
    if backgrounds.all_images and #backgrounds.all_images > 0 then
      local tab = window:active_tab()
      local tab_id = tab:tab_id()
      local new_background = appearance.get_background_for_tab(
        tab_id, 
        backgrounds.all_images, 
        wezterm.GLOBALS.tab_backgrounds
      )
      
      local overrides = window:get_config_overrides() or {}
      if not window or not window.get_config_overrides then return end      overrides.window_background_image = new_background
      overrides.window_background_image_hsb = {
        hue = 1.0,
        saturation = 1.02,
        brightness = 0.25,
      }
      window:set_config_overrides(overrides)
    end
  end)
  
  -- Событие для смены фона по горячей клавише
  wezterm.on('change-background', function(window, pane)
    if backgrounds.all_images and #backgrounds.all_images > 0 then
      local new_background = appearance.get_random_background(backgrounds.all_images)
      local overrides = window:get_config_overrides() or {}
      if not window or not window.get_config_overrides then return end      overrides.window_background_image = new_background
      overrides.window_background_image_hsb = {
        hue = 1.0,
        saturation = 1.02,
        brightness = 0.25,
      }
      window:set_config_overrides(overrides)
      debug.log("appearance", "debug_background_changed", new_background)
    end
  end)
end

return {
  register = register_appearance_events
}
