-- cat > ~/.config/wezterm/config/appearance/backgrounds.lua << 'EOF'
-- ОПИСАНИЕ: Работа с фоновыми изображениями WezTerm (только данные)

local wezterm = require('wezterm')
local appearance = require('utils.appearance')
local paths = require('config.environment.paths')

-- Создаем platform_info
local create_platform_info = require('utils.platform')
local platform = create_platform_info(wezterm.target_triple)

local all_images = appearance.find_all_background_images(platform, paths.backdrops)
local random_background = appearance.get_random_background(all_images)

return {
  all_images = all_images,
  random_background = random_background,
}
