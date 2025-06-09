-- НОВЫЙ МНОГОУРОВНЕВЫЙ МЕНЕДЖЕР СОСТОЯНИЙ

local wezterm = require('wezterm')
local environment = require('config.environment')
local dialogs = require('utils.dialogs')

local M = {}

-- Показ главного меню состояний (уровень 1)
M.show_main_menu = function(window, pane)
  local tab = window:active_tab()
  tab:set_title(environment.locale.t.state_manager_title)
  
  -- Подсчет состояний
  local stats = M.get_states_statistics()
  
  local items = {
    {
      id = "workspace_states",
      icon = environment.icons.t.workspace,
      text = environment.locale.t.workspace_states_count .. ": " .. stats.workspace,
      colored = stats.workspace > 0,
      color = "#50FA7B"
    },
    {
      id = "window_states", 
      icon = environment.icons.t.window,
      text = environment.locale.t.window_states_count .. ": " .. stats.window,
      colored = stats.window > 0,
      color = "#F1FA8C"
    },
    {
      id = "tab_states",
      icon = environment.icons.t.tab, 
      text = environment.locale.t.tab_states_count .. ": " .. stats.tab,
      colored = stats.tab > 0,
      color = "#FF79C6"
    }
  }
  
  local selector = dialogs.create_states_dialog(wezterm, {
    level = 1,
    items = items,
    action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
      if id == "exit" then
        require("utils.dialogs").show_f10_main_settings(wezterm, inner_window, inner_pane, 
          require("config.dialogs.settings-manager"), {
            locale_manager = require("config.dialogs.locale-manager"),
            debug_manager = require("config.dialogs.debug-manager"),
            state_manager = M
          })
        return
      end
      
      M.show_type_details(inner_window, inner_pane, id)
    end)
  })
  
  window:perform_action(wezterm.action.InputSelector(selector), pane)
end

-- Показ деталей типа состояний (уровень 2)
M.show_type_details = function(window, pane, state_type)
  local type_map = {
    workspace_states = "workspace",
    window_states = "window", 
    tab_states = "tab"
  }
  
  local actual_type = type_map[state_type]
  local states = M.get_states_by_type(actual_type)
  
  local items = {}
  for _, state in ipairs(states) do
    table.insert(items, {
      id = state.id,
      icon = environment.icons.t[actual_type],
      text = state.name .. " (" .. state.date .. ")",
      colored = false
    })
  end
  
  local selector = dialogs.create_states_dialog(wezterm, {
    level = 2,
    type_icon = environment.icons.t[actual_type],
    type_title = environment.locale.t[actual_type .. "_states_count"],
    description = "Выберите состояние для действий",
    header_text = "Найдено: " .. #states .. " состояний",
    items = items,
    action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
      if id == "back" then
        M.show_main_menu(inner_window, inner_pane)
      elseif id == "delete_all" then
        M.delete_all_states(inner_window, inner_pane, actual_type)
      else
        M.show_state_actions(inner_window, inner_pane, actual_type, id)
      end
    end)
  })
  
  window:perform_action(wezterm.action.InputSelector(selector), pane)
end

-- Получение статистики состояний
M.get_states_statistics = function()
  return { workspace = 3, window = 1, tab = 2 } -- Заглушка
end

-- Получение состояний по типу
M.get_states_by_type = function(state_type)
  return { -- Заглушка
    { id = "test1", name = "Test State 1", date = "2024-01-01" },
    { id = "test2", name = "Test State 2", date = "2024-01-02" }
  }
end

return M
