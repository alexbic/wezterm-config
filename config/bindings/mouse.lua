-- cat > ~/.config/wezterm/config/mouse/bindings.lua << 'EOF'
--
-- ОПИСАНИЕ: Настройки привязок мыши
-- Определяет поведение мыши: клики, перетаскивание, выделение и прокрутка.
--
-- ЗАВИСИМОСТИ: utils.platform

local wezterm = require('wezterm')
local platform = require('utils.platform')()
local act = wezterm.action
local environment = require('config.environment')

local mod = {}
if platform.is_mac then
  mod.SUPER = 'SUPER'  -- Command (⌘) на macOS
else
  mod.SUPER = 'ALT'    -- Используем ALT на других платформах
end


return {
   -- Перетаскивание окна с помощью мыши
   { event = { Drag = { streak = 1, button = 'Left' } }, mods = mod.SUPER, action = wezterm.action.StartWindowDrag },       -- Command/Alt+левая кнопка
   { event = { Drag = { streak = 1, button = 'Left' } }, mods = 'CTRL|SHIFT', action = wezterm.action.StartWindowDrag },  -- Control+Shift+левая кнопка
   
   -- Control+клик для открытия ссылки под курсором
   { event = { Up = { streak = 1, button = 'Left' } }, mods = 'CTRL', action = act.OpenLinkAtMouseCursor },
   
   -- Движение мыши только выделяет текст, не копирует его в буфер обмена
   { event = { Down = { streak = 1, button = 'Left' } }, mods = 'NONE', action = act.SelectTextAtMouseCursor('Cell') },
   { event = { Up = { streak = 1, button = 'Left' } }, mods = 'NONE', action = act.ExtendSelectionToMouseCursor('Cell') },
   { event = { Drag = { streak = 1, button = 'Left' } }, mods = 'NONE', action = act.ExtendSelectionToMouseCursor('Cell') },
   
   -- Тройной клик левой кнопкой выделяет строку
   { event = { Down = { streak = 3, button = 'Left' } }, mods = 'NONE', action = act.SelectTextAtMouseCursor('Line') },
   { event = { Up = { streak = 3, button = 'Left' } }, mods = 'NONE', action = act.SelectTextAtMouseCursor('Line') },
   
   -- Двойной клик левой кнопкой выделяет слово
   { event = { Down = { streak = 2, button = 'Left' } }, mods = 'NONE', action = act.SelectTextAtMouseCursor('Word') },
   { event = { Up = { streak = 2, button = 'Left' } }, mods = 'NONE', action = act.SelectTextAtMouseCursor('Word') },
   
   -- Включаем колесо мыши для прокрутки экрана
   { event = { Down = { streak = 1, button = { WheelUp = 1 } } }, mods = 'NONE', action = act.ScrollByCurrentEventWheelDelta },
   { event = { Down = { streak = 1, button = { WheelDown = 1 } } }, mods = 'NONE', action = act.ScrollByCurrentEventWheelDelta },
}
