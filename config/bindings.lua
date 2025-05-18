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

-- Функция для отображения активной таблицы клавиш
wezterm.on('update-right-status', function(window, pane)
    local name = window:active_key_table()
    local status = ""
    
    if name then
        status = 'MODE: ' .. name
    end
    
    -- Устанавливаем статус только если он изменился
    local current_status = window:get_right_status()
    if current_status ~= status then
        window:set_right_status(status)
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
    
    -- Различные уровни прозрачности через лидер-клавишу
    { key = '0', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.00') },
    { key = '1', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.05') },
    { key = '2', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.15') },
    { key = '3', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.25') },
    { key = '4', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.4') },
    { key = '5', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.6') },
    { key = '6', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.8') },
    { key = '9', mods = 'LEADER', action = act.EmitEvent('reset-to-defaults') },
    { key = 'b', mods = 'LEADER', action = act.EmitEvent('change-background') },
    
    -- Активация режимов через прямые клавиши вместо LEADER
    -- Alt+P - режим управления панелями
    { key = 'p', mods = 'ALT', action = act.ActivateKeyTable {
        name = 'pane_control',
        one_shot = false,
        timeout_milliseconds = 0,
    }},
    
    -- Alt+F - режим управления шрифтом
    { key = 'f', mods = 'ALT', action = act.ActivateKeyTable {
        name = 'font_control',
        one_shot = false,
        timeout_milliseconds = 0,
    }},
    
    -- Черный фон с хорошо видимой картинкой (Command+0 на macOS)
    { key = '0', mods = mod.SUPER, action = act.EmitEvent('set-black-background') },
    
    -- Горячие клавиши для смены фона
    { key = 'b', mods = 'CMD|SHIFT', action = act.EmitEvent('change-background') },
    
    -- Копирование/Вставка
    { key = 'c', mods = mod.SUPER, action = act.CopyTo('Clipboard') },
    { key = 'v', mods = mod.SUPER, action = act.PasteFrom('Clipboard') },
    
    -- Управление вкладками --
    -- Создание/Закрытие вкладок
    { key = 't', mods = mod.SUPER, action = act.SpawnTab('DefaultDomain') },
    { key = 'w', mods = mod.SUPER_REV, action = act.CloseCurrentTab({ confirm = false }) },
    
    -- Навигация между вкладками
    { key = 'LeftArrow', mods = mod.SUPER, action = act.ActivateTabRelative(-1) },
    { key = 'RightArrow', mods = mod.SUPER, action = act.ActivateTabRelative(1) },
    { key = 'LeftArrow', mods = mod.SUPER_REV, action = act.MoveTabRelative(-1) },
    { key = 'RightArrow', mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },
    
    -- Управление окнами --
    -- Создание нового окна
    { key = 'n', mods = mod.SUPER, action = act.SpawnWindow },
    
    -- Переименование вкладки
    { key = 'R', mods = 'CTRL|SHIFT', action = act.PromptInputLine({
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
    debug_key_events = true,  -- Включаем отладку событий клавиш
    disable_default_key_bindings = true,
    disable_default_mouse_bindings = true,
    leader = leader,
    keys = keys,
    key_tables = {
        -- Таблица для управления панелями (Alt+P активирует)
        pane_control = {
            -- Разделение панелей
            { key = '-', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
            { key = '_', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
            { key = 'x', action = act.CloseCurrentPane({ confirm = true }) },
            { key = 'z', action = act.TogglePaneZoomState },
            
            -- Навигация между панелями (стрелки)
            { key = 'LeftArrow', action = act.ActivatePaneDirection('Left') },
            { key = 'DownArrow', action = act.ActivatePaneDirection('Down') },
            { key = 'UpArrow', action = act.ActivatePaneDirection('Up') },
            { key = 'RightArrow', action = act.ActivatePaneDirection('Right') },
            
            -- Добавляем также навигацию клавишами h,j,k,l для vim-пользователей
            { key = 'h', action = act.ActivatePaneDirection('Left') },
            { key = 'j', action = act.ActivatePaneDirection('Down') },
            { key = 'k', action = act.ActivatePaneDirection('Up') },
            { key = 'l', action = act.ActivatePaneDirection('Right') },
            
            -- Изменение размера панелей (Shift+стрелки)
            { key = 'LeftArrow', mods = 'SHIFT', action = act.AdjustPaneSize({ 'Left', 1 }) },
            { key = 'DownArrow', mods = 'SHIFT', action = act.AdjustPaneSize({ 'Down', 1 }) },
            { key = 'UpArrow', mods = 'SHIFT', action = act.AdjustPaneSize({ 'Up', 1 }) },
            { key = 'RightArrow', mods = 'SHIFT', action = act.AdjustPaneSize({ 'Right', 1 }) },
            
            -- Выход из режима
            { key = 'Escape', action = 'PopKeyTable' },
            { key = 'q', action = 'PopKeyTable' },
        },
        
        -- Таблица для управления шрифтом (Alt+F активирует)
        font_control = {
            -- Управление шрифтом (стрелки вверх/вниз)
            { key = 'UpArrow', action = act.IncreaseFontSize },
            { key = 'DownArrow', action = act.DecreaseFontSize },
            { key = 'r', action = act.ResetFontSize },
            { key = '0', action = act.ResetFontSize },
            
            -- Выход из режима
            { key = 'Escape', action = 'PopKeyTable' },
            { key = 'q', action = 'PopKeyTable' },
        },
    },
    
    mouse_bindings = {
        -- Перетаскивание окна с помощью мыши
        { event = { Drag = { streak = 1, button = 'Left' } }, mods = 'SUPER', action = wezterm.action.StartWindowDrag },
        { event = { Drag = { streak = 1, button = 'Left' } }, mods = 'CTRL|SHIFT', action = wezterm.action.StartWindowDrag },
        
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
