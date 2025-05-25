-- cat > ~/.config/wezterm/wezterm.lua << 'EOF'
--
-- ОПИСАНИЕ: Основной файл конфигурации WezTerm
-- Это главный файл, который загружается при запуске WezTerm.
-- Он импортирует и инициализирует все остальные модули конфигурации.

local wezterm = require('wezterm')
local environment = require('config.environment')
local platform = require('utils.platform')()

if platform.is_mac then
  wezterm.log_info(environment.locale.t("platform") .. ": " .. environment.locale.t("macos"))
elseif platform.is_win then
  wezterm.log_info(environment.locale.t("platform") .. ": " .. environment.locale.t("windows"))
elseif platform.is_linux then
  wezterm.log_info(environment.locale.t("platform") .. ": " .. environment.locale.t("linux"))
else
  wezterm.log_error(environment.locale.t("unknown_platform"))
end

---@class Config
---@field options table
local ConfigClass = {}

function ConfigClass:init()
   local o = {}
   self = setmetatable(o, { __index = ConfigClass })
   self.options = {}
   return o
end

function ConfigClass:append(new_options)
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

print(environment.locale.t("config_loaded"))

-- Собираем все переменные окружения из подмодулей
local set_env = {}

for _, mod in pairs({
  environment.locale and environment.locale.settings,
  environment.colors,
  environment.terminal,
  environment.apps,
  environment.devtools,
}) do
  if type(mod) == "table" then
    for k, v in pairs(mod) do
      if type(v) == "string" then
        set_env[k] = v
      end
    end
  end
end

-- Принудительно устанавливаем переменные окружения в процессе
for key, value in pairs(set_env) do
  if key ~= "PATH" then -- PATH обрабатывается отдельно
    wezterm.log_info(environment.locale.t("set_env_var") .. ": " .. key .. " = " .. tostring(value))
    -- os.setenv(key, tostring(value)) -- если нужно реально установить переменную
  end
end

-- Настраиваем все события ПОСЛЕ установки переменных окружения
require('events.right-status')()         -- вызов функции setup
require('events.tab-title').setup()      -- если там экспортируется таблица с функцией setup
require('events.new-tab-button').setup() -- если там экспортируется таблица с функцией setup

-- Подключаем модуль resurrect
require('config.resurrect')

-- Применяем конфигурацию
return ConfigClass:init()
  :append(require('config.general'))
  :append(require('config.environment.fonts'))
  :append(require('config.appearance'))
  :append(require('config.launch'))
  :append(require('config.bindings'))
  .options
