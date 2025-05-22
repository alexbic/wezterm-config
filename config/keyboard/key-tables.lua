-- cat > ~/.config/wezterm/config/keyboard/key-tables.lua << 'EOF'
--
-- ОПИСАНИЕ: Определение таблиц клавиш для различных режимов
-- Определяет наборы клавиш, которые активируются при входе в 
-- специальные режимы (сессии, панели, шрифты и др.).
--
-- ЗАВИСИМОСТИ: config.resurrect

local wezterm = require('wezterm')
local act = wezterm.action

-- Определяем все таблицы клавиш
return {
  -- Таблица для управления панелями (Alt+A, затем p)
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
    
    -- Изменение размера панелей (Shift+стрелки)
    { key = 'LeftArrow', mods = 'SHIFT', action = act.AdjustPaneSize({ 'Left', 1 }) },
    { key = 'DownArrow', mods = 'SHIFT', action = act.AdjustPaneSize({ 'Down', 1 }) },
    { key = 'UpArrow', mods = 'SHIFT', action = act.AdjustPaneSize({ 'Up', 1 }) },
    { key = 'RightArrow', mods = 'SHIFT', action = act.AdjustPaneSize({ 'Right', 1 }) },
    
    -- Выход из режима
    { key = 'Escape', action = act.PopKeyTable },
    { key = 'q', action = act.PopKeyTable },
    { key = 'Enter', action = act.PopKeyTable },
  },
  
  -- Отдельная таблица для управления шрифтом (Alt+A, затем f)
  font_control = {
    -- Управление шрифтом (стрелки вверх/вниз)
    { key = 'UpArrow', action = act.IncreaseFontSize },
    { key = 'DownArrow', action = act.DecreaseFontSize },
    { key = 'r', action = act.ResetFontSize },
    { key = '0', action = act.ResetFontSize },
    
    -- Выход из режима
    { key = 'Escape', action = act.PopKeyTable },
    { key = 'q', action = act.PopKeyTable },
    { key = 'Enter', action = act.PopKeyTable },
  },
  
  -- Таблица для управления сессиями (Alt+A, затем s)
  session_control = {
    -- ЗАКРЫВАЕМ таблицу при операциях, но сохраняем режим для показа
    { key = "s", action = act.Multiple({
        act.EmitEvent("resurrect.save_state"),
        act.PopKeyTable  -- Закрываем таблицу, чтобы клавиши не мешали
      })
    },
    { key = "r", action = act.Multiple({
        act.EmitEvent("resurrect.restore_state"),
        act.PopKeyTable
      })
    },
    { key = "l", action = act.Multiple({
        act.EmitEvent("resurrect.load_state"),
        act.PopKeyTable
      })
    },
    { key = "d", action = act.Multiple({
        act.EmitEvent("resurrect.delete_state"),
        act.PopKeyTable
      })
    },
    { key = "t", action = act.Multiple({
        act.EmitEvent("resurrect.test_notification"),
        act.PopKeyTable
      })
    },
    
    -- Выход из режима управления сессиями - ПОЛНОСТЬЮ очищаем режим
    { key = 'Escape', action = act.Multiple({
        act.EmitEvent('clear-saved-mode'),
        act.PopKeyTable
      })
    },
    { key = 'q', action = act.Multiple({
        act.EmitEvent('clear-saved-mode'),
        act.PopKeyTable
      })
    },
    { key = 'Enter', action = act.Multiple({
        act.EmitEvent('clear-saved-mode'),
        act.PopKeyTable
      })
    },
  },
}
