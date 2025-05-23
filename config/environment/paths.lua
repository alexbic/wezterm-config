-- cat > ~/.config/wezterm/config/environment/paths.lua << 'EOF'
--
-- ОПИСАНИЕ: Пути и директории для окружения WezTerm
-- Определяет основные и специфичные для платформы пути, используемые в конфигурации.
--
-- ЗАВИСИМОСТИ: wezterm, utils.platform

local wezterm = require('wezterm')
local platform = require('utils.platform')()

local M = {
  home = wezterm.home_dir,
  config = wezterm.config_dir,
}

-- Название каталога для фоновых изображений
local backdrops = "backdrops"

-- Определяем путь к backdrops (каталог с фонами)
local config_backdrops_dir
if platform.is_win then
  config_backdrops_dir = M.config .. "\\" .. backdrops
else
  config_backdrops_dir = M.config .. "/" .. backdrops
end

-- Проверяем, существует ли каталог backdrops в каталоге конфигурации
local function dir_exists(path)
  local ok, _, code = os.rename(path, path)
  return ok or code == 13 -- 13 = Permission denied (но папка есть)
end

if dir_exists(config_backdrops_dir) then
  M.backdrops = config_backdrops_dir
else
  if platform.is_win then
    M.backdrops = M.home .. "\\Pictures\\" .. backdrops
  else
    M.backdrops = M.home .. "/Pictures/" .. backdrops
  end
end

if platform.is_mac then
  M.brew = "/opt/homebrew"
  M.applications = "/Applications"
elseif platform.is_linux then
  M.local_bin = M.home .. "/.local/bin"
  M.usr_local = "/usr/local"
elseif platform.is_win then
  M.program_files = "C:\\Program Files"
  M.appdata = os.getenv("APPDATA") or ""
end

return M
