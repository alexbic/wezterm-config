-- cat > ~/.config/wezterm/config/appearance/backgrounds.lua << 'EOF'
-- ОПИСАНИЕ: Работа с фоновыми изображениями WezTerm (только данные)

local appearance = require('utils.appearance')

local all_images = appearance.find_all_background_images()
local random_background = appearance.get_random_background(all_images)

return {
  all_images = all_images,
  random_background = random_background,
}
