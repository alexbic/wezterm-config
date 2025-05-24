-- cat > ~/.config/wezterm/config/appearance/index.lua << 'EOF'
--
-- ОПИСАНИЕ: Точка входа для appearance-модулей WezTerm
-- Собирает и экспортирует все подмодули внешнего вида: фоны, прозрачность, события.
--
-- ЗАВИСИМОСТИ: backgrounds.lua, transparency.lua, events.lua

local backgrounds = require('config.appearance.backgrounds')
local transparency = require('config.appearance.transparency')
local colors = require('config.environment.colors')
local scheme = colors.colorscheme
local mocha = colors.mocha

return {
  background_image = backgrounds.random_background,
  transparency = transparency,
  -- никаких events и других модулей с функциями!
  -- можно добавить другие параметры, но только данные!
}
