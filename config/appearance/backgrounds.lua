-- cat > ~/.config/wezterm/config/appearance/backgrounds.lua << 'EOF'
--
-- ОПИСАНИЕ: Работа с фоновыми изображениями WezTerm
-- Поиск, выбор и установка фоновых картинок для окон и вкладок.
--
-- ЗАВИСИМОСТИ: utils.platform, config.environment.paths

local wezterm = require('wezterm')
local platform = require('utils.platform')()
local paths = require('config.environment.paths')

-- Список поддерживаемых расширений изображений
local image_formats = { "jpg", "jpeg", "png", "webp" }

local M = {}

local function log(_) end -- логгирование можно добавить по желанию

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

return M
