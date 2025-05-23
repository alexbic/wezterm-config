-- cat > ~/.config/wezterm/utils/math.lua << 'EOF'
--
-- ОПИСАНИЕ: Математические утилиты для WezTerm
-- Этот модуль содержит полезные математические функции,
-- такие как ограничение значений (clamp) и округление.
--
-- ЗАВИСИМОСТИ: Используется в различных модулях для математических операций.

local _math = math
local locale = require('config.locale')

_math.clamp = function(x, min, max)
   return x < min and min or (x > max and max or x)
end

_math.round = function(x, increment)
   if increment then
      return _math.round(x / increment) * increment
   end
   return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

function _math.safe_divide(a, b)
   if b == 0 then
      error(locale.t("division_by_zero"))
   end
   return a / b
end

return _math
