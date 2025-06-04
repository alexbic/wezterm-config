-- cat > ~/.config/wezterm/config/environment/init.lua << 'EOF'
--
-- ОПИСАНИЕ: Точка входа для environment-модулей WezTerm
-- Собирает и экспортирует все подмодули окружения: локаль, devtools, цвета, терминал, приложения, шрифты.
-- ИСПРАВЛЕНО: Убрана зависимость от paths.lua (функции перенесены в utils/environment.lua)
--
-- ЗАВИСИМОСТИ: locale.lua, devtools.lua, colors.lua, terminal.lua, apps.lua, fonts.lua

local locale = require('config.environment.locale')
local devtools = require('config.environment.devtools')
local colors = require('config.environment.colors')
local terminal = require('config.environment.terminal')
local apps = require('config.environment.apps')
local fonts = require('config.environment.fonts')

return {
  locale = locale,
  devtools = devtools,
  colors = colors,
  terminal = terminal,
  apps = apps,
  fonts = fonts,
}
