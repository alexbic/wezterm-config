-- cat > ~/.config/wezterm/config/dialogs/debug-manager.lua << 'EOF'
--
-- ОПИСАНИЕ: UI панель управления отладкой с централизованными иконками
-- Интерактивный диалог для включения/выключения модулей отладки
-- ЗАВИСИМОСТИ: utils.debug, config.environment, config.environment.icons, utils.environment
--
-- ЗАВИСИМОСТИ: config.environment, utils.debug

local wezterm = require('wezterm')
local debug = require('utils.debug')
local environment = require('config.environment')
local icons = require('config.environment.icons')
local colors = require('config.environment.colors')
local env_utils = require('utils.environment')

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

-- Создание выборов для селектора с централизованными иконками
local function create_choices()
  local modules = {}
  for module_name, _ in pairs(debug.DEBUG_CONFIG) do 
    table.insert(modules, module_name) 
  end
  table.sort(modules)
  
  local choices = {}
  
  -- Добавляем каждый модуль с цветовым выделением
  for i, module_name in ipairs(modules) do
    local enabled = debug.DEBUG_CONFIG[module_name] or false
    local status_icon = enabled and env_utils.get_icon(icons, "system") or env_utils.get_icon(icons, "error")
    local description = get_module_description(module_name)
    
    if enabled then
      -- Включенный модуль - цветной
      table.insert(choices, {
        id = module_name,
        label = wezterm.format({
          { Foreground = { Color = env_utils.get_color(colors, "debug_control") } },
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
  
  -- Команды управления с локализацией и иконками
  table.insert(choices, {
    id = "enable_all",
    label = "      " .. env_utils.get_icon(icons, "system") .. "  Включить все модули"
  })
  
  table.insert(choices, {
    id = "disable_all", 
    label = "      " .. env_utils.get_icon(icons, "error") .. "  Выключить все модули"
  })
  
  table.insert(choices, {
    id = "help",
    label = "      " .. env_utils.get_icon(icons, "tip") .. "  Справка и помощь"
  })
  
  table.insert(choices, {
    id = "exit",
    label = "      " .. env_utils.get_icon(icons, "exit") .. "  Сохранить и выйти"
  })
  
  return choices
end

-- Показ панели отладки
M.show_panel = function(window, pane)
  local choices = create_choices()
  local modules = {}
  for module_name, _ in pairs(debug.DEBUG_CONFIG) do 
    table.insert(modules, module_name) 
  end
  table.sort(modules)
  
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
          -- TODO: показать справку
          M.show_panel(inner_window, inner_pane)
          return
        end
        
        if id == "enable_all" then
          for module_name, _ in pairs(debug.DEBUG_CONFIG) do
            debug.DEBUG_CONFIG[module_name] = true
          end
          debug.save_debug_settings()
          M.show_panel(inner_window, inner_pane)
          
        elseif id == "disable_all" then
          for module_name, _ in pairs(debug.DEBUG_CONFIG) do
            debug.DEBUG_CONFIG[module_name] = false
          end
          debug.save_debug_settings()
          M.show_panel(inner_window, inner_pane)
          
        else
          -- Переключаем конкретный модуль
          debug.DEBUG_CONFIG[id] = not debug.DEBUG_CONFIG[id]
          debug.save_debug_settings()
          M.show_panel(inner_window, inner_pane)
        end
      end),
      title = env_utils.get_icon(icons, "debug") .. " Панель управления отладкой",
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

return M
