local keyboard = require('config.bindings.keyboard')
local keyboard_tables = require('config.bindings.keyboard-tables')
local mouse = require('config.bindings.mouse')
local global = require('config.bindings.global')

return {
  keyboard = keyboard,
  keyboard_tables = keyboard_tables,
  mouse = mouse,
  global = global,
}
