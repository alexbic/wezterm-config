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

-- Функция для создания workspace (принимает готовый текст)
M.create_workspace = function(wezterm, description_text)
  description_text = description_text or "Enter workspace name:"
  return wezterm.action.PromptInputLine {
    description = wezterm.format {
      { Attribute = { Intensity = "Bold" } },
      { Foreground = { AnsiColor = "Fuchsia" } },
      { Text = description_text },
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
M.create_workspace_new_window = function(wezterm, description_text)
  description_text = description_text or "Enter workspace name for new window:"
  return wezterm.action.PromptInputLine {
    description = wezterm.format {
      { Attribute = { Intensity = "Bold" } },
      { Foreground = { AnsiColor = "Fuchsia" } },
      { Text = description_text },
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
M.rename_tab = function(wezterm, description_text)
  description_text = description_text or "Enter new tab name:"
  return wezterm.action.PromptInputLine({
    description = description_text,
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

-- Функция для генерации биндингов workspace (принимает готовые тексты)
M.generate_workspace_bindings = function(wezterm, mod, workspace_text, workspace_new_window_text)
  workspace_text = workspace_text or "Enter workspace name:"
  workspace_new_window_text = workspace_new_window_text or "Enter workspace name for new window:"
  
  return {
    { key = "w", mods = "CTRL|SHIFT", action = M.create_workspace(wezterm, workspace_text) },
    { key = "w", mods = "CTRL|SHIFT|ALT", action = M.create_workspace_new_window(wezterm, workspace_new_window_text) },
    { key = "w", mods = "LEADER", action = wezterm.action.EmitEvent("workspace.switch") },
    { key = "W", mods = "LEADER", action = wezterm.action.EmitEvent("workspace.restore") },
  }
end

-- F8 освобожден для будущего использования
M.create_debug_panel_action = function(wezterm)
  return wezterm.action_callback(function(window, pane)
    local debug = require("utils.debug")
    local environment = require("config.environment")
    local locale_t = environment.locale and environment.locale.t or {}
    local message = locale_t.unused_key_not_used or "не используется, доступна для новых функций"
    debug.log(wezterm, locale_t, "bindings", "F8", "F8 → " .. message)
  end)
end

-- Функция для F9 локализации через универсальную систему
M.create_locale_manager_action = function(wezterm)
  return wezterm.action_callback(function(window, pane)
    local dialogs = require("utils.dialogs")
    local environment = require("config.environment")
    local env_utils = require("utils.environment")
    local create_platform_info = require("utils.platform")
    local platform = create_platform_info(wezterm.target_triple)
    
    -- Устанавливаем название вкладки
    local tab = window:active_tab()
    tab:set_title("Управление локализацией")
    
    -- Сканируем доступные языки динамически
    local available_languages = env_utils.scan_locale_files(wezterm.config_dir, platform)
    local current_language = (environment.locale and environment.locale.current_language) or "ru"
    
    -- Создаём динамическую конфигурацию
    local dynamic_locale_config = {
      meta = {
        title_key = "locale_manager_wezterm_title",
        icon_key = "locale_manager", 
        tab_title_key = "locale_manager_title",
        fuzzy = true
      },
      main_items = {},
      service_items = {}
    }
    
    -- Добавляем заголовок
    table.insert(dynamic_locale_config.main_items, {
      id = "header",
      text_key = "locale_manager_title",
      icon_key = "system",
      action = "header"
    })
    
    -- Текущий язык
    table.insert(dynamic_locale_config.main_items, {
      id = "current",
      text_key = "locale_current_language",
      icon_key = "locale_current", 
      action = "show_current",
      extra_text = current_language
    })
    
    -- Доступные языки с иконками состояния
    for lang_code, lang_data in pairs(available_languages) do
      local status_icon = (lang_code == current_language) and "🟢" or "⚪"
      table.insert(dynamic_locale_config.main_items, {
        id = "switch_" .. lang_code,
        text_key = lang_data.name .. " (" .. lang_code .. ")",
        icon_key = status_icon,
        action = "switch_lang",
        lang = lang_code
      })
    end
    
    -- Служебные команды
    table.insert(dynamic_locale_config.service_items, {
      id = "regenerate",
      text_key = "locale_regenerate_cache",
      icon_key = "locale_refresh",
      action = "regenerate"
    })
    
    table.insert(dynamic_locale_config.service_items, {
      id = "emergency_fix",
      text_key = "Экстренное восстановление ru.lua",
      icon_key = "locale_emergency",
      action = "emergency"
    })
    
    local locale_state_provider = {
      handle_action = function(id, inner_window, inner_pane)
        -- ИСПРАВЛЕНИЕ: проверка на nil id (ESC нажатие)
        if not id then
          return { action = "close" }
        end
        if id == "header" or id == "current" then
          return { action = "none" }
        elseif id:match("^switch_") then
          local lang_code = id:match("^switch_(.+)$")
          if lang_code and lang_code ~= current_language then
            local success = env_utils.switch_language_and_rebuild(wezterm.config_dir, platform, lang_code)
            if success then
              inner_window:toast_notification("Локализация", "Язык переключен на: " .. lang_code, nil, 3000)
              wezterm.reload_configuration()
            end
          end
          return { action = "close" }
        elseif id == "regenerate" then
          local success = env_utils.rebuild_locale_cache_file(wezterm.config_dir, platform, current_language)
          if success then
            inner_window:toast_notification("Локализация", "Кэш перегенерирован", nil, 3000)
            wezterm.reload_configuration()
          end
          return { action = "close" }
        elseif id == "emergency_fix" then
          local success = env_utils.rebuild_locale_cache_file(wezterm.config_dir, platform, "ru")
          if success then
            inner_window:toast_notification("Восстановление", "Восстановлено на русский язык", nil, 3000)
            wezterm.reload_configuration()
          end
          return { action = "close" }
        end
        return { action = "none" }
      end
    }
    
    window:perform_action(dialogs.build_inputselector(wezterm, dynamic_locale_config, locale_state_provider), pane)
  end)
end

-- Функция для F10 центра управления через универсальную систему
M.create_f10_settings_action = function(wezterm)
  return wezterm.action_callback(function(window, pane)
    local dialogs = require("utils.dialogs")
    local settings_config = require("config.dialogs.settings-manager")
    
    local settings_state_provider = {
      handle_action = function(id, inner_window, inner_pane)
        -- ИСПРАВЛЕНИЕ: проверка на nil id (ESC нажатие)
        if not id then
          return { action = "close" }
        end
        if id == "locale_settings" then
          M.create_locale_manager_action(wezterm)()(inner_window, inner_pane)
          return { action = "close" }
        elseif id == "debug_settings" then
          M.create_shift_f12_debug_action(wezterm)()(inner_window, inner_pane)
          return { action = "close" }
        elseif id == "state_settings" then
          inner_window:toast_notification("Состояния", "Менеджер состояний в разработке", nil, 2000)
          return { action = "none" }
        end
        return { action = "none" }
      end
    }
    
    window:perform_action(dialogs.build_inputselector(wezterm, settings_config, settings_state_provider), pane)
  end)
end

-- Функция для Shift+F12 отладки через универсальную систему
M.create_shift_f12_debug_action = function(wezterm)
  return wezterm.action_callback(function(window, pane)
    local dialogs = require("utils.dialogs")
    local debug_config = require("config.dialogs.debug-manager")
    local debug = require("utils.debug")
    
    local debug_state_provider = {
      get_state = function(module_name) 
        return debug.DEBUG_CONFIG[module_name] 
      end,
      handle_action = function(id, inner_window, inner_pane)
        -- ИСПРАВЛЕНИЕ: проверка на nil id (ESC нажатие)
        if not id then
          return { action = "close" }
        end
        if id == "enable_all" then
          for module_name, _ in pairs(debug.DEBUG_CONFIG) do
            debug.DEBUG_CONFIG[module_name] = true
          end
          debug.save_debug_settings(wezterm)
          return { action = "refresh" }
        elseif id == "disable_all" then
          for module_name, _ in pairs(debug.DEBUG_CONFIG) do
            debug.DEBUG_CONFIG[module_name] = false
          end
          debug.save_debug_settings(wezterm)
          return { action = "refresh" }
        elseif debug.DEBUG_CONFIG[id] ~= nil then
          debug.DEBUG_CONFIG[id] = not debug.DEBUG_CONFIG[id]
          debug.save_debug_settings(wezterm)
          return { action = "refresh" }
        end
        return { action = "none" }
      end
    }
    
    debug.load_debug_settings(wezterm)
    window:perform_action(dialogs.build_inputselector(wezterm, debug_config, debug_state_provider), pane)
  end)
end

-- Функция для принудительной перезагрузки
M.create_force_reload_action = function(wezterm)
  return wezterm.action_callback(function(window, pane)
    local env_utils = require("utils.environment")
    env_utils.force_config_reload(wezterm)
  end)
end

-- Функция сборки всех биндингов (перенесена из keyboard.lua)
M.build_keys = function(wezterm, base_keys, mod, platform, locale_t)
  local keys = {}
  for _, key in ipairs(base_keys) do 
    table.insert(keys, key) 
  end
  for _, key in ipairs(M.generate_appearance_bindings(wezterm, mod)) do 
    table.insert(keys, key) 
  end
  for _, key in ipairs(M.generate_key_table_bindings(wezterm, mod)) do 
    table.insert(keys, key) 
  end
  if platform.is_mac then
    for _, key in ipairs(M.generate_special_char_bindings(wezterm)) do 
      table.insert(keys, key) 
    end
  end
  for _, key in ipairs(M.generate_workspace_bindings(wezterm, mod, locale_t.enter_workspace_name or "Введите имя workspace:", locale_t.enter_workspace_name_new_window or "Введите имя workspace для нового окна:")) do 
    table.insert(keys, key) 
  end
  return keys
end

return M
