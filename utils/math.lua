-- cat > ~/.config/wezterm/utils/math.lua << 'EOF'
--
-- ОПИСАНИЕ: Математические утилиты для WezTerm
-- Этот модуль содержит полезные математические функции,
-- такие как ограничение значений (clamp) и округление.
-- ПОЛНОСТЬЮ САМОДОСТАТОЧНЫЙ МОДУЛЬ - все зависимости передаются как параметры.
--
-- ЗАВИСИМОСТИ: НЕТ

local _math = math

_math.clamp = function(x, min, max)
   return x < min and min or (x > max and max or x)
end

_math.round = function(x, increment)
   if increment then
      return _math.round(x / increment) * increment
   end
   return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

-- Функция безопасного деления (принимает функцию перевода как параметр)
function _math.safe_divide(a, b, t_func)
   if b == 0 then
      local error_msg = "division_by_zero"
      if t_func then
         error_msg = t_func("division_by_zero")
      end
      error(error_msg)
   end
   return a / b
end

return _math
