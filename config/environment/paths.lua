-- cat > ~/.config/wezterm/config/environment/paths.lua << 'EOF'
--
-- ОПИСАНИЕ: Пути и директории для окружения WezTerm
-- Определяет основные и специфичные для платформы пути, используемые в конфигурации.
--
-- ЗАВИСИМОСТИ: wezterm, utils.platform

local wezterm = require('wezterm')
local platform = require('utils.platform')()

-- === КОНСТАНТЫ КОНФИГУРАЦИИ ===
local BACKDROPS_DIR = "backdrops"
local RESURRECT_STATE_PATH = "plugins/resurrect.wezterm/state"

-- === БАЗОВЫЕ ПУТИ ===
local M = {
  home = wezterm.home_dir,
  config = wezterm.config_dir,
}

-- === ПЛАТФОРМО-ЗАВИСИМЫЕ НАСТРОЙКИ ===
if platform.is_win then
  -- Windows пути
  local separator = "\\"
  M.backdrops = M.config .. separator .. BACKDROPS_DIR
  M.resurrect_state_dir = M.config .. separator .. RESURRECT_STATE_PATH .. separator
  M.program_files = "C:\\Program Files"
  M.appdata = os.getenv("APPDATA") or ""
  
elseif platform.is_mac then
  -- macOS пути
  local separator = "/"
  M.backdrops = M.config .. separator .. BACKDROPS_DIR
  M.resurrect_state_dir = M.config .. separator .. RESURRECT_STATE_PATH .. separator
  M.brew = "/opt/homebrew"
  M.applications = "/Applications"
  
else
  -- Linux/Unix пути
  local separator = "/"
  M.backdrops = M.config .. separator .. BACKDROPS_DIR
  M.resurrect_state_dir = M.config .. separator .. RESURRECT_STATE_PATH .. separator
  M.local_bin = M.home .. "/.local/bin"
  M.usr_local = "/usr/local"
end

return M
