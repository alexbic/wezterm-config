-- cat > ~/.config/wezterm/utils/debug.lua << 'EOF'
--
-- ОПИСАНИЕ: Улучшенная система управляемого отладочного логирования
-- Позволяет включать/выключать отладочные сообщения, локализовать их и отлаживать таблицы
-- ПОЛНОСТЬЮ САМОДОСТАТОЧНЫЙ МОДУЛЬ - все зависимости передаются как параметры.
--
local colors = require("config.environment.colors")
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

-- Функция отладочного логирования с локализацией и централизованными иконками
M.log_system = function(wezterm, t_func, message_key, ...)
  local localized_msg = t_func(message_key) or message_key
  local formatted_msg = string.format(localized_msg, ...)
  
  -- Получаем иконку и цвет из централизованной системы
  local ok_icons, icons = pcall(require, "config.environment.icons")
  local ok_env, env_utils = pcall(require, "utils.environment")
  
  if ok_icons and ok_env then
    local icon = env_utils.get_icon(icons, "system")
    local color = env_utils.get_color(colors, "system")
    wezterm.log_info(wezterm.format({
      { Foreground = { Color = color } },
      { Text = icon .. " " .. formatted_msg }
    }))
  else
    wezterm.log_info("⚙ " .. formatted_msg)
  end
end

M.log = function(wezterm, t_func, module, message_key, ...)
  if M.DEBUG_CONFIG[module] then
    local localized_msg = t_func(message_key) or message_key
    local formatted_msg = string.format(localized_msg, ...)
    
    -- Простой вывод без иконок для обычных отладочных сообщений
    wezterm.log_info("[" .. module .. "] " .. formatted_msg)
  end
end
-- Функция для отладки таблиц
M.log_table = function(wezterm, module, table_name, tbl)
  if M.DEBUG_CONFIG[module] then
    local table_str = table_to_string(tbl)
    
    -- Получаем иконку и цвет из централизованной системы
    local ok_icons, icons = pcall(require, "config.environment.icons")
    local ok_env, env_utils = pcall(require, "utils.environment")
    
    if ok_icons and ok_env then
      -- Для обычных отладочных сообщений НЕ используем иконки
      wezterm.log_info("[" .. module .. "] " .. formatted_msg)      local icon = env_utils.get_icon(icons, category)
      local color = env_utils.get_color(colors, category)
      wezterm.log_info(wezterm.format({
        { Foreground = { Color = color } },
        { Text = icon .. " [" .. module .. "] TABLE " .. table_name .. ":\n" .. table_str }
      }))
    else
      wezterm.log_info("⊠ [" .. module .. "] TABLE " .. table_name .. ":\n" .. table_str)
    end
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
    
    -- Получаем иконку и цвет из централизованной системы
    local ok_icons, icons = pcall(require, "config.environment.icons")
    local ok_env, env_utils = pcall(require, "utils.environment")
    
    if ok_icons and ok_env then
      -- Для обычных отладочных сообщений НЕ используем иконки
      wezterm.log_info("[" .. module .. "] " .. formatted_msg)      local icon = env_utils.get_icon(icons, category)
      local color = env_utils.get_color(colors, category)
      wezterm.log_info(wezterm.format({
        { Foreground = { Color = color } },
        { Text = icon .. " [" .. module .. "] EVENT " .. event_name .. " " .. args_str }
      }))
    else
      wezterm.log_info("⊠ [" .. module .. "] EVENT " .. event_name .. " " .. args_str)
    end
  end
end

-- Включить отладку для модуля
M.enable_debug = function(wezterm, t_func, module)
  M.DEBUG_CONFIG[module] = true
  local msg = t_func("debug_enabled_for_module")
  
  -- Получаем иконку и цвет из централизованной системы
  local ok_icons, icons = pcall(require, "config.environment.icons")
  local ok_env, env_utils = pcall(require, "utils.environment")
  
  if ok_icons and ok_env then
    local icon = env_utils.get_icon(icons, "system")
    local color = env_utils.get_color(colors, "system")
    wezterm.log_info(wezterm.format({
      { Foreground = { Color = color } },
      { Text = icon .. " " .. string.format(msg, module) }
    }))
  else
    wezterm.log_info("⚙ " .. string.format(msg, module))
  end
end

-- Выключить отладку для модуля  
M.disable_debug = function(wezterm, t_func, module)
  M.DEBUG_CONFIG[module] = false
  local msg = t_func("debug_disabled_for_module")
  
  -- Получаем иконку и цвет из централизованной системы
  local ok_icons, icons = pcall(require, "config.environment.icons")
  local ok_env, env_utils = pcall(require, "utils.environment")
  
  if ok_icons and ok_env then
    local icon = env_utils.get_icon(icons, "system")
    local color = env_utils.get_color(colors, "system")
    wezterm.log_info(wezterm.format({
      { Foreground = { Color = color } },
      { Text = icon .. " " .. string.format(msg, module) }
    }))
  else
    wezterm.log_info("⚙ " .. string.format(msg, module))
  end
end

-- Включить отладку для всех модулей
M.enable_all = function(wezterm, t_func)
  for module, _ in pairs(M.DEBUG_CONFIG) do
    M.DEBUG_CONFIG[module] = true
  end
  local msg = t_func("debug_all_enabled")
  
  -- Получаем иконку и цвет из централизованной системы
  local ok_icons, icons = pcall(require, "config.environment.icons")
  local ok_env, env_utils = pcall(require, "utils.environment")
  
  if ok_icons and ok_env then
    local icon = env_utils.get_icon(icons, "system")
    local color = env_utils.get_color(colors, "system")
    wezterm.log_info(wezterm.format({
      { Foreground = { Color = color } },
      { Text = icon .. " " .. msg }
    }))
  else
    wezterm.log_info("⚙ " .. msg)
  end
end

-- Выключить отладку для всех модулей
M.disable_all = function(wezterm, t_func)
  for module, _ in pairs(M.DEBUG_CONFIG) do
    M.DEBUG_CONFIG[module] = false
  end
  local msg = t_func("debug_all_disabled")
  
  -- Получаем иконку и цвет из централизованной системы
  local ok_icons, icons = pcall(require, "config.environment.icons")
  local ok_env, env_utils = pcall(require, "utils.environment")
  
  if ok_icons and ok_env then
    local icon = env_utils.get_icon(icons, "system")
    local color = env_utils.get_color(colors, "system")
    wezterm.log_info(wezterm.format({
      { Foreground = { Color = color } },
      { Text = icon .. " " .. msg }
    }))
  else
    wezterm.log_info("⚙ " .. msg)
  end
end

-- Функция для запуска WezTerm с детальным логированием
M.enable_verbose_logging = function(wezterm)
  wezterm.log_info("⚙ Для детального логирования запустите WezTerm с:")
  wezterm.log_info("⚙ WEZTERM_LOG=info wezterm")
end

-- Функция загрузки настроек отладки из Lua файла
M.load_debug_settings = function()
  local wezterm = require("wezterm")
  local settings_file = wezterm.config_dir .. "/session-state/debug-settings.lua"
  local file = io.open(settings_file, "r")
  if file then
    local content = file:read("*a")
    file:close()
    local chunk = load("return " .. content)
    if chunk then
      local ok, data = pcall(chunk)
      if ok and data and data.debug_modules then
        M.DEBUG_CONFIG.appearance = data.debug_modules.appearance or false
        M.DEBUG_CONFIG.global = data.debug_modules.global or false
        M.DEBUG_CONFIG.session_status = data.debug_modules.session_status or false
        M.DEBUG_CONFIG.workspace = data.debug_modules.workspace or false
        M.DEBUG_CONFIG.bindings = data.debug_modules.bindings or false
        M.DEBUG_CONFIG.resurrect = data.debug_modules.resurrect or false
      end
    end
  end
end

-- Функция сохранения настроек отладки в Lua файл
M.save_debug_settings = function()
  local wezterm = require("wezterm")
  local settings_file = wezterm.config_dir .. "/session-state/debug-settings.lua"
  local lua_content = string.format([[{
  debug_modules = {
    appearance = %s,
    global = %s,
    session_status = %s,
    workspace = %s,
    bindings = %s,
    resurrect = %s
  },
  last_updated = "%s"
}]], 
    M.DEBUG_CONFIG.appearance and "true" or "false",
    M.DEBUG_CONFIG.global and "true" or "false",
    M.DEBUG_CONFIG.session_status and "true" or "false",
    M.DEBUG_CONFIG.workspace and "true" or "false",
    M.DEBUG_CONFIG.bindings and "true" or "false",
    M.DEBUG_CONFIG.resurrect and "true" or "false",
    os.date("%Y-%m-%d %H:%M:%S"))
  
  local file = io.open(settings_file, "w")
  if file then
    file:write(lua_content)
    file:close()
  end
end

return M
