-- cat > ~/.config/wezterm/utils/debug.lua << 'EOF'
--
-- ОПИСАНИЕ: Улучшенная система управляемого отладочного логирования
-- Позволяет включать/выключать отладочные сообщения, локализовать их и отлаживать таблицы
-- ПОЛНОСТЬЮ САМОДОСТАТОЧНЫЙ МОДУЛЬ - все зависимости передаются как параметры.
--
-- ЗАВИСИМОСТИ: НЕТ

local M = {}

-- Настройки отладки (включить/выключить по модулям)
M.DEBUG_CONFIG = {
  session_status = false,    -- отладка статуса сессий
  appearance = false,        -- отладка внешнего вида
  resurrect = false,         -- отладка сохранения/восстановления
  workspace = false,         -- отладка workspace
  bindings = false,          -- отладка горячих клавиш
  global = false,            -- общая отладка
}

-- Функция для красивого вывода таблиц
local function table_to_string(tbl, indent, max_depth, current_depth)
  indent = indent or 0
  max_depth = max_depth or 3
  current_depth = current_depth or 0
  
  if current_depth >= max_depth then
    return "... (max depth reached)"
  end
  
  if type(tbl) ~= "table" then
    return tostring(tbl)
  end
  
  local result = ""
  local spaces = string.rep("  ", indent)
  
  for k, v in pairs(tbl) do
    if type(v) == "table" then
      result = result .. string.format("%s%s = {\n%s%s}\n", 
        spaces, tostring(k), 
        table_to_string(v, indent + 1, max_depth, current_depth + 1), 
        spaces)
    else
      result = result .. string.format("%s%s = %s\n", spaces, tostring(k), tostring(v))
    end
  end
  return result
end

M.table_to_string = table_to_string

-- Функция отладочного логирования с локализацией
-- Функция для системных сообщений без указания модуля
M.log_system = function(wezterm, t_func, message_key, ...)
  local localized_msg = t_func(message_key) or message_key
  local formatted_msg = string.format(localized_msg, ...)
  wezterm.log_info("🪲 " .. formatted_msg)
end

M.log = function(wezterm, t_func, module, message_key, ...)
  if M.DEBUG_CONFIG[module] then
    local localized_msg = t_func(message_key) or message_key
    local formatted_msg = string.format(localized_msg, ...)
    wezterm.log_info("🪲 [" .. module .. "] " .. formatted_msg)
  end
end

-- Функция для отладки таблиц
M.log_table = function(wezterm, module, table_name, tbl)
  if M.DEBUG_CONFIG[module] then
    local table_str = table_to_string(tbl)
    wezterm.log_info("🪲 [" .. module .. "] TABLE " .. table_name .. ":\n" .. table_str)
  end
end

-- Функция для отладки событий
M.log_event = function(wezterm, module, event_name, ...)
  if M.DEBUG_CONFIG[module] then
    local args = {...}
    local args_str = ""
    for i, arg in ipairs(args) do
      if type(arg) == "table" then
        args_str = args_str .. "arg" .. i .. "=" .. table_to_string(arg, 0, 2) .. " "
      else
        args_str = args_str .. "arg" .. i .. "=" .. tostring(arg) .. " "
      end
    end
    wezterm.log_info("🪲 [" .. module .. "] EVENT " .. event_name .. " " .. args_str)
  end
end

-- Включить отладку для модуля
M.enable_debug = function(wezterm, t_func, module)
  M.DEBUG_CONFIG[module] = true
  local msg = t_func("debug_enabled_for_module")
  wezterm.log_info("⚙️ " .. string.format(msg, module))
end

-- Выключить отладку для модуля  
M.disable_debug = function(wezterm, t_func, module)
  M.DEBUG_CONFIG[module] = false
  local msg = t_func("debug_disabled_for_module")
  wezterm.log_info("⚙️ " .. string.format(msg, module))
end

-- Включить отладку для всех модулей
M.enable_all = function(wezterm, t_func)
  for module, _ in pairs(M.DEBUG_CONFIG) do
    M.DEBUG_CONFIG[module] = true
  end
  local msg = t_func("debug_enabled_all")
  wezterm.log_info("⚙️ " .. msg)
end

-- Выключить отладку для всех модулей
M.disable_all = function(wezterm, t_func)
  for module, _ in pairs(M.DEBUG_CONFIG) do
    M.DEBUG_CONFIG[module] = false
  end
  local msg = t_func("debug_disabled_all")
  wezterm.log_info("⚙️ " .. msg)
end

-- Функция для запуска WezTerm с детальным логированием
M.enable_verbose_logging = function(wezterm)
  wezterm.log_info("⚙️ Для детального логирования запустите WezTerm с:")
  wezterm.log_info("⚙️ WEZTERM_LOG=info wezterm")
end

return M
