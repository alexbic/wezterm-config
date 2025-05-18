local wezterm = require('wezterm')
local act = wezterm.action

-- Показываем активную ключевую таблицу в строке состояния
wezterm.on('update-right-status', function(window, pane)
    local name = window:active_key_table()
    if name then
        window:set_right_status('MODE: ' .. name)
    else
        window:set_right_status('')
    end
end)

-- Конфигурация
return {
    -- Отключаем стандартные привязки клавиш
    disable_default_key_bindings = true,
    
    -- Лидер-клавиша Alt+A
    leader = { key = 'a', mods = 'ALT', timeout_milliseconds = 1000 },
    
    -- Основные горячие клавиши
    keys = {
        -- Функциональные клавиши
        { key = 'F1', mods = 'NONE', action = 'ActivateCopyMode' },
        { key = 'F2', mods = 'NONE', action = act.ActivateCommandPalette },
        { key = 'F3', mods = 'NONE', action = act.ShowLauncher },
        { key = 'F12', mods = 'NONE', action = act.ShowDebugOverlay },
        
        -- Alt+A затем цифра для прозрачности
        { key = '1', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.05') },
        { key = '2', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.15') },
        { key = '3', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.25') },
        { key = '4', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.4') },
        { key = '5', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.6') },
        { key = '6', mods = 'LEADER', action = act.EmitEvent('set-opacity-0.8') },
        { key = '9', mods = 'LEADER', action = act.EmitEvent('reset-to-defaults') },
        
        -- Активация ключевых таблиц
        { 
            key = 'p', 
            mods = 'LEADER', 
            action = act.ActivateKeyTable { 
                name = 'pane_control',
                one_shot = false,
                timeout_milliseconds = 0
            } 
        },
        { 
            key = 'f', 
            mods = 'LEADER', 
            action = act.ActivateKeyTable { 
                name = 'font_control',
                one_shot = false,
                timeout_milliseconds = 0
            } 
        },
        
        -- Копирование/вставка
        { key = 'c', mods = 'SUPER', action = act.CopyTo('Clipboard') },
        { key = 'v', mods = 'SUPER', action = act.PasteFrom('Clipboard') },
        
        -- Управление вкладками
        { key = 't', mods = 'SUPER', action = act.SpawnTab('DefaultDomain') },
        { key = 'w', mods = 'SUPER|CTRL', action = act.CloseCurrentTab({ confirm = false }) },
    },
    
    -- Определяем ключевые таблицы
    key_tables = {
        -- Таблица для управления панелями
        pane_control = {
            -- Разделение панелей
            { key = '-', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
            { key = '_', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
            { key = 'x', action = act.CloseCurrentPane({ confirm = true }) },
            { key = 'z', action = act.TogglePaneZoomState },
            
            -- Навигация между панелями
            { key = 'LeftArrow', action = act.ActivatePaneDirection('Left') },
            { key = 'DownArrow', action = act.ActivatePaneDirection('Down') },
            { key = 'UpArrow', action = act.ActivatePaneDirection('Up') },
            { key = 'RightArrow', action = act.ActivatePaneDirection('Right') },
            
            -- Выход из режима
            { key = 'Escape', action = 'PopKeyTable' },
            { key = 'q', action = 'PopKeyTable' },
        },
        
        -- Таблица для управления шрифтом
        font_control = {
            -- Управление шрифтом
            { key = 'UpArrow', action = act.IncreaseFontSize },
            { key = 'DownArrow', action = act.DecreaseFontSize },
            { key = '0', action = act.ResetFontSize },
            
            -- Выход из режима
            { key = 'Escape', action = 'PopKeyTable' },
            { key = 'q', action = 'PopKeyTable' },
        },
    },
}
