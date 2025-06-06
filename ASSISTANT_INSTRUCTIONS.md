# 🤖 ИНСТРУКЦИИ ДЛЯ AI АССИСТЕНТА - WEZTERM CONFIG PROJECT

## 👤 КОНТЕКСТ ОПЕРАТОРА
- **Имя оператора:** Александр
- **Язык общения:** Русский
- **Платформа:** macOS
- **Уровень экспертизы:** Средний (WezTerm)
- **Приоритет работы:** СКОРОСТЬ решения задач
- **Личные предпочтения:** Любит эмодзи, дотошный, ценит порядок

## ⚙️ НАСТРОЙКИ ДИАЛОГА
- **Тип ассистента:** Claude
- **Реальный лимит:** ~35 сообщений (НЕ 100!)
- **Порог подготовки к завершению:** 28+ сообщений (~80%)
- **Формат commit:** Подробный с историей чата
- **Стиль взаимодействия:** Краткие команды + проактивные предложения

## 📊 АВТОМАТИЧЕСКИЙ КОНТРОЛЬ ДИАЛОГА
**ОБЯЗАТЕЛЬНО:**
- Вести счетчик: #X/35 с первого сообщения
- При 15 сообщениях: первое предупреждение (45%)
- При 28 сообщениях: подготовка к завершению (80%)
- Обращаться по имени: "Александр"
- Адаптировать под средний уровень WezTerm
- Команды для macOS

## 🚨 КРИТИЧЕСКИЕ ПРАВИЛА (ПРИОРИТЕТ #1)

### 🛡️ ЗОЛОТОЕ ПРАВИЛО ВЫДАЧИ КОМАНД
- ВСЕГДА выдавать команды ПОСЛЕДОВАТЕЛЬНО (одна за другой)
- ЖДАТЬ результата от пользователя перед следующей
- АНАЛИЗИРОВАТЬ результат перед продолжением
- НЕ выдавать сложные && цепочки команд
- НЕ переходить к следующему этапу без подтверждения

**ПРАВИЛЬНО:**
    echo "=== ЭТАП ==="
    команда1

**НЕПРАВИЛЬНО:**
    echo "этап" && команда1 && команда2 && echo "SUCCESS"

### 🔧 ПРАВИЛО БЛОКОВ КОМАНД
**ФОРМАТ ЕДИНОГО БЛОКА:**
    # Собираем данные в переменные
    RESULT1=$(команда1)
    RESULT2=$(команда2)
    
    # Красиво выводим результаты
    echo "=== ЗАГОЛОВОК БЛОКА ==="
    echo "$RESULT1"
    echo ""
    echo "=== ДРУГОЙ БЛОК ==="
    echo "$RESULT2"

**ПРИНЦИПЫ:**
- ВСЕ команды в ОДНОМ блоке (сбор + вывод)
- Каждая команда предваряется комментарием
- Финальный вывод структурирован заголовками
- Пользователь выполняет весь блок целиком, показывает результат

### 🛡️ ПРАВИЛО ECHO СИНТАКСИСА (КРИТИЧНО)
- ❌ НИКОГДА: echo "текст!" (восклицательный знак перед закрывающей кавычкой)
- ✅ ПРАВИЛЬНО: echo "текст" или echo "текст."
- Причина: Ломает bash синтаксис, вызывает dquote> зависание

### 🛡️ ПРАВИЛО MARKDOWN СИНТАКСИСА (КРИТИЧНО)
- ❌ НИКОГДА: Тройные кавычки внутри блоков кода
- ❌ Конструкция: ```bash внутри heredoc
- ✅ ПРАВИЛЬНО: Отступы (4 пробела) для примеров кода
- Причина: Ломает Markdown парсинг

### 🎨 ПРАВИЛО ЭМОДЗИ В ДИАЛОГЕ
- ✅ Александр любит эмодзи - украшать заголовки и разделы
- ❌ НЕ использовать эмодзи перед кавычками в командах
- ✅ Использовать в заголовках блоков и описаниях
- ✅ Декорировать разделы для улучшения читаемости

### 🔍 ДИАГНОСТИКА ПЕРЕД ДЕЙСТВИЕМ
ВСЕГДА перед sed/исправлениями:
    RESULT=$(grep -n "проблема" файл)
    echo "$RESULT"
- Анализировать контекст и причину
- Только потом предлагать исправления

### ⚙️ СИСТЕМЫ ЛОКАЛИЗАЦИИ WEZTERM
КРИТИЧНЫЕ ПРАВИЛА:
- environment.locale.t.key - статическая таблица данных
- ЗАПРЕЩЕНО: environment.locale.t("key") или environment.locale.t(key)
- При ошибках "attempt to call a table value" - ищи старые вызовы функций
- Проверка: grep -r "environment\.locale\.t(" .

### 🎯 ПРАВИЛО: ЧИСТЫЕ ЛОКАЛИ (КРИТИЧНО)
ПРИНЦИП: Файлы локалей = ТОЛЬКО чистый текст, БЕЗ:
- ❌ Иконок (🌍, 📍, 🔧)
- ❌ Форматирования (%s внутри)
- ❌ ANSI цветов
- ❌ Специальных символов

ВСЕ ФОРМАТИРОВАНИЕ через wezterm.format:
- ✅ Иконки из config/environment/icons.lua
- ✅ Цвета из config/environment/colors.lua
- ✅ %s подстановки в коде
- ✅ Структура через utils/environment.lua

### 🛡️ FALLBACK СИСТЕМА ДЛЯ UI
ВСЕГДА в диалогах создавать fallback функции:
    local FALLBACK_TEXTS = { key = "текст" }
    local function safe_get_text(key, ...)
      return (environment.locale.t[key]) or FALLBACK_TEXTS[key] or key
    end

## 🚨 ПАТТЕРНЫ ОШИБОК WEZTERM (ИЗ ПРАКТИКИ)

### 🔴 СИНТАКСИЧЕСКИЕ ОШИБКИ

#### АВТОПЕРЕВОД ПОРТИТ ФОРМАТИРОВАНИЕ
Проблема: Google Translate %s→%S, %d→%D
Решение: sed 's/%S/%s/g; s/%D/%d/g' после автоперевода
Проверка: grep -E "%[A-Z]" файл.lua

#### ПРЕЖДЕВРЕМЕННОЕ ЗАКРЫТИЕ LUA БЛОКОВ
Проблема: Добавление новых ключей через cat >> создает { } в середине файла
Симптомы: luac: file.lua:XX: <eof> expected near 'key_name'
Диагностика: grep -n "^}" file.lua покажет преждевременные закрытия
Решение: sed -i 'XXd' file.lua (удалить строку) + echo "}" >> file.lua
Проверка: luac -p file.lua после исправления

#### ДУБЛИРОВАНИЕ КЛЮЧЕЙ ЛОКАЛИЗАЦИИ
Проблема: Копирование блоков с дублированными ключами
Диагностика: grep -o '^  [a-zA-Z_]*' file.lua | sort | uniq -d
Решение: sed удаление дублированного блока + luac -p проверка

#### НЕПРАВИЛЬНЫЕ ОБРАЩЕНИЯ К ИКОНКАМ
Проблема: environment.icons.t."key" вместо environment.icons.t.key
Симптомы: <name> expected near '"key"'
Диагностика: grep -r 'environment\.icons\.t\."' . --include="*.lua"
Решение: sed 's/environment\.icons\.t\."key"/environment.icons.t.key/g'
Проверка: luac -p после массовых замен

### 🔴 АРХИТЕКТУРНЫЕ ОШИБКИ

#### ИЗМЕНЕНИЕ БАЗОВОЙ АРХИТЕКТУРЫ БЕЗ АНАЛИЗА ЗАВИСИМОСТЕЙ
Проблема: Изменение структуры без анализа всех мест использования
Симптомы: массовые syntax error, attempt to index nil value
Диагностика: grep -r "старая_функция" . --include="*.lua" ПЕРЕД изменениями
Решение: Массовая замена всех зависимостей одновременно

ОБЯЗАТЕЛЬНЫЙ АЛГОРИТМ для архитектурных изменений:
1. grep -r "старый_паттерн" . --include="*.lua"
2. Подсчитать количество мест использования
3. Подготовить команды замены для ВСЕХ мест
4. Выполнить замены массово
5. Проверить синтаксис всех затронутых файлов

#### ЦИКЛИЧЕСКИЕ ЗАВИСИМОСТИ CONFIG
Проблема: config/ модули импортируют wezterm напрямую
Решение: config/=данные, utils/=функции, параметры передавать
Правило: config/ НЕ должен содержать require('wezterm')

#### КЭШ РАССИНХРОНИЗАЦИЯ
Проблема: Ключи в ru.lua, но НЕ в config/environment/locale.lua
Решение: env_utils.rebuild_locale_cache_file() после изменений
Проверка: grep "новый_ключ" config/environment/locale.lua

#### ОТСУТСТВИЕ ЭКСПОРТА В INIT.LUA
Проблема: config/environment/init.lua не экспортирует все модули
Симптомы: attempt to index nil value (field 'icons')
Решение: Добавить require и экспорт в init.lua
Проверка: cat config/environment/init.lua

#### NIL В STRING.FORMAT
Проблема: string.format(text, nil) в UI диалогах
Решение: safe_get_text() функция с fallback
Паттерн: text = env.locale.t.key or FALLBACK_TEXTS[key] or key

### 🔴 ПОВЕДЕНЧЕСКИЕ ПАТТЕРНЫ ОШИБОК

#### ЗАВИСАНИЕ ВНЕШНИХ КОМАНД
Проблема: wezterm команды и автоперевод зависают, открывают окна
Решение: Использовать --config-file без дополнительных флагов
Проверка: НЕ использовать --no-auto-connect (не существует)

#### ЦИКЛИЧЕСКИЕ ЗАДАЧИ БЕЗ ПРОГРЕССА
Проблема: Возврат к исходной точке без решения проблемы
Симптомы: "Мы прошли по кругу", функциональность работала с начала
Решение: Четко фиксировать прогресс, избегать повторения проверок

#### НАРУШЕНИЕ ЗОЛОТОГО ПРАВИЛА КОМАНД
Проблема: Выдача сложных команд без ожидания результата
Симптомы: Пользователь жалуется "не читаешь инструкции", "следуй правилам"
Решение: СТРОГО одна команда → ждать результат → анализ → следующая команда
Проверка: Каждое сообщение = максимум ОДНА команда или ОДИН блок сбора данных

#### НЕТОЧНОСТЬ В ДИАГНОСТИКЕ НОМЕРОВ СТРОК
Проблема: Поиск неправильных номеров строк без предварительной проверки
Симптомы: "sed: bad flag", изменения не применяются
Решение: ВСЕГДА grep -n "паттерн" файл ПЕРЕД sed изменениями
Проверка: Номер строки должен быть подтвержден перед исправлением

#### НАРУШЕНИЕ ПРОТОКОЛА ЗАВЕРШЕНИЯ ЧАТА
Проблема: Переход сразу к commit без анализа паттернов и обновления ROADMAP
Симптомы: "Нарушаешь порядок работы", "критически важная последовательность"
Решение: СТРОГО следовать алгоритму 28-35: паттерны → ROADMAP → инструкции → commit
Проверка: При 28+ сообщениях - начинать с анализа паттернов

#### КРИТИЧЕСКАЯ ОШИБКА ECHO СИНТАКСИСА (ЧАТ #31)
Проблема: echo "текст!" вызывает dquote> зависание (4 раза в чате #31)
Симптомы: Пользователь ругается "красными буквами написано", "надо мной издеваешься"
Решение: ВСЕГДА echo "текст" или echo "текст." БЕЗ ! перед кавычкой
Проверка: Каждая echo команда должна проверяться на ! перед "

## 📊 АЛГОРИТМ ЗАВЕРШЕНИЯ ЧАТОВ (28-35 сообщений)

### 1️⃣ АНАЛИЗ ПАТТЕРНОВ (28-30)
- Собрать новые найденные паттерны ошибок
- Выявить архитектурные принципы
- Документировать технические решения

### 2️⃣ ОБНОВЛЕНИЕ ИНСТРУКЦИЙ (30-32)
- Дополнение ASSISTANT_INSTRUCTIONS.md новыми правилами
- Систематизация всех правил
- Удаление дублирования и противоречий

### 3️⃣ ОБНОВЛЕНИЕ ROADMAP (32-33)
- Конкретные задачи для следующего чата
- Приоритеты и файлы для работы
- Систематизация выполненного для README

### 4️⃣ COMMIT И GITHUB (34-35)
- Подготовка COMMIT_MESSAGE.md с историей чата
- git add . && git commit -F COMMIT_MESSAGE.md
- git push origin main

## 🎯 МЕТА-ПРАВИЛА ДЛЯ AI

### ПРИОРИТЕТЫ ПРИ КОНФЛИКТЕ ПРАВИЛ
1. **Критические правила** > все остальное (поломка проекта)
2. **Скорость** > тщательность (по запросу Александра)
3. **Безопасность** > красота кода
4. **Работающее решение** > идеальное решение

### ИСКЛЮЧЕНИЯ ИЗ ПРАВИЛ
- При критических ошибках архитектуры можно нарушить план
- При обнаружении значительно лучшего решения - предложить немедленно
- При неясности - действовать в сторону безопасности + предложить альтернативу

### СТИЛЬ ОБЩЕНИЯ С АЛЕКСАНДРОМ
- Всегда обращаться по имени
- Украшать диалог эмодзи (он любит)
- Быть дотошным и следить за порядком
- Приоритет: СКОРОСТЬ решения задач
- Фиксировать прогресс для избежания циклических задач

---
Создано для Александра - WezTerm локализация
Обновлено в чате #31 - систематизированы паттерны ошибок, убрано дублирование
