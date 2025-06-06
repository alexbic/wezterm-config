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


-- === Функции для диалогов удаления состояний ===

-- Функция для создания обработчика удаления состояний
M.create_delete_state_handler = function(wezterm, session_status, environment, icons, colors, env_utils)
  return function(window, pane)
    session_status.delete_session_start(window)
    session_status.start_dialog()    
    -- Устанавливаем название вкладки для правильного определения
    local tab = window:active_tab()
    tab:set_title(environment.locale.t.delete_session_tab_title or "Delete")
    
    local choices = {}

    -- Получаем все сохранённые состояния с нашими иконками и цветами
    local env_utils = require("utils.environment")
    local create_platform_info = require("utils.platform")
    local platform = create_platform_info(wezterm.target_triple)
    local paths = env_utils.create_environment_paths(wezterm.home_dir, wezterm.config_dir, platform)
    local state_types = {
      {type = "workspace", icon = "󱂬", color = "workspace"},
      {type = "window", icon = nil, color = "window"},
      {type = "tab", icon = "󰓩", color = "debug"}
    }

    for _, state_info in ipairs(state_types) do
      local state_dir = paths.resurrect_state_dir .. state_info.type
      local cmd = "ls " .. state_dir .. "/*.json 2>/dev/null || true"
      local handle = io.popen(cmd)
      if handle then
        for line in handle:lines() do
          local name = line:match("([^/]+)%.json$")
          if name then
            local type_label = environment.locale.t[state_info.type .. "_type"]
            
            table.insert(choices, {
              id = state_info.type .. "/" .. name .. ".json",
              label = wezterm.format({
                { Foreground = { Color = env_utils.get_color(colors, state_info.color) } },
                { Text = (state_info.icon or environment.icons.t.state_info.type) .. " : " .. name .. " (" .. type_label .. ")" }
              })
            })
          end
        end
        handle:close()
      end
    end

    if #choices == 0 then
      table.insert(choices, {
        id = "none",
        label = wezterm.format({
          { Foreground = { Color = env_utils.get_color(colors, "error") } },
          { Text = "❌ " .. environment.locale.t.no_workspaces_available }
        })
      })
    end

    -- Используем наш локализованный InputSelector
    window:perform_action(
      wezterm.action.InputSelector({
        action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
          session_status.end_dialog()
          session_status.clear_saved_mode()          -- Возвращаем обычное название вкладки
          inner_window:active_tab():set_title("")

          if not id or id == "none" then
            return
          end

          -- Обработка удаления
          local type = string.match(id, "^([^/]+)")
          local clean_id = string.match(id, "([^/]+)$")
          clean_id = string.match(clean_id, "(.+)%..+$")

          -- Удаляем состояние
          local resurrect = require('wezterm').plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
          resurrect.state_manager.delete_state(id)
          
          -- Уведомляем об успехе
          wezterm.time.call_after(0.5, function()
            session_status.delete_session_success(inner_window, clean_id)
          end)
        end),
        title = environment.icons.t."list_delete_tab" .. " " .. environment.locale.t.deleting_sessions_title,
        description = environment.locale.t.deleting_sessions_description,
        fuzzy_description = environment.locale.t.deleting_sessions_fuzzy,
        fuzzy = true,
        choices = choices,
      }),
      pane
    )
  end
end
return M
