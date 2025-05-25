local wezterm = require('wezterm')
local M = {}

-- Инициализация плагина Smart Workspace Switcher
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
M.workspace_switcher = workspace_switcher

-- Настройка пути к zoxide для macOS
workspace_switcher.zoxide_path = "/opt/homebrew/bin/zoxide"

return M
