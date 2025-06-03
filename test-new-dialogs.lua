#!/usr/bin/env lua

-- Тест новой системы диалогов
local wezterm = require('wezterm')
local dialogs = require('utils.dialogs')
local environment = require('config.environment')
local icons = require('config.environment.icons')
local colors = require('config.environment.colors')
local env_utils = require('utils.environment')

print("🧪 Тестирование новой системы диалогов...")

-- Тест диалога сохранения workspace
print("\n=== ТЕСТ 1: Диалог сохранения workspace ===")
local save_workspace_desc = dialogs.create_save_description(
  wezterm,
  dialogs.DIALOG_TYPES.SAVE_WORKSPACE,
  "my-awesome-workspace",
  environment,
  icons,
  colors,
  env_utils
)

print("Создан диалог сохранения workspace")

-- Тест диалога сохранения window
print("\n=== ТЕСТ 2: Диалог сохранения window ===")
local save_window_desc = dialogs.create_save_description(
  wezterm,
  dialogs.DIALOG_TYPES.SAVE_WINDOW,
  "main_window_123",
  environment,
  icons,
  colors,
  env_utils
)

print("Создан диалог сохранения window")

-- Тест диалога загрузки
print("\n=== ТЕСТ 3: Диалог загрузки сессии ===")
local load_desc = dialogs.create_load_description(
  wezterm,
  5,
  environment,
  icons,
  colors,
  env_utils
)

print("Создан диалог загрузки")

print("\n✅ Все тесты пройдены успешно!")
print("🚀 Теперь можете тестировать в WezTerm через Alt+A → s → s (сохранение workspace)")
