local wezterm = require('wezterm')
local platform = require('utils.platform')()
local act = wezterm.action

local mod = {}

if platform.is_mac then
   mod.SUPER = 'SUPER'  -- Command (⌘) на macOS
   mod.SUPER_REV = 'SUPER|CTRL'  -- Command+Control на macOS
elseif platform.is_win then
    mod.SUPER = 'ALT'  -- Используем ALT вместо WIN на Windows
    mod.SUPER_REV = 'ALT|CTRL'
else
    mod.SUPER = 'ALT'  -- Используем ALT на Linux
    mod.SUPER_REV = 'ALT|CTRL'
end

-- Устанавливаем лидер-клавишу Alt+A для специальных функций
local leader = { key = 'a', mods = 'ALT', timeout_milliseconds = 1000 }

-- Переменная для хранения активного режима, даже если ключевая таблица будет сброшена
local active_mode = ""

-- Функция для отображения активной таблицы клавиш 
wezterm.on('update-right-status', function(window, pane)
    local name = window:active_key_table()
    
    -- Если активна ключевая таблица, обновляем нашу переменную
    if name then
        active_mode = 'MODE: ' .. name
    end
    
    -- Если статусная строка пустая, но у нас есть активный режим - отображаем его
    local current_status = window:get_right_status()
    if (current_status == nil or current_status == '') and active_mode ~= '' then
        window:set_right_status(active_mode)
    end
    
    -- Если активная ключевая таблица изменилась, обновляем статус
    if name then
        local new_status = 'MODE: ' .. name
        if current_status ~= new_status then
            window:set_right_status(new_status)
        end
    end
end)

-- Событие при выходе из режима - сбрасываем активный режим
wezterm.on('user-var-changed', function(window, pane, name, value)
    if name == "active_mode" then
        active_mode = value
        window:set_right_status(value)
    end
end)

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
    
    -- Различные уровни прозрачности (Alt+A, затем цифра)
    { key = '0', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.00') },  -- Полная прозрачность
    { key = '1', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.05') },  -- 5% непрозрачности
    { key = '2', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.15') },  -- 15% непрозрачности
    { key = '3', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.25') },  -- 25% непрозрачности
    { key = '4', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.4') },   -- 40% непрозрачности
    { key = '5', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.6') },   -- 60% непрозрачности
    { key = '6', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.8') },   -- 80% непрозрачности
    { key = '9', mods = 'LEADER', action = act.EmitEvent('reset-to-defaults') }, -- Сброс к настройкам по умолчанию
    { key = 'b', mods = 'LEADER', action = act.EmitEvent('change-background') }, -- Смена фона
    
    -- Черный фон с хорошо видимой картинкой (Command+0 на macOS)
    { key = '0', mods = mod.SUPER, action = act.EmitEvent('set-black-background') },
    
    -- Активаторы для key_tables (таблиц клавиш)
    { key = 'p', mods = 'LEADER', action = wezterm.action_callback(function(window, pane)
        -- Активируем режим панелей
        window:perform_action(
            act.ActivateKeyTable({
                name = 'pane_control',
                one_shot = false,
                timeout_milliseconds = 0,
            }), 
            pane
        )
        -- Устанавливаем пользовательскую переменную для режима
        window:set_user_var("active_mode", "MODE: pane_control")
    end)},
    
    { key = 'f', mods = 'LEADER', action = wezterm.action_callback(function(window, pane)
        -- Активируем режим управления шрифтом
        window:perform_action(
            act.ActivateKeyTable({
                name = 'font_control',
                one_shot = false,
                timeout_milliseconds = 0,
            }), 
            pane
        )
        -- Устанавливаем пользовательскую переменную для режима
        window:set_user_var("active_mode", "MODE: font_control")
    end)},

    -- Горячие клавиши для смены фона
    { key = 'b', mods = 'CMD|SHIFT', action = act.EmitEvent('change-background') }, -- Shift+Command+B
    
    -- Копирование/Вставка
    { key = 'c', mods = mod.SUPER, action = act.CopyTo('Clipboard') },       -- Command+C
    { key = 'v', mods = mod.SUPER, action = act.PasteFrom('Clipboard') },    -- Command+V
    
    -- Управление вкладками --
    -- Создание/Закрытие вкладок
    { key = 't', mods = mod.SUPER, action = act.SpawnTab('DefaultDomain') },           -- Command+T: новая вкладка
    { key = 'w', mods = mod.SUPER_REV, action = act.CloseCurrentTab({ confirm = false }) }, -- Command+Control+W: закрыть вкладку
    
    -- Навигация между вкладками
    { key = 'LeftArrow', mods = mod.SUPER, action = act.ActivateTabRelative(-1) },    -- Command+← предыдущая вкладка
    { key = 'RightArrow', mods = mod.SUPER, action = act.ActivateTabRelative(1) },    -- Command+→ следующая вкладка
    { key = 'LeftArrow', mods = mod.SUPER_REV, action = act.MoveTabRelative(-1) },    -- Command+Control+← переместить влево
    { key = 'RightArrow', mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },    -- Command+Control+→ переместить вправо
    
    -- Управление окнами --
    -- Создание нового окна
    { key = 'n', mods = mod.SUPER, action = act.SpawnWindow },  -- Command+N: новое окно
    
    -- Переименование вкладки
    { key = 'R', mods = 'CTRL|SHIFT', action = act.PromptInputLine({  -- Control+Shift+R
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
}

-- Все остальные настройки
return {
    debug_key_events = true,      -- Включаем отладку событий клавиш
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
            
            -- Добавляем также навигацию клавишами h,j,k,l для vim-пользователей
            { key = 'h', action = act.ActivatePaneDirection('Left') },
            { key = 'j', action = act.ActivatePaneDirection('Down') },
            { key = 'k', action = act.ActivatePaneDirection('Up') },
            { key = 'l', action = act.ActivatePaneDirection('Right') },
            
            -- Изменение размера панелей (Shift+стрелки)
            { key = 'LeftArrow', mods = 'SHIFT', action = act.AdjustPaneSize({ 'Left', 1 }) },   -- Уменьшить ширину
            { key = 'DownArrow', mods = 'SHIFT', action = act.AdjustPaneSize({ 'Down', 1 }) },   -- Увеличить высоту
            { key = 'UpArrow', mods = 'SHIFT', action = act.AdjustPaneSize({ 'Up', 1 }) },       -- Уменьшить высоту
            { key = 'RightArrow', mods = 'SHIFT', action = act.AdjustPaneSize({ 'Right', 1 }) }, -- Увеличить ширину
            
            -- Выход из режима
            { key = 'Escape', action = wezterm.action_callback(function(window, pane)
                window:perform_action(act.PopKeyTable(), pane)
                window:set_user_var("active_mode", "")
            end) },
            { key = 'q', action = wezterm.action_callback(function(window, pane)
                window:perform_action(act.PopKeyTable(), pane)
                window:set_user_var("active_mode", "")
            end) },
        },
        
        -- Отдельная таблица для управления шрифтом (Alt+A, затем f)
        font_control = {
            -- Управление шрифтом (стрелки вверх/вниз)
            { key = 'UpArrow', action = act.IncreaseFontSize },    -- Увеличить размер шрифта
            { key = 'DownArrow', action = act.DecreaseFontSize },  -- Уменьшить размер шрифта
            { key = 'r', action = act.ResetFontSize },             -- Сбросить размер шрифта
            { key = '0', action = act.ResetFontSize },             -- Сбросить размер шрифта (альтернатива)
            
            -- Выход из режима
            { key = 'Escape', action = wezterm.action_callback(function(window, pane)
                window:perform_action(act.PopKeyTable(), pane)
                window:set_user_var("active_mode", "")
            end) },
            { key = 'q', action = wezterm.action_callback(function(window, pane)
                window:perform_action(act.PopKeyTable(), pane)
                window:set_user_var("active_mode", "")
            end) },
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
