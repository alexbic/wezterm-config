-- cat > ~/.config/wezterm/utils/debug.lua << 'EOF'
--
-- ОПИСАНИЕ: Самодостаточная система управляемого отладочного логирования
-- Позволяет включать/выключать отладочные сообщения по модулям
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
  global = true,            -- общая отладка
}

-- Простое логирование с поддержкой таблицы локализации
M.log = function(wezterm, t_table, module, message_key, ...)
  if M.DEBUG_CONFIG[module] then
    local colors = require("config.environment.colors")
    local icons = require("config.environment.icons")
    local env_utils = require("utils.environment")
    local localized_msg = (t_table and t_table[message_key]) or message_key
    local formatted_msg = string.format(localized_msg, ...)
    local icon = icons.t[module] or "🔧"
    local color_code = env_utils.get_ansi_color(colors, module)
    local colored_prefix = "27[38;5;" .. color_code .. "m" .. icon .. " [" .. module .. "]27[0m"    wezterm.log_info(colored_prefix .. " " .. formatted_msg)
  end
end
-- Выключить отладку для модуля  
M.disable_debug = function(wezterm, t_table, module)
  M.DEBUG_CONFIG[module] = false
  local msg = (t_table and t_table["debug_disabled_for_module"]) or "Debug disabled for module: %s"
  wezterm.log_info("⚙ " .. string.format(msg, module))
end

-- Включить отладку для всех модулей
M.enable_all = function(wezterm, t_table)
  for module, _ in pairs(M.DEBUG_CONFIG) do
    M.DEBUG_CONFIG[module] = true
  end
  local msg = (t_table and t_table["debug_all_enabled"]) or "All debug modules enabled"
  wezterm.log_info("⚙ " .. msg)
end

-- Выключить отладку для всех модулей
M.disable_all = function(wezterm, t_table)
  for module, _ in pairs(M.DEBUG_CONFIG) do
    M.DEBUG_CONFIG[module] = false
  end
  local msg = (t_table and t_table["debug_all_disabled"]) or "All debug modules disabled"
  wezterm.log_info("⚙ " .. msg)
end

-- Функция загрузки настроек отладки из Lua файла
M.load_debug_settings = function(wezterm)
  local settings_file = wezterm.config_dir .. "/session-state/debug-settings.lua"
  local file = io.open(settings_file, "r")
  if file then
    local content = file:read("*a")
    file:close()
    local chunk = load("return " .. content)
    if chunk then
      local ok, data = pcall(chunk)
      if ok and data and data.debug_modules then
        for module, value in pairs(data.debug_modules) do
          if M.DEBUG_CONFIG[module] ~= nil then
            M.DEBUG_CONFIG[module] = value
          end
        end
      end
    end
  end
end

-- Функция сохранения настроек отладки в Lua файл
M.save_debug_settings = function(wezterm)
  if not wezterm then
    wezterm = require('wezterm')
  end
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
