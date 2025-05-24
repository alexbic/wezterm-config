-- cat > ~/.config/wezterm/config/environment/index.lua << 'EOF'
--
-- ОПИСАНИЕ: Точка входа для environment-модулей WezTerm
-- Собирает и экспортирует все подмодули окружения: пути, локаль, devtools, цвета, терминал, приложения, шрифты.
--
-- ЗАВИСИМОСТИ: paths.lua, locale.lua, devtools.lua, colors.lua, terminal.lua, apps.lua, fonts.lua

local paths = require('config.environment.paths')
local locale = require('config.environment.locale')
local devtools = require('config.environment.devtools')
local colors = require('config.environment.colors')
local terminal = require('config.environment.terminal')
local apps = require('config.environment.apps')
local fonts = require('config.environment.fonts')

return {
  paths = paths,
  locale = locale,
  devtools = devtools,
  colors = colors,
  terminal = terminal,
  apps = apps,
  fonts = fonts,
}
