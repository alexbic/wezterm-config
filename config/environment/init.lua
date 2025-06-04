-- cat > ~/.config/wezterm/config/environment/init.lua << 'EOF'
--
-- ОПИСАНИЕ: Точка входа для environment-модулей WezTerm
-- Собирает и экспортирует все подмодули окружения: локаль, devtools, цвета, терминал, приложения, шрифты.
-- ОБНОВЛЕНО: Интегрирован с новой системой локализации через globals.lua
--
-- ЗАВИСИМОСТИ: locale.lua, devtools.lua, colors.lua, terminal.lua, apps.lua, fonts.lua, globals.lua

local locale = require('config.environment.locale')
local devtools = require('config.environment.devtools')
local colors = require('config.environment.colors')
local terminal = require('config.environment.terminal')
local apps = require('config.environment.apps')
local fonts = require('config.environment.fonts')
local globals = require('config.environment.globals')

return {
  locale = locale,
  devtools = devtools,
  colors = colors,
  terminal = terminal,
  apps = apps,
  fonts = fonts,
  globals = globals,
}
