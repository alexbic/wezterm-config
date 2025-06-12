# 🗺️ ROADMAP - ЧАТ #47 ПЛАН

## 📍 ТЕКУЩЕЕ СОСТОЯНИЕ (после отката к началу чата #46):
- ❌ F9 локализация: ошибка id=[nil] строка 246  
- ❌ F10 центр управления: ошибка meta=nil строка 163
- ❌ F8: нет реакции на нажатие
- ✅ Shift+F12 отладка: работает нормально

## 🎯 ПРИОРИТЕТ 1: ИСПРАВЛЕНИЕ СУЩЕСТВУЮЩИХ ДИАЛОГОВ
1. **F9 locale manager:** Исправить ошибку id=[nil] в locale_state_provider.handle_action
2. **F10 settings manager:** Исправить ошибка meta=nil в settings_config структуре
3. **F8:** Восстановить utils/dialogs.lua.show_debug_panel вместо заглушки
4. **Универсальные диалоги:** Завершить миграцию на build_inputselector

## 🎯 ПРИОРИТЕТ 2: СИСТЕМА DEBUG ЛОГИРОВАНИЯ ДЛЯ НЕНАЗНАЧЕННЫХ КЛАВИШ

### КОНЦЕПЦИЯ (начато в чате #46):
**Цель:** F-клавиши без функций показывают debug сообщение о своей доступности

**Архитектура:**
- **Локализация:** Ключ `unused_key_not_used = "не используется, доступна для новых функций"`
- **Функция:** `M.create_unused_key_action(wezterm, key_name)` в utils/bindings.lua
- **Логика:** `debug.log(wezterm, locale.t, "bindings", key, composed_message)`
- **Условие:** Логирование только при `DEBUG_CONFIG.bindings = true`
- **Сообщение:** "F8 → не используется, доступна для новых функций"

**Целевые клавиши:** F5, F6, F7, F8 (и другие свободные)

### ПОСЛЕДОВАТЕЛЬНОСТЬ РЕАЛИЗАЦИИ:
1. **Локализация:** ru.lua.master → ru.lua → cache regeneration
2. **Функция:** Создание в utils/bindings.lua с emergency backup
3. **Тестирование:** luac -p + require('wezterm') проверки
4. **Назначение:** Обновление keyboard.lua (ТОЛЬКО после тестов функции)

## 🎯 ПРИОРИТЕТ 3: НОВЫЕ ДИАЛОГИ ПО УНИВЕРСАЛЬНОЙ СХЕМЕ

### АРХИТЕКТУРА УНИВЕРСАЛЬНЫХ ДИАЛОГОВ (из чата #45):
- **config/dialogs/name.lua:** ТОЛЬКО данные (meta, main_items, service_items)
- **utils/dialogs.lua:** M.build_inputselector(wezterm, config, state_provider)
- **state_provider:** Логика с возвратом { action = "refresh/exit/none" }

### ГОТОВЫЕ ШАБЛОНЫ:
- debug-manager.lua: Панель отладки модулей
- locale-manager.lua: Управление языками  
- settings-manager.lua: Главное меню F10

### НАЗНАЧЕНИЕ НА ГОРЯЧИЕ КЛАВИШИ:
- **F8:** Новый диалог (после освобождения от заглушки)
- **F9:** Исправленный locale manager
- **F10:** Исправленный settings manager через build_inputselector

## 🚨 УРОКИ БЕЗОПАСНОСТИ ИЗ ЧАТА #46:
- **Последовательность:** utils/ → test → keyboard.lua (КРИТИЧНО)
- **Emergency backup:** Перед ЛЮБЫМИ изменениями utils/bindings.lua
- **C stack overflow:** = немедленно git reset --hard origin/main
- **Локализация:** Эталон→копия→кэш цепочка работает корректно

## 📋 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ ЧАТА #47:
- ✅ Все диалоги F8/F9/F10/Shift+F12 работают без ошибок
- ✅ Универсальная система диалогов полностью функциональна
- ✅ Debug логирование для неназначенных клавиш реализовано
- ✅ Готовность к Release 1.0 конфигурации
