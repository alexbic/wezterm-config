-- cat > ~/.config/wezterm/config/appearance/index.lua << 'EOF'
--
-- ОПИСАНИЕ: Точка входа для appearance-модулей WezTerm
-- Собирает и экспортирует все подмодули внешнего вида: фоны, прозрачность, события.
--
-- ЗАВИСИМОСТИ: backgrounds.lua, transparency.lua, events.lua

local backgrounds = require('config.appearance.backgrounds')
local transparency = require('config.appearance.transparency')
local events = require('config.appearance.events')
local colors = require('config.environment.colors')
local scheme = colors.colorscheme
local mocha = colors.mocha

return {
  backgrounds = backgrounds,
  transparency = transparency,
  events = events,
}
