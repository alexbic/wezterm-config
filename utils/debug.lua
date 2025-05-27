-- cat > ~/.config/wezterm/utils/debug.lua << 'EOF'
--
-- ОПИСАНИЕ: Система управляемого отладочного логирования
-- Позволяет включать/выключать отладочные сообщения и локализовать их
--
-- ЗАВИСИМОСТИ: config.environment.locale

local wezterm = require('wezterm')
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

-- Функция отладочного логирования с локализацией
M.log = function(module, message_key, ...)
  if M.DEBUG_CONFIG[module] then
    local environment = require('config.environment')
    local localized_msg = environment.locale.t(message_key) or message_key
    local formatted_msg = string.format(localized_msg, ...)
    wezterm.log_info("🐛 [" .. module .. "] " .. formatted_msg)
  end
end

-- Включить отладку для модуля
M.enable_debug = function(module)
  M.DEBUG_CONFIG[module] = true
  local environment = require('config.environment')
  local msg = environment.locale.t("debug_enabled_for_module")
  wezterm.log_info("🔧 " .. string.format(msg, module))
end

-- Выключить отладку для модуля  
M.disable_debug = function(module)
  M.DEBUG_CONFIG[module] = false
  local environment = require('config.environment')
  local msg = environment.locale.t("debug_disabled_for_module")
  wezterm.log_info("🔧 " .. string.format(msg, module))
end

-- Включить отладку для всех модулей
M.enable_all = function()
  for module, _ in pairs(M.DEBUG_CONFIG) do
    M.DEBUG_CONFIG[module] = true
  end
  local environment = require('config.environment')
  local msg = environment.locale.t("debug_enabled_all")
  wezterm.log_info("🔧 " .. msg)
end

-- Выключить отладку для всех модулей
M.disable_all = function()
  for module, _ in pairs(M.DEBUG_CONFIG) do
    M.DEBUG_CONFIG[module] = false
  end
  local environment = require('config.environment')
  local msg = environment.locale.t("debug_disabled_all")
  wezterm.log_info("🔧 " .. msg)
end

return M
-- EOF
