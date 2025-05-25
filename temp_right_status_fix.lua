-- Функция для получения локализованных строк
local function get_localized_strings(lang)
  local environment = require('config.environment')
  local l = environment.locale.get_language_table(lang)
  return {
    days = l.days or {},
    months = l.months or {},
  }
end
