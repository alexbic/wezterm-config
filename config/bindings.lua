local wezterm = require('wezterm')
local platform = require('utils.platform')()
local act = wezterm.action

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
local leader = { key = 'a', mods = 'ALT', timeout_milliseconds = 1000 }

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
    { key = '0', mods = 'CTRL', action = act.EmitEvent('cycle-opacity-forward') },         -- Ctrl+0: вперед
    { key = '9', mods = 'CTRL', action = act.EmitEvent('cycle-opacity-backward') },        -- Ctrl+9: назад
    
    -- Переключение видимости панели закладок
    { key = 'h', mods = 'SHIFT|SUPER', action = act.EmitEvent('toggle-tab-bar') }, -- Command (⌘)+Shift+H на macOS
    
    -- Горячие клавиши для смены фона
    { key = 'b', mods = 'SHIFT|SUPER', action = act.EmitEvent('change-background') }, -- Command (⌘)+Shift+B 
   
    -- Активаторы для key_tables (таблиц клавиш)
    { key = 'p', mods = 'LEADER', action = act.ActivateKeyTable({
        name = 'pane_control',
        one_shot = false,
        timeout_milliseconds = 30000,  -- Уменьшаем таймаут до 30 секунд
    })},
    
    { key = 'f', mods = 'LEADER', action = act.ActivateKeyTable({
        name = 'font_control',
        one_shot = false,
        timeout_milliseconds = 30000,  -- Уменьшаем таймаут до 30 секунд
    })},


    -- Копирование/Вставка
    { key = 'c', mods = mod.SUPER, action = act.CopyTo('Clipboard') },       -- Command (⌘)+C
    { key = 'v', mods = mod.SUPER, action = act.PasteFrom('Clipboard') },    -- Command (⌘)+V
    
    -- Управление вкладками --
    -- Создание/Закрытие вкладок
    { key = 't', mods = mod.SUPER, action = act.SpawnTab('DefaultDomain') },           -- Command (⌘)+T: новая вкладка
    { key = 'w', mods = mod.SUPER_REV, action = act.CloseCurrentTab({ confirm = false }) }, -- Command (⌘)+Control+W: закрыть вкладку
    
    -- Навигация между вкладками
    { key = 'LeftArrow', mods = mod.SUPER, action = act.ActivateTabRelative(-1) },    -- Command (⌘)+← предыдущая вкладка
    { key = 'RightArrow', mods = mod.SUPER, action = act.ActivateTabRelative(1) },    -- Command (⌘)+→ следующая вкладка
    { key = 'LeftArrow', mods = mod.SUPER_REV, action = act.MoveTabRelative(-1) },    -- Command (⌘)+Control+← переместить влево
    { key = 'RightArrow', mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },    -- Command (⌘)+Control+→ переместить вправо
    
    -- Управление окнами --
    -- Создание нового окна
    { key = 'n', mods = mod.SUPER, action = act.SpawnWindow },  -- Command (⌘)+N: новое окно
    
    -- Переименование вкладки
    { key = 'R', mods = 'CTRL|SHIFT', action = act.PromptInputLine({  -- Control (⌘)+Shift+R
        description = 'Enter new name for tab',
        action = wezterm.action_callback(function(window, pane, line)
            -- line будет nil, если нажали escape
            -- Пустая строка, если просто нажали enter
            -- Или текст, который ввели
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
}

-- Все остальные настройки
return {
    disable_default_key_bindings = true,      -- Отключаем стандартные привязки клавиш
    disable_default_mouse_bindings = true,    -- Отключаем стандартные привязки мыши
    leader = leader,                          -- Используем Alt+A как лидер-клавишу
    keys = keys,
    key_tables = {
        -- Таблица для управления панелями (Alt+A, затем p)
        pane_control = {
            -- Разделение панелей
            { key = '-', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) }, -- Горизонтальное разделение
            { key = '_', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },   -- Вертикальное разделение
            { key = 'x', action = act.CloseCurrentPane({ confirm = true }) },              -- Закрыть панель
            { key = 'z', action = act.TogglePaneZoomState },                               -- Увеличить/уменьшить панель
            
            -- Навигация между панелями (стрелки)
            { key = 'LeftArrow', action = act.ActivatePaneDirection('Left') },    -- Панель слева
            { key = 'DownArrow', action = act.ActivatePaneDirection('Down') },    -- Панель снизу
            { key = 'UpArrow', action = act.ActivatePaneDirection('Up') },        -- Панель сверху
            { key = 'RightArrow', action = act.ActivatePaneDirection('Right') },  -- Панель справа
            
            -- Изменение размера панелей (Shift+стрелки)
            { key = 'LeftArrow', mods = 'SHIFT', action = act.AdjustPaneSize({ 'Left', 1 }) },   -- Уменьшить ширину
            { key = 'DownArrow', mods = 'SHIFT', action = act.AdjustPaneSize({ 'Down', 1 }) },   -- Увеличить высоту
            { key = 'UpArrow', mods = 'SHIFT', action = act.AdjustPaneSize({ 'Up', 1 }) },       -- Уменьшить высоту
            { key = 'RightArrow', mods = 'SHIFT', action = act.AdjustPaneSize({ 'Right', 1 }) }, -- Увеличить ширину
            
            -- Выход из режима - упрощенные опции выхода без колбэков
            { key = 'Escape', action = act.PopKeyTable },
            { key = 'q', action = act.PopKeyTable },
            { key = 'Enter', action = act.PopKeyTable },
        },
        
        -- Отдельная таблица для управления шрифтом (Alt+A, затем f)
        font_control = {
            -- Управление шрифтом (стрелки вверх/вниз)
            { key = 'UpArrow', action = act.IncreaseFontSize },    -- Увеличить размер шрифта
            { key = 'DownArrow', action = act.DecreaseFontSize },  -- Уменьшить размер шрифта
            { key = 'r', action = act.ResetFontSize },             -- Сбросить размер шрифта
            { key = '0', action = act.ResetFontSize },             -- Сбросить размер шрифта (альтернатива)
            
            -- Выход из режима - упрощенные опции выхода без колбэков
            { key = 'Escape', action = act.PopKeyTable },
            { key = 'q', action = act.PopKeyTable },
            { key = 'Enter', action = act.PopKeyTable },
        },
    },
    
    mouse_bindings = {
        -- Перетаскивание окна с помощью мыши
        { event = { Drag = { streak = 1, button = 'Left' } }, mods = 'SUPER', action = wezterm.action.StartWindowDrag },       -- Command+левая кнопка
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
    },
}
