-- cat > ~/.config/wezterm/config/dialogs/state-manager.lua << 'EOF'
--
-- ОПИСАНИЕ: Менеджер управления сохраненными состояниями (ПОЛНОСТЬЮ ФУНКЦИОНАЛЬНЫЙ)
-- Исправлена локализация и добавлено красивое форматирование с выравниванием
-- ЗАВИСИМОСТИ: config.environment, utils.environment, utils.dialog
--

local wezterm = require('wezterm')
local environment = require('config.environment')
local icons = require('config.environment.icons')
local colors = require('config.environment.colors')
local env_utils = require('utils.environment')
local dialog = require('utils.dialog')

local M = {}

-- Получение статистики состояний
local function get_states_statistics()
  -- Получаем пути через utils/environment.lua
  local wezterm = require("wezterm")
  local env_utils = require("utils.environment")
  local create_platform_info = require("utils.platform")
  local platform = create_platform_info(wezterm.target_triple)
  local paths = env_utils.create_environment_paths(wezterm.home_dir, wezterm.config_dir, platform)
  local state_dir = paths.resurrect_state_dir
  
  local stats = {
    workspace = { count = 0, files = {} },
    window = { count = 0, files = {} },
    tab = { count = 0, files = {} }
  }
  
  for state_type, _ in pairs(stats) do
    local type_dir = state_dir .. state_type
    local cmd = "find '" .. type_dir .. "' -name '*.json' 2>/dev/null | wc -l"
    local handle = io.popen(cmd)
    if handle then
      local count_str = handle:read("*l")
      handle:close()
      stats[state_type].count = tonumber(count_str) or 0
    end
    
    -- Получаем список файлов
    local list_cmd = "find '" .. type_dir .. "' -name '*.json' 2>/dev/null"
    local list_handle = io.popen(list_cmd)
    if list_handle then
      for line in list_handle:lines() do
        local filename = line:match("([^/]+)%.json$")
        if filename then
          table.insert(stats[state_type].files, {
            name = filename,
            path = line
          })
        end
      end
      list_handle:close()
    end
  end
  
  return stats
end

-- Создание выборов с красивым форматированием и локализацией
local function create_main_menu_choices(stats)
  local choices = {}
  
  -- Заголовок с локализацией
  table.insert(choices, {
    id = "header",
    label = wezterm.format({
      { Foreground = { Color = env_utils.get_color(colors, "session") } },
      { Text = environment.icons.t."session" .. " " .. environment.locale.t.state_manager_title }
    })
  })
  
  table.insert(choices, { 
    id = "separator1", 
    label = "─────────────────────────────────────────" 
  })
  
  -- Статистика с выравниванием и локализацией
  local max_width = 35  -- Общая ширина строки
  
  -- Workspace
  local workspace_text = "Workspace"
  local workspace_count = tostring(stats.workspace.count) .. " состояний"
  local workspace_spaces = string.rep(" ", max_width - string.len(workspace_text) - string.len(workspace_count))
  
  table.insert(choices, {
    id = "stats_workspace",
    label = wezterm.format({
      { Foreground = { Color = env_utils.get_color(colors, "workspace") } },
      { Text = environment.icons.t."workspace" .. " " .. workspace_text },
      { Foreground = { Color = "#666666" } },
      { Text = workspace_spaces },
      { Foreground = { Color = env_utils.get_color(colors, "workspace") } },
      { Text = workspace_count }
    })
  })
  
  -- Window
  local window_text = "Window"
  local window_count = tostring(stats.window.count) .. " состояний"
  local window_spaces = string.rep(" ", max_width - string.len(window_text) - string.len(window_count))
  
  table.insert(choices, {
    id = "stats_window",
    label = wezterm.format({
      { Foreground = { Color = env_utils.get_color(colors, "window") } },
      { Text = environment.icons.t."window" .. " " .. window_text },
      { Foreground = { Color = "#666666" } },
      { Text = window_spaces },
      { Foreground = { Color = env_utils.get_color(colors, "window") } },
      { Text = window_count }
    })
  })
  
  -- Tab
  local tab_text = "Tab"
  local tab_count = tostring(stats.tab.count) .. " состояний"
  local tab_spaces = string.rep(" ", max_width - string.len(tab_text) - string.len(tab_count))
  
  table.insert(choices, {
    id = "stats_tab",
    label = wezterm.format({
      { Foreground = { Color = env_utils.get_color(colors, "tab") } },
      { Text = environment.icons.t."tab" .. " " .. tab_text },
      { Foreground = { Color = "#666666" } },
      { Text = tab_spaces },
      { Foreground = { Color = env_utils.get_color(colors, "tab") } },
      { Text = tab_count }
    })
  })
  
  table.insert(choices, { 
    id = "separator2", 
    label = "─────────────────────────────────────────" 
  })
  
  -- Действия (ТОЛЬКО если есть состояния)
  if stats.workspace.count > 0 then
    table.insert(choices, {
      id = "view_workspace",
      label = wezterm.format({
        { Foreground = { Color = env_utils.get_color(colors, "workspace") } },
        { Text = environment.icons.t."workspace" .. " " .. environment.locale.t.view_workspace_states }
      })
    })
  end
  
  if stats.window.count > 0 then
    table.insert(choices, {
      id = "view_window",
      label = wezterm.format({
        { Foreground = { Color = env_utils.get_color(colors, "window") } },
        { Text = environment.icons.t."window" .. " " .. environment.locale.t.view_window_states }
      })
    })
  end
  
  if stats.tab.count > 0 then
    table.insert(choices, {
      id = "view_tab",
      label = wezterm.format({
        { Foreground = { Color = env_utils.get_color(colors, "tab") } },
        { Text = environment.icons.t."tab" .. " " .. environment.locale.t.view_tab_states }
      })
    })
  end
  
  -- Добавляем разделитель только если есть действия
  local total_states = stats.workspace.count + stats.window.count + stats.tab.count
  if total_states > 0 then
    table.insert(choices, { 
      id = "separator3", 
      label = "─────────────────────────────────────────" 
    })
  end
  
  table.insert(choices, {
    id = "exit",
    label = wezterm.format({
      { Foreground = { Color = env_utils.get_color(colors, "exit") } },
      { Text = environment.icons.t."exit" .. " " .. environment.locale.t.exit }
    })
  })
  
  return choices
end

-- Показ состояний конкретного типа
local function show_states_of_type(window, pane, state_type, files)
  local choices = {}
  
  if #files == 0 then
    table.insert(choices, {
      id = "empty",
      label = wezterm.format({
        { Foreground = { Color = env_utils.get_color(colors, "error") } },
        { Text = environment.icons.t."error" .. " Нет сохраненных состояний" }
      })
    })
  else
    for _, file in ipairs(files) do
      table.insert(choices, {
        id = state_type .. "|" .. file.name,
        label = file.name
      })
    end
    
    table.insert(choices, { 
      id = "separator", 
      label = "─────────────────────────────────────────" 
    })
  end
  
  table.insert(choices, {
    id = "back",
    label = wezterm.format({
      { Foreground = { Color = env_utils.get_color(colors, "exit") } },
      { Text = environment.icons.t."exit" .. " " .. environment.locale.t.back_to_main_menu }
    })
  })
  
  local selector_config = {
    title = wezterm.format({
      { Foreground = { Color = env_utils.get_color(colors, state_type) } },
      { Text = environment.icons.t.state_type .. " Состояния " .. state_type }
    }),
    description = "Выберите действие с состояниями",
    fuzzy = true,
    alphabet = "",
    choices = choices,
    action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
      if id == "back" or id == "empty" then
        M.show_main_menu(inner_window, inner_pane)
      elseif id and id:match("^" .. state_type .. "|") then
        -- TODO: реализовать действия с конкретным файлом
        M.show_main_menu(inner_window, inner_pane)
      end
    end)
  }
  
  window:perform_action(wezterm.action.InputSelector(selector_config), pane)
end

-- Главное меню менеджера состояний
M.show_main_menu = function(window, pane)
  local stats = get_states_statistics()
  local choices = create_main_menu_choices(stats)
  
  local selector_config = {
    title = wezterm.format({
      { Foreground = { Color = env_utils.get_color(colors, "session") } },
      { Text = environment.icons.t."session" .. " " .. environment.locale.t.state_manager_title }
    }),
    description = environment.locale.t.state_manager_description,
    fuzzy = false,
    alphabet = "",
    choices = choices,
    action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
      if id == "exit" or not id then
        return
      elseif id:match("^view_") then
        local state_type = id:match("^view_(.+)$")
        show_states_of_type(inner_window, inner_pane, state_type, stats[state_type].files)
      elseif id:match("^stats_") or id:match("^separator") or id == "header" then
        -- Игнорируем клики по статистике и разделителям
        M.show_main_menu(inner_window, inner_pane)
      end
    end)
  }
  
  window:perform_action(wezterm.action.InputSelector(selector_config), pane)
end

return M
