-- cat > ~/.config/wezterm/utils/debug-panel.lua << 'EOF'
--
-- ОПИСАНИЕ: Локализованная панель отладки с правильной справкой
-- Использует ключи локализации для отображения справки
--
-- ЗАВИСИМОСТИ: utils.debug, utils.debug-manager, config.environment

local wezterm = require('wezterm')
local debug = require('utils.debug')
local debug_manager = require('utils.debug-manager')
local environment = require('config.environment')

local M = {}

-- Описания модулей
local function get_module_description(module_name)
  local descriptions = {
    session_status = "Статус сессий и режимов терминала",
    appearance = "Внешний вид, фоны и прозрачность",
    resurrect = "Сохранение и восстановление сессий",
    workspace = "Управление рабочими пространствами",
    bindings = "Горячие клавиши и биндинги",
    global = "Общесистемная отладка WezTerm"
  }
  return descriptions[module_name] or "Модуль отладки"
end

-- Функция показа справки с правильной локализацией
local function show_help(window, pane)
  local t = environment.locale.t
  
  local help_choices = {
    { id = "title", label = "📖 " .. t("debug_help_title") },
    { id = "empty1", label = "" },
    { id = "what", label = t("debug_help_what") },
    { id = "empty2", label = "" },
    { id = "how", label = "🔧 " .. t("debug_help_how") },
    { id = "step1", label = t("debug_help_step1") },
    { id = "step2", label = t("debug_help_step2") },
    { id = "step3", label = t("debug_help_step3") },
    { id = "step4", label = t("debug_help_step4") },
    { id = "empty3", label = "" },
    { id = "modules", label = "📋 " .. t("debug_help_modules") },
    { id = "appearance", label = t("debug_help_appearance") },
    { id = "bindings", label = t("debug_help_bindings") },
    { id = "global", label = t("debug_help_global") },
    { id = "resurrect", label = t("debug_help_resurrect") },
    { id = "session", label = t("debug_help_session") },
    { id = "workspace", label = t("debug_help_workspace") }
  }
  
  window:perform_action(
    wezterm.action.InputSelector({
      action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
        M.show_panel(inner_window, inner_pane)
      end),
      title = "🪲 " .. t("debug_help_title"),
      description = "Нажмите Enter для возврата к панели отладки",
      fuzzy = false,
      choices = help_choices,
    }),
    pane
  )
end
-- Создание выборов для селектора
local function create_choices()
  local modules = debug_manager.get_available_modules()
  local choices = {}
  
  -- Добавляем каждый модуль с цветовым выделением
  for i, module_name in ipairs(modules) do
    local enabled = debug.DEBUG_CONFIG[module_name] or false
    local status_icon = enabled and "✓" or "✗"
    local description = get_module_description(module_name)
    
    if enabled then
      -- Включенный модуль - цветной
      table.insert(choices, {
        id = module_name,
        label = wezterm.format({
          { Foreground = { Color = "#4ECDC4" } },
          { Text = string.format(" %d    %s  %-15s - %s", i, status_icon, module_name, description) }
        })
      })
    else
      -- Выключенный модуль - обычный
      table.insert(choices, {
        id = module_name,
        label = string.format(" %d    %s  %-15s - %s", i, status_icon, module_name, description)
      })
    end
  end
  
  -- Разделитель
  table.insert(choices, {
    id = "separator",
    label = "─────────────────────────────────────────────────────────"
  })
  
  -- Команды управления с локализацией
  table.insert(choices, {
    id = "enable_all",
    label = "      ✓  " .. environment.locale.t("debug_enable_all_modules")
  })
  
  table.insert(choices, {
    id = "disable_all", 
    label = "      ✗  " .. environment.locale.t("debug_disable_all_modules")
  })
  
  table.insert(choices, {
    id = "help",
    label = "      ⓘ  " .. (environment.locale.get_language_table().name == "English" and "Help and Info" or "Справка и помощь")
  })
  
  table.insert(choices, {
    id = "exit",
    label = "      ⏏  " .. environment.locale.t("debug_save_and_exit")
  })
  
  return choices
end

-- Показ панели отладки
M.show_panel = function(window, pane)
  local choices = create_choices()
  local modules = debug_manager.get_available_modules()
  
  -- Подсчет статистики
  local enabled_count = 0
  for _, module_name in ipairs(modules) do
    if debug.DEBUG_CONFIG[module_name] then
      enabled_count = enabled_count + 1
    end
  end
  
  window:perform_action(
    wezterm.action.InputSelector({
      action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
        if not id or id == "exit" then
          return
        end
        
        if id == "separator" then
          M.show_panel(inner_window, inner_pane)
          return
        end
        
        if id == "help" then
          show_help(inner_window, inner_pane)
          return
        end
        
        if id == "enable_all" then
          for module_name, _ in pairs(debug.DEBUG_CONFIG) do
            debug.DEBUG_CONFIG[module_name] = true
          end
          M.show_panel(inner_window, inner_pane)
          
        elseif id == "disable_all" then
          for module_name, _ in pairs(debug.DEBUG_CONFIG) do
            debug.DEBUG_CONFIG[module_name] = false
          end
          M.show_panel(inner_window, inner_pane)
          
        else
          -- Переключаем конкретный модуль
          debug.DEBUG_CONFIG[id] = not debug.DEBUG_CONFIG[id]
          M.show_panel(inner_window, inner_pane)
        end
      end),
      title = "🪲 " .. environment.locale.t("debug_panel_title"),
      description = string.format("Активно: %d/%d модулей", enabled_count, #modules),
      fuzzy_description = "Найти модуль:",
      fuzzy = true,
      choices = choices,
    }),
    pane
  )
end

-- Главная функция создания панели
M.create_panel = function(window, pane)
  M.show_panel(window, pane)
end

-- Заглушки для совместимости
M.move_up = function() end
M.move_down = function() end
M.toggle_current = function() end
M.enable_all = function() end
M.disable_all = function() end
M.save_and_close = function(window) end
M.cancel_and_close = function(window) end
M.close_panel = function(window, saved) end
M.update_display = function() end

return M
