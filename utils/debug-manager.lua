-- cat > ~/.config/wezterm/utils/debug-manager.lua << 'EOF'
--
-- ОПИСАНИЕ: Интерактивный менеджер отладки для WezTerm
-- Позволяет включать/выключать отладку модулей через Debug Overlay (F12)
-- Автоматически определяет доступные модули из utils/debug.lua
--
-- ИСПОЛЬЗОВАНИЕ: В Debug Overlay введите: :debug-enable session_status
--                                         :debug-disable session_status  
--                                         :debug-list
--                                         :debug-all-on
--                                         :debug-all-off

local wezterm = require('wezterm')
local debug = require('utils.debug')
local environment = require('config.environment')

local M = {}

-- Автоматическое получение списка доступных модулей из debug.DEBUG_CONFIG
M.get_available_modules = function()
  local modules = {}
  for module_name, _ in pairs(debug.DEBUG_CONFIG) do
    table.insert(modules, module_name)
  end
  table.sort(modules) -- Сортируем для удобства
  return modules
end

-- Функция для обработки debug команд
M.handle_debug_command = function(command, args)
  local cmd = command:lower()
  local available_modules = M.get_available_modules()
  
  if cmd == "debug-enable" then
    local module = args[1]
    if module and M.is_valid_module(module, available_modules) then
      debug.enable_debug(wezterm, environment.locale.t, module)
      return environment.locale.t("debug_enabled_for_module", module)
    else
      return environment.locale.t("debug_invalid_module") .. table.concat(available_modules, ", ")
    end
    
  elseif cmd == "debug-disable" then
    local module = args[1]  
    if module and M.is_valid_module(module, available_modules) then
      debug.disable_debug(wezterm, environment.locale.t, module)
      return environment.locale.t("debug_disabled_for_module", module)
    else
      return environment.locale.t("debug_invalid_module") .. table.concat(available_modules, ", ")
    end
    
  elseif cmd == "debug-all-on" then
    debug.enable_all(wezterm, environment.locale.t)
    return environment.locale.t("debug_all_enabled")
    
  elseif cmd == "debug-all-off" then
    debug.disable_all(wezterm, environment.locale.t)
    return environment.locale.t("debug_disabled_all")
    
  elseif cmd == "debug-list" then
    local status = {}
    for _, module in ipairs(available_modules) do
      local state = debug.DEBUG_CONFIG[module] and environment.locale.t("debug_status_on") or environment.locale.t("debug_status_off")
      table.insert(status, module .. ": " .. state)
    end
    return environment.locale.t("debug_status_title") .. "\n" .. table.concat(status, "\n")
    
  elseif cmd == "debug-help" then
    return environment.locale.t("debug_help_text", table.concat(available_modules, ", "))
  end
  
  return nil
end

-- Проверка валидности модуля
M.is_valid_module = function(module, available_modules)
  for _, valid_module in ipairs(available_modules) do
    if valid_module == module then
      return true
    end
  end
  return false
end

-- Регистрация обработчика команд в Debug Overlay
M.setup = function()
  local available_modules = M.get_available_modules()
  debug.log(wezterm, environment.locale.t, wezterm, environment.locale.t, "global", "debug_manager_initialized", table.concat(available_modules, ", "))
  debug.log(wezterm, environment.locale.t, wezterm, environment.locale.t, "global", "debug_manager_help_hint")
end

return M
