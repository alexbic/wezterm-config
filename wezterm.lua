-- cat > ~/.config/wezterm/wezterm.lua << 'EOF'
--
-- ОПИСАНИЕ: Основной файл конфигурации WezTerm
-- Это главный файл, который загружается при запуске WezTerm.
-- Он импортирует и инициализирует все остальные модули конфигурации.
-- 
-- ЗАВИСИМОСТИ: Этот файл загружает все остальные модули конфигурации.

local wezterm = require('wezterm')
local Config = require('config')
local locale = require('config.locale') -- добавить после require('wezterm') и require('config')

-- ВАЖНО: Загружаем настройки окружения В САМОМ НАЧАЛЕ
local environment = require('config.environment')

-- Принудительно устанавливаем переменные окружения в процессе
for key, value in pairs(environment.set_environment_variables) do
  if key ~= "PATH" then -- PATH обрабатывается отдельно
    wezterm.log_info(locale.t("set_env_var") .. ": " .. key .. " = " .. tostring(value))
  end
end

-- Настраиваем все события ПОСЛЕ установки переменных окружения
require('events.right-status').setup()
require('events.tab-title').setup()
require('events.new-tab-button').setup()
-- Убрали require('events.key-table-debug').setup() - больше не нужен

-- Подключаем модуль resurrect
require('config.resurrect')

-- Применяем конфигурацию
return Config:init()
            :append(require('config.general'))
            :append(require('config.fonts'))
            :append(require('config.appearance'))
            :append(require('config.launch'))
            :append(require('config.bindings'))
            :append(environment)
            .options
