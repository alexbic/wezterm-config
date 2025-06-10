local M = {}

M.show_debug_panel = function(wezterm, window, pane)
  local debug = require('utils.debug')
  local environment = require('config.environment')
  
  local tab = window:active_tab()
  tab:set_title("Панель управления отладкой")
  
  local modules = {"appearance", "bindings", "global", "resurrect", "session_status", "workspace"}
  
  local descriptions = {
    session_status = "Статус сессий и режимов терминала",
    appearance = "Внешний вид, фоны и прозрачность",
    resurrect = "Сохранение и восстановление сессий",
    workspace = "Управление рабочими пространствами",
    bindings = "Горячие клавиши и биндинги",
    global = "Общесистемная отладка WezTerm"
  }
  
  local choices = {}
  
  -- Верхний разделитель
  table.insert(choices, {
    id = "header_separator",
    label = wezterm.format({
      { Foreground = { Color = "#FFFFFF" } },
      { Text = " ───────────────────────────────────────────────────────" }
    })
  })
  
  -- Модули с нумерацией 1-6
  for i, module_name in ipairs(modules) do
    local enabled = debug.DEBUG_CONFIG[module_name] or false
    local status_icon = enabled and "⚙" or "✗"
    local description = descriptions[module_name] or "Модуль отладки"
    
    table.insert(choices, {
      id = module_name,
      label = wezterm.format({
        { Foreground = { Color = "#FFFFFF" } },
        { Text = string.format(" %d.  %s  %-15s  -  %s", i, status_icon, module_name, description) }
      })
    })
  end
  
  -- Нижний разделитель
  table.insert(choices, {
    id = "footer_separator",
    label = wezterm.format({
      { Foreground = { Color = "#FFFFFF" } },
      { Text = " ───────────────────────────────────────────────────────" }
    })
  })
  
  -- Служебные команды
  table.insert(choices, {
    id = "enable_all",
    label = wezterm.format({
      { Foreground = { Color = "#FFFFFF" } },
      { Text = "      ⚙  Включить все модули" }
    })
  })
  
  table.insert(choices, {
    id = "disable_all",
    label = wezterm.format({
      { Foreground = { Color = "#FFFFFF" } },
      { Text = "      ✗  Выключить все модули" }
    })
  })
  
  table.insert(choices, {
    id = "exit",
    label = wezterm.format({
      { Foreground = { Color = "#FFFFFF" } },
      { Text = "      ⏏  Выход" }
    })
  })
  
  window:perform_action(wezterm.action.InputSelector({
    title = wezterm.format({
      { Foreground = { Color = "#FF6B6B" } },
      { Text = "Панель управления отладкой" }
    }),
    description = "",
    fuzzy_description = "Выбери модуль:",
    fuzzy = true,
    choices = choices,
    action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
      if id == "exit" or id == "header_separator" or id == "footer_separator" then
        if id == "exit" then
          M.show_f10_main_settings(wezterm, inner_window, inner_pane,
            require("config.dialogs.settings-manager"), {
              locale_manager = require("config.dialogs.locale-manager"),
              debug_manager = { show_panel = function(w,p) M.show_debug_panel(wezterm,w,p) end },
              state_manager = require("config.dialogs.state-manager")
            })
        end
        return
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
      else
        debug.DEBUG_CONFIG[id] = not debug.DEBUG_CONFIG[id]
        debug.save_debug_settings(wezterm)
        M.show_debug_panel(wezterm, inner_window, inner_pane)
      end
    end)
  }), pane)
end

M.show_f10_main_settings = function(wezterm, window, pane, menu_data, existing_managers)
  local tab = window:active_tab()
  local environment = require('config.environment')
  local title = environment.locale.t[menu_data.title_key] or "Центр управления"
  tab:set_title(title)
  
  local choices = {}
  table.insert(choices, { id = "separator_top", label = "─────────────────────────────────────────────────────────" })
  
  for _, item in ipairs(menu_data.menu_items) do
    local status_icon = (item.status == "ready") and "✅" or "🔧"
    local item_title = environment.locale.t[item.title_key] or item.title_key
    table.insert(choices, {
      id = item.id,
      label = status_icon .. " " .. item_title
    })
  end
  
  table.insert(choices, { id = "exit", label = "  🚪  Выход" })
  
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


-- Универсальная функция построения InputSelector диалогов
M.build_inputselector = function(wezterm, dialog_config, action_callback)
  local environment = require("config.environment")
  local choices = {}
  
  -- Верхний разделитель
  table.insert(choices, {
    id = "header_separator",
    label = wezterm.format({
      { Foreground = { Color = "#FFFFFF" } },
      { Text = " ───────────────────────────────────────────────────────" }
    })
  })
  
  -- Основные пункты с нумерацией
  for i, item in ipairs(dialog_config.main_items or {}) do
    local icon = environment.icons.t[item.icon_key] or "⚙"
    local text = environment.locale.t[item.text_key] or item.text_key
    
    table.insert(choices, {
      id = item.id,
      label = wezterm.format({
        { Foreground = { Color = "#FFFFFF" } },
        { Text = string.format(" %d.  %s  %-15s  -  %s", i, icon, item.id, text) }
      })
    })
  end
  
  -- Нижний разделитель + служебные команды
  table.insert(choices, {
    id = "footer_separator",
    label = wezterm.format({
      { Foreground = { Color = "#FFFFFF" } },
      { Text = " ───────────────────────────────────────────────────────" }
    })
  })
  
  -- Служебные команды
  for _, item in ipairs(dialog_config.service_items or {}) do
    local icon = environment.icons.t[item.icon_key] or "⚙"
    local text = environment.locale.t[item.text_key] or item.text_key
    
    table.insert(choices, {
      id = item.id,
      label = wezterm.format({
        { Foreground = { Color = "#FFFFFF" } },
        { Text = string.format("      %s  %s", icon, text) }
      })
    })
  end
  
  return wezterm.action.InputSelector({
    title = environment.locale.t[dialog_config.meta.title_key] or dialog_config.meta.title_key,
    description = dialog_config.meta.description or "",
    fuzzy = dialog_config.meta.fuzzy or true,
    choices = choices,
    action = action_callback
  })
end
return M
