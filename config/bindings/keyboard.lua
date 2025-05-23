-- cat > ~/.config/wezterm/config/keyboard/bindings.lua << 'EOF'
--
-- ОПИСАНИЕ: Настройки привязок клавиш
-- Определяет сочетания клавиш для различных действий: управление вкладками,
-- окнами, копирование/вставка, поиск, изменение внешнего вида.
-- Активирует модальные таблицы клавиш.
--
-- ЗАВИСИМОСТИ: utils.platform, config.keyboard.key-tables

local wezterm = require('wezterm')
local platform = require('utils.platform')()
local act = wezterm.action
local key_tables = require('config.bindings.keyboard-tables')
local locale = require('config.locale')

local mod = {}

if platform.is_mac then
  mod.SUPER = 'SUPER'  -- Command (⌘) на macOS
  mod.SUPER_REV = 'SUPER|CTRL'  -- Command (⌘) + Control на macOS
elseif platform.is_win then
   mod.SUPER = 'ALT'  -- Используем ALT вместо WIN на Windows
   mod.SUPER_REV = 'ALT|CTRL'
else
   mod.SUPER = 'ALT'  -- Используем ALT на Linux
   mod.SUPER_REV = 'ALT|CTRL'
end

-- Устанавливаем лидер-клавишу Alt+A для специальных функций
local leader = { key = 'a', mods = 'ALT', timeout_milliseconds = 750 }

-- Клавиши для основных функций
local keys = {
   -- Общие функции --
   { key = 'F1',     mods = 'NONE',        action = 'ActivateCopyMode' },
   { key = 'F2',     mods = 'NONE',        action = act.ActivateCommandPalette },
   { key = 'F3',     mods = 'NONE',        action = act.ShowLauncher },
   { key = 'F4',     mods = 'NONE',        action = act.ShowTabNavigator },
   { key = 'F11',    mods = 'NONE',        action = act.ToggleFullScreen },
   { key = 'F12',    mods = 'NONE',        action = act.ShowDebugOverlay },
   { key = 'f',      mods = mod.SUPER,     action = act.Search({ CaseInSensitiveString = '' }) },

   -- Циклическое изменение прозрачности
   { key = '0', mods = 'CTRL', action = act.EmitEvent('cycle-opacity-forward') },
   { key = '9', mods = 'CTRL', action = act.EmitEvent('cycle-opacity-backward') },
   
   -- Переключение видимости панели закладок
   { key = 'h', mods = 'SHIFT|SUPER', action = act.EmitEvent('toggle-tab-bar') },
   
   -- Горячие клавиши для смены фона
   { key = 'b', mods = 'SHIFT|SUPER', action = act.EmitEvent('change-background') },
  
   -- Активаторы для key_tables (таблиц клавиш) с принудительным обновлением статуса
   { key = 'p', mods = 'LEADER', action = act.Multiple({
       act.ActivateKeyTable({
         name = 'pane_control',
         one_shot = false,
         timeout_milliseconds = 10000,
       }),
       act.EmitEvent('force-update-status')
   })},
   
   { key = 'f', mods = 'LEADER', action = act.Multiple({
       act.ActivateKeyTable({
         name = 'font_control',
         one_shot = false,
         timeout_milliseconds = 10000,
       }),
       act.EmitEvent('force-update-status')
   })},
   
   { key = 's', mods = 'LEADER', action = act.Multiple({
       act.ActivateKeyTable({
         name = 'session_control',
         one_shot = false,
         timeout_milliseconds = 10000,
       }),
       act.EmitEvent('force-update-status')
   })},

   -- Тестовая клавиша для проверки уведомлений
   { key = 'n', mods = 'CTRL|SHIFT', action = act.EmitEvent('resurrect.test_notification') },
   
   -- Отладка анимации - принудительная остановка (для тестирования)
   { key = 'x', mods = 'CTRL|SHIFT', action = act.EmitEvent('stop-loading-debug') },

   -- Копирование/Вставка
   { key = 'c', mods = mod.SUPER, action = act.CopyTo('Clipboard') },
   { key = 'v', mods = mod.SUPER, action = act.PasteFrom('Clipboard') },
   
   -- Управление вкладками --
   { key = 't', mods = mod.SUPER, action = act.SpawnTab('DefaultDomain') },
   { key = 'w', mods = mod.SUPER, action = act.CloseCurrentTab({ confirm = false }) },
   { key = 'w', mods = mod.SUPER_REV, action = act.CloseCurrentTab({ confirm = false }) },
   
   -- Навигация между вкладками
   { key = 'LeftArrow', mods = mod.SUPER, action = act.ActivateTabRelative(-1) },
   { key = 'RightArrow', mods = mod.SUPER, action = act.ActivateTabRelative(1) },
   { key = 'LeftArrow', mods = mod.SUPER_REV, action = act.MoveTabRelative(-1) },
   { key = 'RightArrow', mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },
   
   -- Управление окнами --
   { key = 'n', mods = mod.SUPER, action = act.SpawnWindow },
   { key = 'q', mods = mod.SUPER, action = act.QuitApplication },
   
   -- Переименование вкладки
   { key = 'R', mods = 'CTRL|SHIFT', action = act.PromptInputLine({
       description = 'Enter new name for tab',
       action = wezterm.action_callback(function(window, pane, line)
           if line then
               window:active_tab():set_title(line)
           end
       end),
   })},
   
   -- Отправка специальных символов через Alt (Option)
   { key = "'", mods = 'ALT', action = act.SendString("\\") },
   { key = 'ñ', mods = 'ALT', action = act.SendString("~") },
   { key = '1', mods = 'ALT', action = act.SendString("|") },
   { key = 'º', mods = 'ALT', action = act.SendString("\\") },
   { key = '+', mods = 'ALT', action = act.SendString("]") },
   { key = '`', mods = 'ALT', action = act.SendString("[") },
   { key = 'ç', mods = 'ALT', action = act.SendString("}") },
   { key = '*', mods = 'ALT', action = act.SendString("{") },
   { key = '3', mods = 'ALT', action = act.SendString("#") },
   
   -- Создание нового workspace
   { key = "w", mods = "CTRL|SHIFT", action = act.PromptInputLine {
       description = wezterm.format {
         { Attribute = { Intensity = "Bold" } },
         { Foreground = { AnsiColor = "Fuchsia" } },
         { Text = "Введите имя для нового workspace" },
       },
       action = wezterm.action_callback(function(window, pane, line)
         if line then
           window:perform_action(
             act.SwitchToWorkspace {
               name = line,
             },
             pane
           )
         end
       end),
   }},
   {
     key = "t",
     mods = "CTRL|SHIFT",
     action = wezterm.action.SpawnTab "CurrentPaneDomain",
     description = locale.t("open_new_tab"),
   },
}

-- Экспортируем настройки клавиатуры
return {
   disable_default_key_bindings = true,
   leader = leader,
   keys = keys,
   key_tables = key_tables,
}
