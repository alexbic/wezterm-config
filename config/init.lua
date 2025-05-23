-- cat > ~/.config/wezterm/config/init.lua << 'EOF'
--
-- ОПИСАНИЕ: Инициализатор конфигурации
-- Определяет класс Config для создания, управления и объединения параметров 
-- конфигурации из разных модулей. Предотвращает дублирование параметров.
--
-- ЗАВИСИМОСТИ: Используется во всех модулях конфигурации

local wezterm = require('wezterm')
local locale = require('config.locale')

---@class Config
---@field options table
local Config = {}

---Initialize Config
---@return Config
function Config:init()
   local o = {}
   self = setmetatable(o, { __index = Config })
   self.options = {}
   return o
end

---Append to `Config.options`
---@param new_options table new options to append
---@return Config
function Config:append(new_options)
   for k, v in pairs(new_options) do
      if self.options[k] ~= nil then
         wezterm.log_warn(
            'Duplicate config option detected: ',
            { old = self.options[k], new = new_options[k] }
            )
        else
            self.options[k] = v
        end
    end
    return self
end

print(locale.t("config_loaded"))

return Config
