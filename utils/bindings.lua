-- cat > ~/.config/wezterm/utils/bindings.lua << 'EOF'
--
-- ОПИСАНИЕ: Утилиты для работы с биндингами клавиш и мыши WezTerm
-- Централизованные функции для создания привязок клавиш, управления модификаторами
-- и генерации специализированных биндингов для разных категорий функций.
--
-- ЗАВИСИМОСТИ: wezterm, utils.platform

local wezterm = require('wezterm')
local platform = require('utils.platform')()

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
    
    -- Если enable_tab_bar не установлен в overrides, используем значение по умолчанию (true)
    local current_tab_bar_state = overrides.enable_tab_bar
    if current_tab_bar_state == nil then
      current_tab_bar_state = true -- значение по умолчанию
    end
    
    -- Переключаем состояние
    overrides.enable_tab_bar = not current_tab_bar_state
    window:set_config_overrides(overrides)
    
    -- Логируем для отладки
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

-- Функция для создания key table биндинга с принудительным обновлением статуса
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

-- Функция для создания workspace
M.create_workspace = function()
  return wezterm.action.PromptInputLine {
    description = wezterm.format {
      { Attribute = { Intensity = "Bold" } },
      { Foreground = { AnsiColor = "Fuchsia" } },
      { Text = "Введите имя для нового workspace" },
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

-- Функция для переименования вкладки
M.rename_tab = function()
  return wezterm.action.PromptInputLine({
    description = 'Enter new name for tab',
    action = wezterm.action_callback(function(window, pane, line)
      if line then
        window:active_tab():set_title(line)
      end
    end),
  })
end

-- Функция для валидации биндинга
M.is_valid_binding = function(binding)
  if not binding or type(binding) ~= "table" then
    return false
  end
  
  -- Проверяем обязательные поля
  if not binding.key or not binding.action then
    return false
  end
  
  -- Проверяем тип ключа
  if type(binding.key) ~= "string" then
    return false
  end
  
  return true
end

-- Функция для генерации биндингов внешнего вида
M.generate_appearance_bindings = function(mod)
  return {
    -- Циклическое изменение прозрачности
    { key = '0', mods = 'CTRL', action = M.cycle_opacity_forward() },
    { key = '9', mods = 'CTRL', action = M.cycle_opacity_backward() },
    
    -- Переключение видимости панели закладок
    { key = 'h', mods = mod.SUPER_REV, action = M.toggle_tab_bar() },
    
    -- Горячие клавиши для смены фона
    { key = 'b', mods = 'SHIFT|' .. mod.SUPER, action = M.change_background() },
  }
end

-- Функция для генерации биндингов key tables
M.generate_key_table_bindings = function(mod)
  return {
    -- Активаторы для key_tables с принудительным обновлением статуса
    { key = 'p', mods = 'LEADER', action = M.create_key_table_binding('pane_control') },
    { key = 'f', mods = 'LEADER', action = M.create_key_table_binding('font_control') },
    { key = 's', mods = 'LEADER', action = M.create_key_table_binding('session_control') },
  }
end

-- Функция для генерации биндингов специальных символов (macOS)
M.generate_special_char_bindings = function()
  return {
    -- Отправка специальных символов через Alt (Option) для macOS
    { key = "'", mods = 'ALT', action = M.send_special_char("\\") },
    { key = 'ñ', mods = 'ALT', action = M.send_special_char("~") },
    { key = '1', mods = 'ALT', action = M.send_special_char("|") },
    { key = 'º', mods = 'ALT', action = M.send_special_char("\\") },
    { key = '+', mods = 'ALT', action = M.send_special_char("]") },
    { key = '`', mods = 'ALT', action = M.send_special_char("[") },
    { key = 'ç', mods = 'ALT', action = M.send_special_char("}") },
    { key = '*', mods = 'ALT', action = M.send_special_char("{") },
    { key = '3', mods = 'ALT', action = M.send_special_char("#") },
  }
end

-- Функция для генерации биндингов workspace
M.generate_workspace_bindings = function(mod)
  return {
    -- Создание нового workspace
    { key = "w", mods = "CTRL|SHIFT", action = M.create_workspace() },
    
    -- Горячие клавиши для workspace управления
    { key = "w", mods = "LEADER", action = wezterm.action.EmitEvent("workspace.switch") },
    { key = "W", mods = "LEADER", action = wezterm.action.EmitEvent("workspace.restore") },
  }
end

return M
