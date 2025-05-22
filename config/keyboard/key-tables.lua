-- cat > ~/.config/wezterm/config/keyboard/key-tables.lua << 'EOF'
--
-- ОПИСАНИЕ: Определение таблиц клавиш для различных режимов
-- Определяет наборы клавиш, которые активируются при входе в 
-- специальные режимы (сессии, панели, шрифты и др.).
--
-- ЗАВИСИМОСТИ: config.resurrect

local wezterm = require('wezterm')
local act = wezterm.action

return {
    session_control = {
        { key = "s", action = act.Multiple({
            act.EmitEvent("resurrect.save_state"),
            act.PopKeyTable
        })},
        { key = "l", action = act.Multiple({
            act.EmitEvent("resurrect.load_state"),
            act.PopKeyTable
        })},
        { key = "d", action = act.Multiple({
            act.EmitEvent("resurrect.delete_state"),
            act.PopKeyTable
        })},
        { key = "Escape", action = act.Multiple({
            act.EmitEvent("clear-saved-mode"),
            act.PopKeyTable
        })},
        { key = "q", action = act.Multiple({
            act.EmitEvent("clear-saved-mode"),
            act.PopKeyTable
        })}
    },
    pane_control = {
        { key = "-", action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
        { key = "_", action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
        { key = "x", action = act.CloseCurrentPane({ confirm = true }) },
        { key = "z", action = act.TogglePaneZoomState },
        { key = "LeftArrow", action = act.ActivatePaneDirection('Left') },
        { key = "DownArrow", action = act.ActivatePaneDirection('Down') },
        { key = "UpArrow", action = act.ActivatePaneDirection('Up') },
        { key = "RightArrow", action = act.ActivatePaneDirection('Right') },
        { key = "LeftArrow", mods = 'SHIFT', action = act.AdjustPaneSize({ 'Left', 1 }) },
        { key = "DownArrow", mods = 'SHIFT', action = act.AdjustPaneSize({ 'Down', 1 }) },
        { key = "UpArrow", mods = 'SHIFT', action = act.AdjustPaneSize({ 'Up', 1 }) },
        { key = "RightArrow", mods = 'SHIFT', action = act.AdjustPaneSize({ 'Right', 1 }) },
        { key = "Escape", action = act.PopKeyTable },
        { key = "q", action = act.PopKeyTable },
        { key = "Enter", action = act.PopKeyTable }
    },
    font_control = {
        { key = "UpArrow", action = act.IncreaseFontSize },
        { key = "DownArrow", action = act.DecreaseFontSize },
        { key = "r", action = act.ResetFontSize },
        { key = "0", action = act.ResetFontSize },
        { key = "Escape", action = act.PopKeyTable },
        { key = "q", action = act.PopKeyTable },
        { key = "Enter", action = act.PopKeyTable }
    }
}
