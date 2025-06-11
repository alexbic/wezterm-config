local M = {}

-- Функция отображения отладочной панели (специализированная)
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
  table.insert(choices, {id = "header_separator", label = "───────────────────────────────────────────────────────"})
  
  for i, module_name in ipairs(modules) do
    local enabled = debug.DEBUG_CONFIG[module_name] or false
    local status_icon = enabled and "⚙" or "✗"
    local description = descriptions[module_name] or "Модуль отладки"
    table.insert(choices, {id = module_name, label = string.format("%d.  %s  %-15s  -  %s", i, status_icon, module_name, description)})
  end
  
  table.insert(choices, {id = "footer_separator", label = "───────────────────────────────────────────────────────"})
  table.insert(choices, {id = "enable_all", label = "     ⚙  Включить все модули"})
  table.insert(choices, {id = "disable_all", label = "     ✗  Выключить все модули"})
  table.insert(choices, {id = "exit", label = "     ⏏  Выход"})
  
  window:perform_action(wezterm.action.InputSelector({
    title = "🪲 Панель управления отладкой",
    description = "",
    fuzzy_description = "Выбери модуль:",
    fuzzy = true,
    choices = choices,
    action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
      wezterm.log_info("DEBUG: Clicked id=[" .. tostring(id) .. "] label=[" .. tostring(label) .. "]")
      -- ✅ РАЗДЕЛИТЕЛИ ИГНОРИРУЮТСЯ
      if id == "header_separator" or id == "footer_separator" then
        return  -- НЕ ДЕЛАЕМ НИЧЕГО
      end
      
      if id == "exit" then
        M.show_f10_main_settings(wezterm, inner_window, inner_pane, require("config.dialogs.settings-manager"))
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

-- Функция F10 главного меню
M.show_f10_main_settings = function(wezterm, window, pane, menu_data)
  if not menu_data then
    menu_data = require("config.dialogs.settings-manager")
  end
  
  local tab = window:active_tab()
  local environment = require('config.environment')
  local title = environment.locale.t[menu_data.title_key] or "Центр управления"
  tab:set_title(title)
  
  local choices = {}
  table.insert(choices, { id = "separator_top", label = "─────────────────────────────────────────────────────────" })
  
  for _, item in ipairs(menu_data.menu_items or {}) do
    local status_icon = (item.status == "ready") and "✅" or "🔧"
    local item_title = environment.locale.t[item.title_key] or item.title_key
    table.insert(choices, {id = item.id, label = status_icon .. " " .. item_title})
  end
  
  table.insert(choices, { id = "exit", label = "  🚪  Выход" })
  
  window:perform_action(wezterm.action.InputSelector({
    title = title,
    choices = choices,
    action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
      wezterm.log_info("DEBUG: Clicked id=[" .. tostring(id) .. "] label=[" .. tostring(label) .. "]")
      -- ✅ РАЗДЕЛИТЕЛИ F10 ИГНОРИРУЮТСЯ
      if id == "separator_top" then
        return  -- НЕ ДЕЛАЕМ НИЧЕГО
      end
      
      if id == "locale_settings" then
        require("config.dialogs.locale-manager").show_locale_manager(inner_window, inner_pane)
      elseif id == "debug_settings" then
        M.show_debug_panel(wezterm, inner_window, inner_pane)
      elseif id == "state_settings" then
        local state_manager = require("config.dialogs.state-manager")
        if state_manager.show_main_menu then 
          state_manager.show_main_menu(inner_window, inner_pane) 
        end
      end
    end)
  }), pane)
end

-- Универсальная функция построения InputSelector диалогов
M.build_inputselector = function(wezterm, dialog_config, state_provider)
  local environment = require("config.environment")
  local colors = require("config.environment.colors")
  local env_utils = require("utils.environment")
  local choices = {}
  
  table.insert(choices, {id = "header_separator", label = "───────────────────────────────────────────────────────"})
  
  for i, item in ipairs(dialog_config.main_items or {}) do
    local text = environment.locale.t[item.text_key] or item.text_key
    local icon = "✗"
    local label_format = string.format("%d.  %s  %-15s  -  %s", i, icon, item.id, text)
    
    if state_provider and state_provider.get_state then
      local state = state_provider.get_state(item.id)
      if state == true then
        icon = "⚙"
        label_format = string.format("%d.  %s  %-15s  -  %s", i, icon, item.id, text)
        table.insert(choices, {
          id = item.id,
          label = wezterm.format({
            { Foreground = { Color = env_utils.get_color(colors, "debug_control") } },
            { Text = label_format }
          })
        })
      else
        table.insert(choices, {id = item.id, label = label_format})
      end
    else
      table.insert(choices, {id = item.id, label = label_format})
    end
  end
  
  table.insert(choices, {id = "footer_separator", label = "───────────────────────────────────────────────────────"})
  
  for _, item in ipairs(dialog_config.service_items or {}) do
    local icon = environment.icons.t[item.icon_key] or "⚙"
    local text = environment.locale.t[item.text_key] or item.text_key
    table.insert(choices, {id = item.id, label = string.format("     %s  %s", icon, text)})
  end
  
  table.insert(choices, {id = "exit", label = "     ⏏  Выход"})
  
  local title_icon = environment.icons.t[dialog_config.meta.icon_key] or ""
  local title_text = environment.locale.t[dialog_config.meta.title_key] or dialog_config.meta.title_key
  local full_title = (title_icon ~= "" and (title_icon .. " ") or "") .. title_text
  
  return wezterm.action.InputSelector({
    title = full_title,
    description = dialog_config.meta.description or "",
    fuzzy_description = "Выбери пункт:",
    fuzzy = dialog_config.meta.fuzzy or true,
    choices = choices,
    action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
      wezterm.log_info("DEBUG: Clicked id=[" .. tostring(id) .. "] label=[" .. tostring(label) .. "]")
      -- ✅ РАЗДЕЛИТЕЛИ ИГНОРИРУЮТСЯ
      if id == "header_separator" or id == "footer_separator" then
        return  -- НЕ ДЕЛАЕМ НИЧЕГО
      end
      
      local tab_title = environment.locale.t[dialog_config.meta.tab_title_key] or "Диалог"
      inner_window:active_tab():set_title(tab_title)
      
      if id == "exit" then
        inner_window:active_tab():set_title("")
        M.show_f10_main_settings(wezterm, inner_window, inner_pane, require("config.dialogs.settings-manager"))
        return
      end
      
      if state_provider and state_provider.handle_action then
        local result = state_provider.handle_action(id, inner_window, inner_pane)
        if result and type(result) == "table" and result.action == "refresh" then
          wezterm.time.call_after(0.1, function()
            inner_window:perform_action(M.build_inputselector(wezterm, dialog_config, state_provider), inner_pane)
          end)
        end
      end
    end)
  })
end

-- Универсальная функция создания селектора
M.create_selector_dialog = function(wezterm, config)
  return {
    title = config.title, 
    description = config.description, 
    fuzzy = config.fuzzy or true, 
    choices = config.choices or {}, 
    action = config.action
  }
end

return M
