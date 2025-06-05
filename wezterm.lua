-- cat > ~/.config/wezterm/wezterm.lua << 'EOF'
--
-- ОПИСАНИЕ: Основной файл конфигурации WezTerm
-- Это главный файл, который загружается при запуске WezTerm.
-- Он импортирует и инициализирует все остальные модули конфигурации.

local wezterm = require('wezterm')
local debug = require("utils.debug")
debug.load_debug_settings(wezterm)
local environment = require('config.environment')
local create_platform_info = require('utils.platform')
local platform = create_platform_info(wezterm.target_triple)

-- Защита от повторного логирования через файл состояния
local env_utils = require("utils.environment")
if not env_utils.config_env_loaded(wezterm) then
  if platform.is_mac then
    debug.log(wezterm, environment.locale.t, "global", "platform_info", "macOS")
  elseif platform.is_win then
    debug.log(wezterm, environment.locale.t, "global", "platform_info", "Windows")
  elseif platform.is_linux then
    debug.log(wezterm, environment.locale.t, "global", "platform_info", "Linux")
  else
    debug.log(wezterm, environment.locale.t, "global", "platform_info", "Unknown")
  end


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

  
  -- Выводим собранные переменные окружения
  for key, value in pairs(set_env) do
    if key ~= "PATH" then -- PATH обрабатываем отдельно
      debug.log(wezterm, environment.locale.t, "global", "set_env_var", key, tostring(value))
    end
  end
  debug.log(wezterm, environment.locale.t, "global", "config_loaded_info", "")
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

-- Настраиваем все события ПОСЛЕ установки переменных окружения
require('events.session-status').setup()
require('events.tab-title').setup()
require('events.new-tab-button').setup()

-- Регистрируем события appearance
local appearance_utils = require("utils.appearance")
appearance_utils.setup_window_centering(wezterm)
local appearance_events = require("config.appearance.events")

-- Тестирование системы отладки
if appearance_events and appearance_events.register then
   appearance_events.register()
end

-- Обработчик для закрытия отладочной панели
wezterm.on("close-debug-panel", function(window, pane)
  local current_tab = window:active_tab()
  local panes = current_tab:panes()
  
  -- Если есть больше одной панели, закрываем нижнюю
  if #panes > 1 then
    window:perform_action(wezterm.action.ActivatePaneDirection("Down"), window:active_pane())
    window:perform_action(wezterm.action.CloseCurrentPane({ confirm = false }), window:active_pane())
  end
end)

wezterm.on("clear-saved-mode", function(window, pane)
  local session_status = require("events.session-status")
  session_status.clear_saved_mode()
end)

-- Обработчик для выхода из других режимов
wezterm.on("update-status-on-key-table-exit", function(window, pane)
  require("events.session-status").clear_saved_mode()
end)

-- Подключаем smart workspace switcher
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
workspace_switcher.zoxide_path = "/opt/homebrew/bin/zoxide"
require('config.resurrect')

-- Получаем настройки bindings
local bindings = require('config.bindings.global')

-- Регистрируем события workspace
require("events.workspace-events").setup()

-- Применяем конфигурацию
return ConfigClass:init()
  :append(require('config.general'))
  :append(require('config.environment.fonts'))
  :append(require('config.appearance'))
  :append(require('config.launch'))
  :append(bindings)
  .options
