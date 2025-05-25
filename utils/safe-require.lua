-- cat > ~/.config/wezterm/utils/safe-require.lua << 'EOF'
--
-- ОПИСАНИЕ: Утилита для безопасного импорта модулей
-- Предотвращает падение конфигурации при отсутствии модулей
--
-- ЗАВИСИМОСТИ: wezterm

local wezterm = require('wezterm')

local M = {}

-- Функция для безопасного импорта модуля
M.safe_require = function(module_name, default_value)
  local ok, module = pcall(require, module_name)
  if not ok then
    wezterm.log_warn("Failed to load module: " .. module_name)
    return default_value or {}
  end
  return module
end

-- Функция для безопасного вызова функции модуля
M.safe_call = function(func, ...)
  if type(func) ~= "function" then
    return nil
  end
  
  local ok, result = pcall(func, ...)
  if not ok then
    wezterm.log_warn("Function call failed: " .. tostring(result))
    return nil
  end
  return result
end

return M
