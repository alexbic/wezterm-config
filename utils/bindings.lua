-- cat > ~/.config/wezterm/utils/bindings.lua << 'EOF'
--
-- ОПИСАНИЕ: Утилиты для работы с биндингами клавиш и мыши WezTerm
-- Централизованные функции для создания привязок клавиш, управления модификаторами
-- ТОЛЬКО ФУНКЦИИ - биндинги определяются в config/bindings/keyboard.lua
--
-- ЗАВИСИМОСТИ: wezterm, utils.platform

local wezterm = require('wezterm')
local platform = require('utils.platform')()
local environment = require('config.environment')

local M = {}

-- Определяем модификаторы для текущей платформы
M.get_modifiers = function()
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
  return mod
end

-- Функция для переключения видимости панели вкладок
M.toggle_tab_bar = function()
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
M.cycle_opacity_forward = function()
  return wezterm.action.EmitEvent('cycle-opacity-forward')
end

-- Функция для циклического изменения прозрачности (назад)
M.cycle_opacity_backward = function()
  return wezterm.action.EmitEvent('cycle-opacity-backward')
end

-- Функция для смены фонового изображения
M.change_background = function()
  return wezterm.action.EmitEvent('change-background')
end

-- Функция для создания key table биндинга
M.create_key_table_binding = function(key_table_name, timeout_ms)
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
M.send_special_char = function(char)
  return wezterm.action.SendString(char)
end

-- Функция для создания workspace в текущем окне
M.create_workspace = function()
  return wezterm.action.PromptInputLine {
    description = wezterm.format {
      { Attribute = { Intensity = "Bold" } },
      { Foreground = { AnsiColor = "Fuchsia" } },
      { Text = environment.locale.t("enter_workspace_name") },
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
M.create_workspace_new_window = function()
  return wezterm.action.PromptInputLine {
    description = wezterm.format {
      { Attribute = { Intensity = "Bold" } },
      { Foreground = { AnsiColor = "Fuchsia" } },
      { Text = environment.locale.t("enter_workspace_name_new_window") },
    },
    action = wezterm.action_callback(function(window, pane, line)
      if line then
        -- Создаем новое окно с workspace сразу
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
M.rename_tab = function()
  return wezterm.action.PromptInputLine({
    description = environment.locale.t("enter_new_tab_name"),
    action = wezterm.action_callback(function(window, pane, line)
      if line then
        window:active_tab():set_title(line)
      end
    end),
  })
end

return M
-- EOF
