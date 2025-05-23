-- cat > ~/.config/wezterm/utils/appearance.lua << 'EOF'
-- ОПИСАНИЕ: Утилиты для работы с внешним видом (appearance) WezTerm

local wezterm = require('wezterm')
local platform = require('utils.platform')()
local paths = require('config.environment.paths')

local M = {}

-- === Backgrounds ===
local image_formats = { "jpg", "jpeg", "png", "webp" }

function M.find_all_background_images()
  local all_files = {}
  if platform.directory_exists(paths.backgrounds) then
    for _, ext in ipairs(image_formats) do
      local pattern = "*." .. ext
      local files = platform.get_files_in_directory(paths.backgrounds, pattern)
      for _, file in ipairs(files) do
        if platform.file_exists(file) then
          table.insert(all_files, file)
        end
      end
    end
  end
  return all_files
end

function M.get_random_background(background_files)
  if not background_files or #background_files == 0 then return nil end
  math.randomseed(os.time())
  local index = math.random(1, #background_files)
  return background_files[index]
end

function M.get_background_for_tab(tab_id, background_files, tab_backgrounds)
  if not tab_backgrounds[tab_id] then
    tab_backgrounds[tab_id] = M.get_random_background(background_files)
  end
  return tab_backgrounds[tab_id]
end

-- === Events ===
function M.register_opacity_events(transparency)
  wezterm.on("cycle-opacity-forward", function(window, pane)
    wezterm.GLOBALS.current_opacity_index = (wezterm.GLOBALS.current_opacity_index + 1) % #transparency.opacity_settings
    local settings = transparency.opacity_settings[wezterm.GLOBALS.current_opacity_index + 1]
    local overrides = window:get_config_overrides() or {}
    overrides.window_background_opacity = settings.opacity
    window:set_config_overrides(overrides)
    window:set_title(settings.title)
  end)

  wezterm.on("cycle-opacity-backward", function(window, pane)
    wezterm.GLOBALS.current_opacity_index = (wezterm.GLOBALS.current_opacity_index - 1)
    if wezterm.GLOBALS.current_opacity_index < 0 then
      wezterm.GLOBALS.current_opacity_index = #transparency.opacity_settings - 1
    end
    local settings = transparency.opacity_settings[wezterm.GLOBALS.current_opacity_index + 1]
    local overrides = window:get_config_overrides() or {}
    overrides.window_background_opacity = settings.opacity
    window:set_config_overrides(overrides)
    window:set_title(settings.title)
  end)
end

-- === Transparency (заглушка для будущих функций) ===
-- function M.set_opacity(window, value)
--   -- ...
-- end

return M
