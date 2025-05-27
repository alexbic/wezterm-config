# WezTerm: Модульная конфигурация с индивидуальными фонами

![WezTerm Logo](https://img.shields.io/badge/WezTerm-Configuration-blue?style=for-the-badge&logo=terminal) ![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Windows%20%7C%20Linux-brightgreen?style=for-the-badge) ![License](https://img.shields.io/badge/License-BSD--Clear-orange?style=for-the-badge)

**Модульная конфигурация WezTerm с поддержкой индивидуальных фонов для каждой вкладки**

Проект основан на идее модульной структуры, заимствованной из [wezterm-config-file 千里](https://gitee.com/thousands-of-miles/wezterm-config-file.git) и существенно переработан под собственные задачи.

## 🚀 Возможности

- 🖥️ **Кроссплатформенность** - macOS, Windows, Linux с правильными модификаторами
- ⌨️ **Лидер-клавиша** - Alt+A для специальных функций (750ms timeout)
- 🎨 **Гибкие настройки** - прозрачность и фоны с горячими клавишами
- 📑 **Управление панелями** - split, resize, navigate через key tables
- 🎲 **Случайные фоны** - разные для каждой вкладки с сохранением
- 💾 **Управление сессиями** - save/restore состояний workspace/window/tab
- 🔍 **Smart workspace** - интеграция с zoxide для быстрого переключения
- 🖱️ **Настроенная мышь** - drag, select, scroll с платформенными модификаторами
- 🔔 **Visual Bell** - оранжевая вспышка фона при BEL-сигналах с плавной анимацией

## 📁 Структура проекта

Проект организован по модульному принципу с четким разделением ответственности:

```
wezterm-config/
├── 📄 wezterm.lua                   # Главный файл конфигурации
├── 📁 config/                       # Основные модули конфигурации
│   ├── 📄 general.lua               # Общие настройки
│   ├── 📄 resurrect.lua             # Настройки восстановления сессий
│   ├── 📄 launch.lua                # Настройки запуска
│   ├── 📄 workspace-switcher.lua    # Переключатель рабочих пространств
│   ├── 📁 appearance/               # Модули внешнего вида
│   │   ├── 📄 backgrounds.lua       # Управление фонами
│   │   ├── 📄 events.lua            # События внешнего вида
│   │   └── 📄 transparency.lua      # Настройки прозрачности
│   ├── 📁 bindings/                 # Привязки клавиш и мыши
│   │   ├── 📄 keyboard.lua          # Горячие клавиши
│   │   ├── 📄 mouse.lua             # Управление мышью
│   │   └── 📄 key-tables.lua        # Таблицы клавиш
│   └── 📁 environment/              # Настройки окружения
│       ├── 📄 apps.lua              # Настройки приложений
│       ├── 📄 colors.lua            # Цветовые схемы
│       ├── 📄 fonts.lua             # Настройки шрифтов
│       ├── 📄 locale.lua            # Локализация
│       └── 📄 paths.lua             # Пути и директории
├── 📁 events/                       # Обработчики событий
│   ├── 📄 right-status.lua          # Правый статус
│   ├── 📄 session-status.lua        # Статус сессии
│   └── 📄 tab-title.lua             # Заголовки вкладок
├── 📁 utils/                        # Утилиты и вспомогательные функции
│   ├── 📄 appearance.lua            # Утилиты внешнего вида
│   ├── 📄 platform.lua              # Определение платформы
│   └── 📄 notifications.lua         # Система уведомлений
├── 📁 backdrops/                    # Фоновые изображения для вкладок
│   ├── 🖼️ image1.jpg
│   ├── 🖼️ image2.png
│   └── 🖼️ ...
├── 📁 plugins/                      # Плагины
│   └── 📁 resurrect.wezterm         # Плагин сохранения/восстановления сессий
│       ├── 📄 plugin/
│       └── 📄 ...
└── 📁 scripts/                      # Вспомогательные скрипты
    ├── 📄 install.sh                # Скрипт установки
    └── 📄 backup.sh                 # Скрипт резервного копирования
```