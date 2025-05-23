-- cat > ~/.config/wezterm/config/keyboard/key-tables.lua << 'EOF'
--
-- ОПИСАНИЕ: Определение таблиц клавиш для различных режимов
-- Определяет наборы клавиш, которые активируются при входе в 
-- специальные режимы (сессии, панели, шрифты и др.).
--
-- ЗАВИСИМОСТИ: config.resurrect

local wezterm = require('wezterm')
local act = wezterm.action
local locale = require('config.locale')

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
    },
    copy_mode = {
        { key = "Escape", action = act.PopKeyTable },
        { key = "Enter", action = act.Multiple({
            act.CopyTo("Clipboard"),
            act.PopKeyTable
        })},
        { key = "v", action = act.PasteFrom("Clipboard") },
        { key = "c", action = act.CopyTo("Clipboard") },
        { key = "f", action = act.Multiple({
            act.EmitEvent("activate-copy-mode"),
            act.PopKeyTable
        })},
        { key = "m", action = act.Multiple({
            act.EmitEvent("activate-multi-select-mode"),
            act.PopKeyTable
        })},
        { key = "UpArrow", action = act.ScrollByLine(-1) },
        { key = "DownArrow", action = act.ScrollByLine(1) },
        { key = "LeftArrow", action = act.ScrollByPage(-1) },
        { key = "RightArrow", action = act.ScrollByPage(1) },
        { key = "Home", action = act.ScrollToTop },
        { key = "End", action = act.ScrollToBottom },
        { key = "PageUp", action = act.ScrollByPage(-1) },
        { key = "PageDown", action = act.ScrollByPage(1) },
        { key = "Tab", action = act.Multiple({
            act.EmitEvent("activate-next-tab"),
            act.PopKeyTable
        })},
        { key = "Shift+Tab", action = act.Multiple({
            act.EmitEvent("activate-previous-tab"),
            act.PopKeyTable
        })},
        { key = "1", action = act.ActivateTab(0) },
        { key = "2", action = act.ActivateTab(1) },
        { key = "3", action = act.ActivateTab(2) },
        { key = "4", action = act.ActivateTab(3) },
        { key = "5", action = act.ActivateTab(4) },
        { key = "6", action = act.ActivateTab(5) },
        { key = "7", action = act.ActivateTab(6) },
        { key = "8", action = act.ActivateTab(7) },
        { key = "9", action = act.ActivateTab(8) },
        { key = "0", action = act.ActivateTab(9) },
        { key = "q", action = act.PopKeyTable },
        { key = "Enter", action = act.PopKeyTable }
    },
    search_mode = {
        { key = "Escape", action = act.PopKeyTable },
        { key = "Enter", action = act.Multiple({
            act.CopyTo("Clipboard"),
            act.PopKeyTable
        })},
        { key = "v", action = act.PasteFrom("Clipboard") },
        { key = "c", action = act.CopyTo("Clipboard") },
        { key = "f", action = act.Multiple({
            act.EmitEvent("activate-copy-mode"),
            act.PopKeyTable
        })},
        { key = "m", action = act.Multiple({
            act.EmitEvent("activate-multi-select-mode"),
            act.PopKeyTable
        })},
        { key = "UpArrow", action = act.ScrollByLine(-1) },
        { key = "DownArrow", action = act.ScrollByLine(1) },
        { key = "LeftArrow", action = act.ScrollByPage(-1) },
        { key = "RightArrow", action = act.ScrollByPage(1) },
        { key = "Home", action = act.ScrollToTop },
        { key = "End", action = act.ScrollToBottom },
        { key = "PageUp", action = act.ScrollByPage(-1) },
        { key = "PageDown", action = act.ScrollByPage(1) },
        { key = "Tab", action = act.Multiple({
            act.EmitEvent("activate-next-tab"),
            act.PopKeyTable
        })},
        { key = "Shift+Tab", action = act.Multiple({
            act.EmitEvent("activate-previous-tab"),
            act.PopKeyTable
        })},
        { key = "1", action = act.ActivateTab(0) },
        { key = "2", action = act.ActivateTab(1) },
        { key = "3", action = act.ActivateTab(2) },
        { key = "4", action = act.ActivateTab(3) },
        { key = "5", action = act.ActivateTab(4) },
        { key = "6", action = act.ActivateTab(5) },
        { key = "7", action = act.ActivateTab(6) },
        { key = "8", action = act.ActivateTab(7) },
        { key = "9", action = act.ActivateTab(8) },
        { key = "0", action = act.ActivateTab(9) },
        { key = "q", action = act.PopKeyTable },
        { key = "Enter", action = act.PopKeyTable }
    }
}
