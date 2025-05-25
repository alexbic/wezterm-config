-- cat > ~/.config/wezterm/wezterm.lua << 'EOF'
--
-- ОПИСАНИЕ: Основной файл конфигурации WezTerm
-- Это главный файл, который загружается при запуске WezTerm.
-- Он импортирует и инициализирует все остальные модули конфигурации.

local wezterm = require('wezterm')
local environment = require('config.environment')
local platform = require('utils.platform')()

if platform.is_mac then
  wezterm.log_info("Платформа: macOS")
elseif platform.is_win then
  wezterm.log_info("Платформа: Windows")
elseif platform.is_linux then
  wezterm.log_info("Платформа: Linux")
else
  wezterm.log_error("Неизвестная платформа")
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

print("Конфигурация загружена")

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
    wezterm.log_info("Установка переменной окружения: " .. key .. " = " .. tostring(value))
  end
end

-- Настраиваем все события ПОСЛЕ установки переменных окружения
require('events.right-status')()         -- вызов функции setup
require('events.tab-title').setup()      -- если там экспортируется таблица с функцией setup
require('events.new-tab-button').setup() -- если там экспортируется таблица с функцией setup

-- Регистрируем события appearance
local appearance_events = require("config.appearance.events")
if appearance_events and appearance_events.register then
   appearance_events.register()
end

-- Добавляем отладочное логирование событий
wezterm.on("clear-saved-mode", function(window, pane)
  wezterm.log_info("🔥 ГЛАВНОЕ СОБЫТИЕ: clear-saved-mode получено!")
  local session_status = require("events.session-status")
  session_status.clear_saved_mode()
end)

wezterm.on("update-status-on-key-table-exit", function(window, pane)
  wezterm.log_info("🔥 ГЛАВНОЕ СОБЫТИЕ: update-status-on-key-table-exit получено!")
  local session_status = require("events.session-status")
  session_status.clear_saved_mode()
end)

-- Подключаем модуль resurrect
require('config.resurrect')

-- Подключаем workspace switcher
require("config.workspace-switcher")

-- Регистрируем события workspace
require("events.workspace-events")()
-- Получаем настройки bindings
local bindings = require('config.bindings.global')

-- Применяем конфигурацию
return ConfigClass:init()
  :append(require('config.general'))
  :append(require('config.environment.fonts'))
  :append(require('config.appearance'))
  :append(require('config.launch'))
  :append(bindings)  -- Используем bindings напрямую, а не config.bindings
  .options
