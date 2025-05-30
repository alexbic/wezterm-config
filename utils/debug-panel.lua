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
  
  -- Собираем текст справки из локализованных ключей
  local help_parts = {
    "📖 " .. t("debug_help_title"),
    "",
    t("debug_help_what"),
    "",
    "🔧 " .. t("debug_help_how"),
    t("debug_help_step1"),
    t("debug_help_step2"), 
    t("debug_help_step3"),
    t("debug_help_step4"),
    "",
    "📋 " .. t("debug_help_modules"),
    t("debug_help_appearance"),
    t("debug_help_bindings"),
    t("debug_help_global"),
    t("debug_help_resurrect"),
    t("debug_help_session"),
    t("debug_help_workspace"),
    "",
    t("debug_help_footer")
  }
  
  local help_text = table.concat(help_parts, "\n")
  
  window:perform_action(
    wezterm.action.InputSelector({
      action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
        M.show_panel(inner_window, inner_pane)
      end),
      title = "🪲 " .. t("debug_help_title"),
      description = help_text,
      fuzzy = false,
      choices = {
        {
          id = "back",
          label = "← " .. (environment.locale.get_language_table().name == "English" and "Return to debug panel" or "Вернуться к панели отладки")
        }
      },
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
