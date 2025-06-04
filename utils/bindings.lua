-- cat > ~/.config/wezterm/utils/bindings.lua << 'EOF'
--
-- ОПИСАНИЕ: Утилиты для работы с биндингами клавиш и мыши WezTerm
-- Централизованные функции для создания привязок клавиш, управления модификаторами.
-- ПОЛНОСТЬЮ САМОДОСТАТОЧНЫЙ МОДУЛЬ - все зависимости передаются как параметры.
--
-- ЗАВИСИМОСТИ: НЕТ

local M = {}

-- Функция для переключения видимости панели вкладок
M.toggle_tab_bar = function(wezterm)
  return wezterm.action_callback(function(window, pane)
    local overrides = window:get_config_overrides() or {}
    local current_tab_bar_state = overrides.enable_tab_bar
    if current_tab_bar_state == nil then
      current_tab_bar_state = true
    end
    overrides.enable_tab_bar = not current_tab_bar_state
    window:set_config_overrides(overrides)
    wezterm.log_info("Tab bar toggled to: " .. tostring(overrides.enable_tab_bar))
  end)
end

-- Функция для циклического изменения прозрачности (вперед)
M.cycle_opacity_forward = function(wezterm)
  return wezterm.action.EmitEvent('cycle-opacity-forward')
end

-- Функция для циклического изменения прозрачности (назад)
M.cycle_opacity_backward = function(wezterm)
  return wezterm.action.EmitEvent('cycle-opacity-backward')
end

-- Функция для смены фонового изображения
M.change_background = function(wezterm)
  return wezterm.action.EmitEvent('change-background')
end

-- Функция для создания key table биндинга
M.create_key_table_binding = function(wezterm, key_table_name, timeout_ms)
  timeout_ms = timeout_ms or 10000
  return wezterm.action.Multiple({
    wezterm.action.ActivateKeyTable({
      name = key_table_name,
      one_shot = false,
      timeout_milliseconds = timeout_ms,
    }),
    wezterm.action.EmitEvent('force-update-status')
  })
end

-- Функция для отправки специальных символов (для macOS Alt/Option)
M.send_special_char = function(wezterm, char)
  return wezterm.action.SendString(char)
end

-- Функция для создания workspace (принимает wezterm и функцию перевода)
M.create_workspace = function(wezterm, t_func)
  t_func = t_func or function(key) return key end
  return wezterm.action.PromptInputLine {
    description = wezterm.format {
      { Attribute = { Intensity = "Bold" } },
      { Foreground = { AnsiColor = "Fuchsia" } },
      { Text = t_func("enter_workspace_name") },
    },
    action = wezterm.action_callback(function(window, pane, line)
      if line then
        window:perform_action(
          wezterm.action.SwitchToWorkspace {
            name = line,
          },
          pane
        )
      end
    end),
  }
end

-- Функция для создания workspace в новом окне
M.create_workspace_new_window = function(wezterm, t_func)
  t_func = t_func or function(key) return key end
  return wezterm.action.PromptInputLine {
    description = wezterm.format {
      { Attribute = { Intensity = "Bold" } },
      { Foreground = { AnsiColor = "Fuchsia" } },
      { Text = t_func("enter_workspace_name_new_window") },
    },
    action = wezterm.action_callback(function(window, pane, line)
      if line then
        window:perform_action(
          wezterm.action.SpawnWindow {
            workspace = line,
          },
          pane
        )
      end
    end),
  }
end

-- Функция для переименования вкладки
M.rename_tab = function(wezterm, t_func)
  t_func = t_func or function(key) return key end
  return wezterm.action.PromptInputLine({
    description = t_func("enter_new_tab_name"),
    action = wezterm.action_callback(function(window, pane, line)
      if line then
        window:active_tab():set_title(line)
      end
    end),
  })
end

-- Функция для генерации биндингов внешнего вида
M.generate_appearance_bindings = function(wezterm, mod)
  return {
    { key = '0', mods = 'CTRL', action = M.cycle_opacity_forward(wezterm) },
    { key = '9', mods = 'CTRL', action = M.cycle_opacity_backward(wezterm) },
    { key = 'h', mods = mod.SUPER_REV, action = M.toggle_tab_bar(wezterm) },
    { key = 'b', mods = 'SHIFT|' .. mod.SUPER, action = M.change_background(wezterm) },
  }
end

-- Функция для генерации биндингов key tables
M.generate_key_table_bindings = function(wezterm, mod)
  return {
    { key = 'p', mods = 'LEADER', action = M.create_key_table_binding(wezterm, 'pane_control') },
    { key = 'f', mods = 'LEADER', action = M.create_key_table_binding(wezterm, 'font_control') },
    { key = 's', mods = 'LEADER', action = M.create_key_table_binding(wezterm, 'session_control') },
  }
end

-- Функция для генерации биндингов специальных символов (macOS)
M.generate_special_char_bindings = function(wezterm)
  return {
    { key = "'", mods = 'ALT', action = M.send_special_char(wezterm, "\\") },
    { key = 'ñ', mods = 'ALT', action = M.send_special_char(wezterm, "~") },
    { key = '1', mods = 'ALT', action = M.send_special_char(wezterm, "|") },
    { key = 'º', mods = 'ALT', action = M.send_special_char(wezterm, "\\") },
    { key = '+', mods = 'ALT', action = M.send_special_char(wezterm, "]") },
    { key = '`', mods = 'ALT', action = M.send_special_char(wezterm, "[") },
    { key = 'ç', mods = 'ALT', action = M.send_special_char(wezterm, "}") },
    { key = '*', mods = 'ALT', action = M.send_special_char(wezterm, "{") },
    { key = '3', mods = 'ALT', action = M.send_special_char(wezterm, "#") },
  }
end

-- Функция для генерации биндингов workspace
M.generate_workspace_bindings = function(wezterm, mod, t_func)
  return {
    { key = "w", mods = "CTRL|SHIFT", action = M.create_workspace(wezterm, t_func) },
    { key = "w", mods = "CTRL|SHIFT|ALT", action = M.create_workspace_new_window(wezterm, t_func) },
    { key = "w", mods = "LEADER", action = wezterm.action.EmitEvent("workspace.switch") },
    { key = "W", mods = "LEADER", action = wezterm.action.EmitEvent("workspace.restore") },
  }
end


-- Функция для активации режима отладки с разделением панели
-- Функция для активации менеджера состояний
M.activate_state_manager = function(wezterm)
  return wezterm.action_callback(function(window, pane)
    local state_manager = require("config.dialogs.state-manager")
    state_manager.show_main_menu(window, pane)
  end)
end

M.activate_debug_mode_with_panel = function(wezterm)
  return wezterm.action_callback(function(window, pane)
    local debug_panel = require("config.dialogs.debug-manager")
    debug_panel.create_panel(window, pane)
  end)
end
-- Функция для закрытия отладочной панели
M.close_debug_panel = function(wezterm)
  return wezterm.action_callback(function(window, pane)
    local current_tab = window:active_tab()
    local panes = current_tab:panes()
    
    -- Ищем панель с названием DEBUG_PANEL
    for _, p in ipairs(panes) do
      if p:get_title() == "DEBUG_PANEL" then
        -- Активируем отладочную панель и закрываем её
        p:activate()
        window:perform_action(wezterm.action.CloseCurrentPane({ confirm = false }), p)
        break
      end
    end
  end)
end
return M
