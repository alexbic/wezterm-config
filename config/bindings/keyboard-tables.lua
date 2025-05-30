-- cat > ~/.config/wezterm/config/keyboard/key-tables.lua << 'EOF'
--
-- ОПИСАНИЕ: Определение таблиц клавиш для различных режимов
-- Определяет наборы клавиш, которые активируются при входе в 
-- специальные режимы (сессии, панели, шрифты и др.).
--
-- ЗАВИСИМОСТИ: config.resurrect

local wezterm = require('wezterm')
local act = wezterm.action
local environment = require('config.environment')

return {
    debug_control = {
        { key = "l", action = act.Multiple({
            wezterm.action_callback(function(window, pane)
                local debug_manager = require("utils.debug-manager")
                local environment = require("config.environment")
                local debug = require("utils.debug")
                debug.enable_debug(wezterm, environment.locale.t, "global")
                local modules = debug_manager.get_available_modules()
                debug.log_system(wezterm, environment.locale.t, "debug_status_title")
                -- Собираем статус всех модулей в одну строку
                local status_parts = {}
                for _, module in ipairs(modules) do
                    local state = debug.DEBUG_CONFIG[module] and environment.locale.t("debug_status_on") or environment.locale.t("debug_status_off")
                    table.insert(status_parts, module .. ": " .. state)
                end
                debug.log_system(wezterm, environment.locale.t, "debug_modules_status", "  " .. table.concat(status_parts, "\n  "))
            end),
            act.PopKeyTable,
            act.EmitEvent("force-update-status")
        }) },
        { key = "a", action = act.Multiple({
            wezterm.action_callback(function(window, pane)
                local debug = require("utils.debug")
                local environment = require("config.environment")
                debug.enable_all(wezterm, environment.locale.t)
                debug.log(wezterm, environment.locale.t, "global", "debug_all_enabled")
                wezterm.emit("update-right-status", window, pane)
            end),
            act.PopKeyTable,
            act.EmitEvent("force-update-status")
        }) },
        { key = "o", action = act.Multiple({
            wezterm.action_callback(function(window, pane)
                local debug = require("utils.debug")
                local environment = require("config.environment")
                local debug_manager = require("utils.debug-manager")
                debug.disable_all(wezterm, environment.locale.t)
                -- Включаем global обратно для вывода
                debug.enable_debug(wezterm, environment.locale.t, "global")
                debug.log(wezterm, environment.locale.t, "global", "debug_all_disabled")
                -- Показываем обновленный статус всех модулей
                local modules = debug_manager.get_available_modules()
                local status_parts = {}
                for _, module in ipairs(modules) do
                    local state = debug.DEBUG_CONFIG[module] and environment.locale.t("debug_status_on") or environment.locale.t("debug_status_off")
                    table.insert(status_parts, module .. ": " .. state)
                end
                debug.log_system(wezterm, environment.locale.t, "debug_modules_status", "  " .. table.concat(status_parts, "\n  "))
                wezterm.emit("update-right-status", window, pane)
            end),
            act.PopKeyTable,
            act.EmitEvent("force-update-status")
        }) },        { key = "Escape", action = act.Multiple({ act.PopKeyTable, act.EmitEvent("force-update-status") }) },
        { key = "Enter", action = act.Multiple({ act.PopKeyTable, act.EmitEvent("force-update-status") }) }
    },
    session_control = {
        { key = "s", action = act.Multiple({
            act.EmitEvent("resurrect.save_state"),
            act.PopKeyTable
        })}, -- Save workspace
        { key = "l", action = act.Multiple({
            act.EmitEvent("workspace.switch"),
            act.PopKeyTable
        })}, -- List workspace switcher
        { key = "w", action = act.Multiple({
            act.EmitEvent("resurrect.save_window"),
            act.PopKeyTable
        })}, -- Save current window
        { key = "t", action = act.Multiple({
            act.EmitEvent("resurrect.save_tab"),
            act.PopKeyTable
        })}, -- Save current tab
        { key = "d", action = act.Multiple({
            act.EmitEvent("resurrect.delete_state"),
            act.PopKeyTable
        })}, -- Delete saved state
        { key = "Escape", action = act.Multiple({
            act.EmitEvent("clear-saved-mode"),
            act.Multiple({ act.PopKeyTable, act.EmitEvent("force-update-status") })
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
        { key = "Escape", action = act.Multiple({ act.Multiple({ act.PopKeyTable, act.EmitEvent("force-update-status") }), act.EmitEvent("update-status-on-key-table-exit") }) },
        { key = "Enter", action = act.Multiple({ act.Multiple({ act.PopKeyTable, act.EmitEvent("force-update-status") }), act.EmitEvent("update-status-on-key-table-exit") }) }
    },
    font_control = {
        { key = "UpArrow", action = act.IncreaseFontSize },
        { key = "DownArrow", action = act.DecreaseFontSize },
        { key = "r", action = act.ResetFontSize },
        { key = "0", action = act.ResetFontSize },
        { key = "Escape", action = act.Multiple({ act.Multiple({ act.PopKeyTable, act.EmitEvent("force-update-status") }), act.EmitEvent("update-status-on-key-table-exit") }) },
        { key = "Enter", action = act.Multiple({ act.Multiple({ act.PopKeyTable, act.EmitEvent("force-update-status") }), act.EmitEvent("update-status-on-key-table-exit") }) }
    },
    copy_mode = {
        -- 🚪 ЕДИНСТВЕННЫЙ способ выхода из copy_mode
        { key = "Escape", action = act.CopyMode('Close') },
        
        -- Основные действия копирования
        { key = "Enter", action = act.Multiple({
            act.CopyTo("Clipboard"),
            act.CopyMode('Close')
        })},
        { key = "y", action = act.Multiple({
            act.CopyTo("Clipboard"),
            act.CopyMode('Close')
        })},
        { key = "c", action = act.CopyTo("Clipboard") },
        { key = "v", action = act.PasteFrom("Clipboard") },
        
        -- Навигация
        { key = "h", action = act.CopyMode('MoveLeft') },
        { key = "j", action = act.CopyMode('MoveDown') },
        { key = "k", action = act.CopyMode('MoveUp') },
        { key = "l", action = act.CopyMode('MoveRight') },
        { key = "LeftArrow", action = act.CopyMode('MoveLeft') },
        { key = "DownArrow", action = act.CopyMode('MoveDown') },
        { key = "UpArrow", action = act.CopyMode('MoveUp') },
        { key = "RightArrow", action = act.CopyMode('MoveRight') },
        
        -- Прокрутка
        { key = "PageUp", action = act.CopyMode('PageUp') },
        { key = "PageDown", action = act.CopyMode('PageDown') },
        { key = "Home", action = act.CopyMode('MoveToStartOfLine') },
        { key = "End", action = act.CopyMode('MoveToEndOfLineContent') },
        { key = "g", action = act.CopyMode('MoveToScrollbackTop') },
        { key = "G", action = act.CopyMode('MoveToScrollbackBottom') },
        
        -- Выделение
        { key = "v", action = act.CopyMode({ SetSelectionMode = 'Cell' }) },
        { key = "V", action = act.CopyMode({ SetSelectionMode = 'Line' }) },
        { key = " ", action = act.CopyMode({ SetSelectionMode = 'Cell' }) },
        
        -- 🔄 ПЕРЕКЛЮЧЕНИЕ ВКЛАДОК с выходом из copy_mode
        { key = "Tab", action = act.Multiple({
            act.ActivateTabRelative(1),
            act.CopyMode('Close')  -- Выходим из copy_mode после переключения
        })},
        { key = "Tab", mods = "SHIFT", action = act.Multiple({
            act.ActivateTabRelative(-1),
            act.CopyMode('Close')  -- Выходим из copy_mode после переключения
        })},
        
        -- Прямое переключение на вкладку по номеру (ОСТАЕМСЯ в copy_mode)
        { key = "1", action = act.ActivateTab(0) },
        { key = "2", action = act.ActivateTab(1) },
        { key = "3", action = act.ActivateTab(2) },
        { key = "4", action = act.ActivateTab(3) },
        { key = "5", action = act.ActivateTab(4) },
        { key = "6", action = act.ActivateTab(5) },
        { key = "7", action = act.ActivateTab(6) },
        { key = "8", action = act.ActivateTab(7) },
        { key = "9", action = act.ActivateTab(8) },
        { key = "0", action = act.ActivateTab(9) }
    },
    search_mode = {
        { key = "Escape", action = act.Multiple({ act.Multiple({ act.PopKeyTable, act.EmitEvent("force-update-status") }), act.EmitEvent("update-status-on-key-table-exit") }) },
        { key = "Enter", action = act.Multiple({
            act.CopyTo("Clipboard"),
            act.Multiple({ act.PopKeyTable, act.EmitEvent("force-update-status") })
        })},
        { key = "v", action = act.PasteFrom("Clipboard") },
        { key = "c", action = act.CopyTo("Clipboard") },
        { key = "f", action = act.Multiple({
            act.EmitEvent("activate-copy-mode"),
            act.Multiple({ act.PopKeyTable, act.EmitEvent("force-update-status") })
        })},
        { key = "m", action = act.Multiple({
            act.EmitEvent("activate-multi-select-mode"),
            act.Multiple({ act.PopKeyTable, act.EmitEvent("force-update-status") })
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
            act.Multiple({ act.PopKeyTable, act.EmitEvent("force-update-status") })
        })},
        { key = "Tab", mods = "SHIFT", action = act.Multiple({
            act.EmitEvent("activate-previous-tab"),
            act.Multiple({ act.PopKeyTable, act.EmitEvent("force-update-status") })
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
        { key = "Enter", action = act.Multiple({ act.Multiple({ act.PopKeyTable, act.EmitEvent("force-update-status") }), act.EmitEvent("update-status-on-key-table-exit") }) }
    }
}
