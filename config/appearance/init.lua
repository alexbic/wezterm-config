-- cat > ~/.config/wezterm/config/appearance/init.lua << 'EOF'
--
-- ОПИСАНИЕ: Точка входа для appearance-модулей WezTerm
-- Собирает и экспортирует все подмодули внешнего вида: фоны, прозрачность, события.
--
-- ЗАВИСИМОСТИ: backgrounds.lua, transparency.lua, events.lua

local backgrounds = require('config.appearance.backgrounds')
local colors = require('config.environment.colors')

return {
  window_background_image = backgrounds.random_background,
  -- Применяем цветовую схему напрямую
  colors = colors.colorscheme,
}
