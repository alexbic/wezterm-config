-- Статические данные окружения (без wezterm зависимостей)
local locale = require('config.environment.locale')
local devtools = require('config.environment.devtools')
local colors = require('config.environment.colors')
local terminal = require('config.environment.terminal')
local apps = require('config.environment.apps')
local fonts_data = require('config.environment.fonts')
local globals = require('config.environment.globals')

return {
  locale = locale,
  devtools = devtools,
  colors = colors,
  terminal = terminal,
  apps = apps,
  fonts_data = fonts_data,
  globals = globals,
}
