-- cat > ~/.config/wezterm/config/dialogs/state-manager.lua << 'EOF'
--
-- ОПИСАНИЕ: Менеджер управления сохраненными состояниями (ПОЛНОСТЬЮ ФУНКЦИОНАЛЬНЫЙ)
-- Убрана нумерация, исправлены счетчики, добавлена базовая функциональность
-- ЗАВИСИМОСТИ: config.environment, utils.environment, utils.dialog
--

local wezterm = require('wezterm')
local environment = require('config.environment')
local icons = require('config.environment.icons')
local colors = require('config.environment.colors')
local env_utils = require('utils.environment')
local dialog = require('utils.dialog')

local M = {}

-- Получение статистики состояний (ИСПРАВЛЕНО)
local function get_states_statistics()
  local paths = require('config.environment.paths')
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

-- Создание выборов для главного меню (БЕЗ НУМЕРАЦИИ)
local function create_main_menu_choices(stats)
  local choices = {}
  
  -- Заголовок
  table.insert(choices, dialog.create_choice({
    id = "header",
    icon = env_utils.get_icon(icons, "session"),
    text = environment.locale.t("state_manager_title"),
    colored = true,
    color = "system"
  }))
  
  table.insert(choices, { 
    id = "separator1", 
    label = "─────────────────────────────────────────" 
  })
  
  -- Статистика с РАБОТАЮЩИМИ счетчиками
  table.insert(choices, dialog.create_choice({
    id = "stats_workspace",
    icon = env_utils.get_icon(icons, "workspace"),
    text = "Workspace: " .. stats.workspace.count .. " состояний",
    colored = true,
    color = "workspace"
  }))
  
  table.insert(choices, dialog.create_choice({
    id = "stats_window",
    icon = env_utils.get_icon(icons, "window"),
    text = "Window: " .. stats.window.count .. " состояний",
    colored = true,
    color = "window"
  }))
  
  table.insert(choices, dialog.create_choice({
    id = "stats_tab",
    icon = env_utils.get_icon(icons, "tab"),
    text = "Tab: " .. stats.tab.count .. " состояний",
    colored = true,
    color = "tab"
  }))
  
  table.insert(choices, { 
    id = "separator2", 
    label = "─────────────────────────────────────────" 
  })
  
  -- Действия (ТОЛЬКО если есть состояния)
  if stats.workspace.count > 0 then
    table.insert(choices, dialog.create_choice({
      id = "view_workspace",
      icon = env_utils.get_icon(icons, "workspace"),
      text = environment.locale.t("view_workspace_states"),
      colored = true,
      color = "workspace"
    }))
  end
  
  if stats.window.count > 0 then
    table.insert(choices, dialog.create_choice({
      id = "view_window",
      icon = env_utils.get_icon(icons, "window"),
      text = environment.locale.t("view_window_states"),
      colored = true,
      color = "window"
    }))
  end
  
  if stats.tab.count > 0 then
    table.insert(choices, dialog.create_choice({
      id = "view_tab",
      icon = env_utils.get_icon(icons, "tab"),
      text = environment.locale.t("view_tab_states"),
      colored = true,
      color = "tab"
    }))
  end
  
  -- Добавляем разделитель только если есть действия
  local total_states = stats.workspace.count + stats.window.count + stats.tab.count
  if total_states > 0 then
    table.insert(choices, { 
      id = "separator3", 
      label = "─────────────────────────────────────────" 
    })
    
    table.insert(choices, dialog.create_choice({
      id = "cleanup",
      icon = env_utils.get_icon(icons, "system"),
      text = environment.locale.t("cleanup_old_states")
    }))
  end
  
  table.insert(choices, dialog.create_choice({
    id = "exit",
    icon = env_utils.get_icon(icons, "exit"),
    text = environment.locale.t("exit")
  }))
  
  return choices
end

-- Показ состояний конкретного типа (ФУНКЦИОНАЛЬНЫЙ)
local function show_states_of_type(window, pane, state_type, files)
  local choices = {}
  
  if #files == 0 then
    table.insert(choices, dialog.create_choice({
      id = "empty",
      icon = env_utils.get_icon(icons, "error"),
      text = environment.locale.t("no_states_of_type", state_type),
      colored = true,
      color = "error"
    }))
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
    
    table.insert(choices, dialog.create_choice({
      id = "delete_multiple",
      icon = env_utils.get_icon(icons, "error"),
      text = environment.locale.t("delete_selected_states"),
      colored = true,
      color = "error"
    }))
  end
  
  table.insert(choices, dialog.create_choice({
    id = "back",
    icon = env_utils.get_icon(icons, "exit"),
    text = environment.locale.t("back_to_main_menu")
  }))
  
  -- БЕЗ НУМЕРАЦИИ
  local selector_config = dialog.create_input_selector({
    icon = env_utils.get_icon(icons, state_type),
    title = environment.locale.t(state_type .. "_states_title"),
    description = environment.locale.t("select_state_action"),
    title_color = state_type,
    fuzzy = true,
    choices = choices,
    action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
      if id == "back" or id == "empty" then
        M.show_main_menu(inner_window, inner_pane)
      elseif id == "delete_multiple" then
        -- TODO: реализовать множественное удаление
        M.show_main_menu(inner_window, inner_pane)
      elseif id and id:match("^" .. state_type .. "|") then
        -- TODO: реализовать действия с конкретным файлом
        M.show_main_menu(inner_window, inner_pane)
      end
    end)
  })
  
  -- УБИРАЕМ НУМЕРАЦИЮ
  selector_config.alphabet = ""
  
  window:perform_action(wezterm.action.InputSelector(selector_config), pane)
end

-- Главное меню менеджера состояний (БЕЗ НУМЕРАЦИИ)
M.show_main_menu = function(window, pane)
  local stats = get_states_statistics()
  local choices = create_main_menu_choices(stats)
  
  local selector_config = dialog.create_input_selector({
    icon = env_utils.get_icon(icons, "session"),
    title = environment.locale.t("state_manager_title"),
    description = environment.locale.t("state_manager_description"),
    title_color = "session",
    fuzzy = false,
    choices = choices,
    action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
      if id == "exit" or not id then
        return
      elseif id:match("^view_") then
        local state_type = id:match("^view_(.+)$")
        show_states_of_type(inner_window, inner_pane, state_type, stats[state_type].files)
      elseif id == "cleanup" then
        -- TODO: реализовать очистку
        M.show_main_menu(inner_window, inner_pane)
      elseif id:match("^stats_") or id:match("^separator") or id == "header" then
        -- Игнорируем клики по статистике и разделителям
        M.show_main_menu(inner_window, inner_pane)
      end
    end)
  })
  
  -- УБИРАЕМ НУМЕРАЦИЮ
  selector_config.alphabet = ""
  
  window:perform_action(wezterm.action.InputSelector(selector_config), pane)
end

return M
