-- cat > ~/.config/wezterm/config/appearance/backgrounds.lua << 'EOF'
-- ОПИСАНИЕ: Работа с фоновыми изображениями WezTerm (только данные)

local wezterm = require('wezterm')
local appearance = require('utils.appearance')
local env_utils = require('utils.environment')

-- Создаем platform_info
local create_platform_info = require('utils.platform')
local platform = create_platform_info(wezterm.target_triple)

-- Получаем пути через новую функцию
local paths = env_utils.create_environment_paths(
  wezterm.home_dir,
  wezterm.config_dir,
  platform
)

local all_images = appearance.find_all_background_images(platform, paths.backdrops)
local random_background = appearance.get_random_background(all_images)

return {
  all_images = all_images,
  random_background = random_background,
}
