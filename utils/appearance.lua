-- cat > ~/.config/wezterm/utils/appearance.lua << 'EOF'
--
-- ОПИСАНИЕ: Утилиты для работы с внешним видом (appearance) WezTerm
-- ПОЛНОСТЬЮ САМОДОСТАТОЧНЫЙ МОДУЛЬ - все зависимости передаются как параметры.
--
-- ЗАВИСИМОСТИ: НЕТ

local M = {}

-- === Backgrounds ===
local image_formats = { "jpg", "jpeg", "png", "webp" }

function M.find_all_background_images(platform_utils, backdrops_path)
  local all_files = {}
  if platform_utils.directory_exists(backdrops_path) then
    for _, ext in ipairs(image_formats) do
      local pattern = "*." .. ext
      local files = platform_utils.get_files_in_directory(backdrops_path, pattern)
      for _, file in ipairs(files) do
        if platform_utils.file_exists(file) then
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
function M.register_opacity_events(wezterm, transparency)
  -- Инициализируем глобальные переменные
  if not _G.WEZTERM_OPACITY then 
    _G.WEZTERM_OPACITY = {
      current_opacity_index = 6 -- начинаем с 100% (последний элемент)
    }
  end

  wezterm.on("cycle-opacity-forward", function(window, pane)
    if not window then
      window = wezterm.mux.get_active_window()
    end
    if not window then return end
    
    _G.WEZTERM_OPACITY.current_opacity_index = 
      (_G.WEZTERM_OPACITY.current_opacity_index + 1) % #transparency.opacity_settings
    local settings = transparency.opacity_settings[_G.WEZTERM_OPACITY.current_opacity_index + 1]
    local overrides = window:get_config_overrides() or {}
    overrides.window_background_opacity = settings.opacity
    window:set_config_overrides(overrides)
  end)

  wezterm.on("cycle-opacity-backward", function(window, pane)
    if not window then
      window = wezterm.mux.get_active_window()
    end
    if not window then return end
    
    _G.WEZTERM_OPACITY.current_opacity_index = 
      (_G.WEZTERM_OPACITY.current_opacity_index - 1)
    if _G.WEZTERM_OPACITY.current_opacity_index < 0 then
      _G.WEZTERM_OPACITY.current_opacity_index = #transparency.opacity_settings - 1
    end
    local settings = transparency.opacity_settings[_G.WEZTERM_OPACITY.current_opacity_index + 1]
    local overrides = window:get_config_overrides() or {}
    overrides.window_background_opacity = settings.opacity
    window:set_config_overrides(overrides)
  end)
end

-- === Window Positioning ===
function M.setup_window_centering(wezterm)
  wezterm.on("gui-startup", function(cmd)
    local screen = wezterm.gui.screens().active
    local ratio = 0.6  -- 60% от размера экрана
    local width, height = screen.width * ratio, screen.height * ratio
    
    local tab, pane, window = wezterm.mux.spawn_window(cmd or {
      position = {
        x = (screen.width - width) / 2,
        y = (screen.height - height) / 2,
        origin = "ActiveScreen"
      }
    })
    
    window:gui_window():set_inner_size(width, height)
  end)
end

return M
