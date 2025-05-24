-- cat > ~/.config/wezterm/utils/environment.lua << 'EOF'
-- ОПИСАНИЕ: Утилиты для работы с окружением WezTerm (пути, локаль, переменные и т.д.)

local M = {}

-- Пример: функция для проверки существования директории
-- function M.dir_exists(path)
--   local ok, err, code = os.rename(path, path)
--   if not ok then
--     if code == 13 then
--       return true -- Permission denied, but exists
--     end
--     return false
--   end
--   return true
-- end

-- Пример: функция для получения переменной окружения
-- function M.getenv(var)
--   return os.getenv(var)
-- end

return M
