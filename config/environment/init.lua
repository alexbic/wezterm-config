local wezterm = require('wezterm')
local env_utils = require('utils.environment')
local create_platform_info = require('utils.platform')
local platform = create_platform_info(wezterm.target_triple)

local locale = require('config.environment.locale')
local devtools = require('config.environment.devtools')
local colors = require('config.environment.colors')
local terminal = require('config.environment.terminal')
local apps = require('config.environment.apps')
local fonts_data = require('config.environment.fonts')
local globals = require('config.environment.globals')

local fonts_config = env_utils.create_font_config(wezterm, platform, fonts_data)

local result = {
  locale = locale,
  devtools = devtools,
  colors = colors,
  terminal = terminal,
  apps = apps,
  globals = globals,
}

-- Добавляем fonts_config ключи в result-- Разворачиваем fonts_config ключи в result
for key, value in pairs(fonts_config) do
  result[key] = value
end

return result
