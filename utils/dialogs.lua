local M = {}

M.create_selector_dialog = function(wezterm, config)
  return {
title = config.title,
description = config.description,
fuzzy = config.fuzzy or true,
choices = config.choices or {},
action = config.action
  }
end

M.show_f10_main_settings = function(wezterm, window, pane, menu_data, existing_managers)
  local tab = window:active_tab()
  local environment = require('config.environment')
  local title = environment.locale.t[menu_data.title_key] or "Центр управления"
  tab:set_title(title)
  
  local choices = {}
  table.insert(choices, { id = "separator_top", label = "─────────────────────────────────────────────────────────" })  for _, item in ipairs(menu_data.menu_items) do
local status_icon = (item.status == "ready") and "✅" or "🔧"
local item_title = environment.locale.t[item.title_key] or item.title_key
table.insert(choices, {
  id = item.id,
  label = status_icon .. " " .. item_title
})
  end
  
  table.insert(choices, { id = "exit", label = "🚪 Выход" })
  
  window:perform_action(wezterm.action.InputSelector({
title = title,
choices = choices,
action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
  if id == "locale_settings" then
    existing_managers.locale_manager.show_locale_manager(inner_window, inner_pane)
  elseif id == "debug_settings" then
    existing_managers.debug_manager.show_panel(inner_window, inner_pane)
  end
end)
  }), pane)
end

M.show_debug_panel = function(wezterm, window, pane)
  local debug = require('utils.debug')
  local environment = require('config.environment')
  local colors = require('config.environment.colors')
  local env_utils = require('utils.environment')
  
  local tab = window:active_tab()
  local tab_color = env_utils.get_color(colors, "debug_control"); window:set_config_overrides({ colors = { tab_bar = { active_tab = { bg_color = tab_color, fg_color = "#FFFFFF" } } } }); tab:set_title("Панель управления отладкой")
  
  local modules = {}
  for module_name, _ in pairs(debug.DEBUG_CONFIG) do 
table.insert(modules, module_name) 
  end
  table.sort(modules)
  
  local descriptions = {
session_status = "Статус сессий и режимов терминала",
appearance = "Внешний вид, фоны и прозрачность",
resurrect = "Сохранение и восстановление сессий", 
workspace = "Управление рабочими пространствами",
bindings = "Горячие клавиши и биндинги",
global = "Общесистемная отладка WezTerm"
  }
  
  local choices = {}
  table.insert(choices, { id = "separator_top", label = "─────────────────────────────────────────────────────────" })  for i, module_name in ipairs(modules) do
local enabled = debug.DEBUG_CONFIG[module_name] or false
local status_icon = enabled and (environment.icons and environment.icons.t and environment.icons.t.system) or "✅" or (environment.icons and environment.icons.t and environment.icons.t.error) or "❌"
local description = descriptions[module_name] or "Модуль отладки"

if enabled then
  table.insert(choices, {
    id = module_name,
    label = wezterm.format({
      { Foreground = { Color = env_utils.get_color(colors, "debug_control") } },
      { Text = string.format("%s %s - %s", status_icon, module_name, description) }
    })
  })
else
  table.insert(choices, {
    id = module_name,
    label = string.format("%s %s - %s", status_icon, module_name, description)
  })
end
  end
  
  table.insert(choices, { id = "separator", label = "─────────────────────────────────────────────────────────" })
  table.insert(choices, { id = "enable_all", label = "  " .. (environment.icons and environment.icons.t and environment.icons.t.system) or "✅" .. "  Включить все модули" })
  table.insert(choices, { id = "disable_all", label = "  " .. (environment.icons and environment.icons.t and environment.icons.t.error) or "❌" .. "  Выключить все модули" })
  table.insert(choices, { id = "exit", label = "  " .. environment.icons.t.exit .. "  Выход" })
  
  local enabled_count = 0
  for _, enabled in pairs(debug.DEBUG_CONFIG) do
if enabled then enabled_count = enabled_count + 1 end
  end
  
  window:perform_action(wezterm.action.InputSelector({
title = "Панель управления отладкой",
description = string.format("Активно: %d/%d модулей | ESC: F10 меню", enabled_count, #modules),

fuzzy = false,
choices = choices,
action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
  if id == "exit" then
    M.show_f10_main_settings(wezterm, inner_window, inner_pane, 
      require("config.dialogs.settings-manager"), {
        locale_manager = require("config.dialogs.locale-manager"),
        debug_manager = { show_panel = function(w,p) M.show_debug_panel(wezterm,w,p) end }
      })
  elseif id == "enable_all" then
    for module_name, _ in pairs(debug.DEBUG_CONFIG) do
      debug.DEBUG_CONFIG[module_name] = true
    end
    debug.save_debug_settings(wezterm)
    M.show_debug_panel(wezterm, inner_window, inner_pane)
  elseif id == "disable_all" then
    for module_name, _ in pairs(debug.DEBUG_CONFIG) do
      debug.DEBUG_CONFIG[module_name] = false
    end
    debug.save_debug_settings(wezterm)
    M.show_debug_panel(wezterm, inner_window, inner_pane)
  elseif id ~= "separator" then
    debug.DEBUG_CONFIG[id] = not debug.DEBUG_CONFIG[id]
    debug.save_debug_settings(wezterm)
    M.show_debug_panel(wezterm, inner_window, inner_pane)
  end
end)
  }), pane)
end

return M
