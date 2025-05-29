-- cat > ~/.config/wezterm/utils/safe-require.lua << 'EOF'
--
-- ОПИСАНИЕ: Утилита для безопасного импорта модулей
-- Предотвращает падение конфигурации при отсутствии модулей
-- ПОЛНОСТЬЮ САМОДОСТАТОЧНЫЙ МОДУЛЬ - wezterm передается как параметр для логирования.
--
-- ЗАВИСИМОСТИ: НЕТ

local M = {}

-- Функция для безопасного импорта модуля
M.safe_require = function(module_name, default_value, wezterm)
  local ok, module = pcall(require, module_name)
  if not ok then
    if wezterm then
      wezterm.log_warn("Failed to load module: " .. module_name)
    end
    return default_value or {}
  end
  return module
end

-- Функция для безопасного вызова функции модуля
M.safe_call = function(func, wezterm, ...)
  if type(func) ~= "function" then
    return nil
  end
  
  local ok, result = pcall(func, ...)
  if not ok then
    if wezterm then
      wezterm.log_warn("Function call failed: " .. tostring(result))
    end
    return nil
  end
  return result
end

return M
