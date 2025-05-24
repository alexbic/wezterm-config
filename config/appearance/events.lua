-- cat > ~/.config/wezterm/config/appearance/events.lua << 'EOF'
-- ОПИСАНИЕ: Обработчики событий внешнего вида WezTerm (только вызовы)

local transparency = require('config.appearance.transparency')
local appearance = require('utils.appearance')

appearance.register_opacity_events(transparency)

return {}
