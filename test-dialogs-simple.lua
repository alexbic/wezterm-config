#!/usr/bin/env lua

-- Простой тест системы диалогов без загрузки wezterm
print("🧪 Тестирование системы диалогов...")

-- Мокаем wezterm.format для тестирования
local mock_wezterm = {
  format = function(elements)
    local result = ""
    for _, element in ipairs(elements) do
      if element.Text then
        result = result .. element.Text
      end
    end
    return result
  end
}

-- Загружаем только наш модуль диалогов
package.path = package.path .. ";./utils/?.lua;./config/?.lua;./config/environment/?.lua"

-- Мокаем зависимости
local mock_environment = {
  locale = {
    t = function(key, ...)
      local translations = {
        save_workspace_tab_title = "Сохранить сессию",
        current_workspace = "Текущая workspace: %s",
        save_window_tab_title = "Сохранить окно",
        save_window_default = "По умолчанию: %s",
        save_tab_tab_title = "Сохранить вкладку",
        save_tab_default = "По умолчанию: %s",
        loading_sessions_title = "Загрузка сессии",
        loading_sessions_description = "Выберите сессию для загрузки",
        deleting_sessions_title = "Удаление сессии",
        deleting_sessions_description = "Выберите сессию для удаления"
      }
      local template = translations[key] or key
      if ... then
        return string.format(template, ...)
      else
        return template
      end
    end
  }
}

local mock_icons = {
  ICONS = {
    workspace = "󱂬",
    window = "",
    tab = "󰓩"
  }
}

local mock_colors = {
  COLORS = {
    dialog_save_border = "#50FA7B",
    dialog_border = "#BD93F9",
    dialog_delete_border = "#FF5555",
    dialog_load_border = "#8BE9FD",
    dialog_content = "#F8F8F2",
    dialog_hint = "#FFB86C"
  }
}

local mock_env_utils = {
  get_icon = function(icons, category)
    return icons.ICONS[category] or "?"
  end,
  get_color = function(colors, category)
    return colors.COLORS[category] or "#FFFFFF"
  end
}

-- Загружаем модуль диалогов
local dialogs = require('utils.dialogs')

print("\n=== ТЕСТ 1: Диалог сохранения workspace ===")
local save_workspace_desc = dialogs.create_save_description(
  mock_wezterm,
  dialogs.DIALOG_TYPES.SAVE_WORKSPACE,
  "my-awesome-workspace",
  mock_environment,
  mock_icons,
  mock_colors,
  mock_env_utils
)

print("✅ Диалог сохранения workspace создан")
print("Пример вывода:")
print(save_workspace_desc)

print("\n=== ТЕСТ 2: Диалог сохранения window ===")
local save_window_desc = dialogs.create_save_description(
  mock_wezterm,
  dialogs.DIALOG_TYPES.SAVE_WINDOW,
  "main_window_123",
  mock_environment,
  mock_icons,
  mock_colors,
  mock_env_utils
)

print("✅ Диалог сохранения window создан")

print("\n=== ТЕСТ 3: Диалог загрузки ===")
local load_desc = dialogs.create_load_description(
  mock_wezterm,
  5,
  mock_environment,
  mock_icons,
  mock_colors,
  mock_env_utils
)

print("✅ Диалог загрузки создан")

print("\n=== ТЕСТ 4: Диалог удаления ===")
local delete_desc = dialogs.create_delete_description(
  mock_wezterm,
  3,
  mock_environment,
  mock_icons,
  mock_colors,
  mock_env_utils
)

print("✅ Диалог удаления создан")

print("\n🎉 Все тесты пройдены успешно!")
print("🚀 Теперь можете тестировать в WezTerm")
