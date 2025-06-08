#!/bin/bash

SOURCE_FILE="$1"
TARGET_LANG="$2"

if [ -z "$SOURCE_FILE" ] || [ -z "$TARGET_LANG" ]; then
    echo "❌ Использование: $0 <source_file.lua> <target_lang_code>"
    exit 1
fi

# Корректное определение исходного языка
SOURCE_LANG=$(grep -m1 'locale\s*=' "$SOURCE_FILE" | sed -n 's/.*locale\s*=\s*"\([a-z][a-z]\)_.*/\1/p')
if [ -z "$SOURCE_LANG" ]; then
  BASENAME=$(basename "$SOURCE_FILE" .lua)
  SOURCE_LANG="${BASENAME:0:2}"
fi

echo "🌐 Универсальный перевод: $SOURCE_LANG → $TARGET_LANG"

# Автоопределение locale
TARGET_LOCALE=$(locale -a 2>/dev/null | grep -i "^${TARGET_LANG}_" | head -1)
[ -z "$TARGET_LOCALE" ] && TARGET_LOCALE="${TARGET_LANG}_${TARGET_LANG^^}.UTF-8"

# Пути
SOURCE_DIR=$(dirname "$SOURCE_FILE")
NEW_FILE="$SOURCE_DIR/${TARGET_LANG}.lua"
TEMPLATE="$SOURCE_DIR/template.lua"

# Временные файлы
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Извлекаем данные
echo "📊 Извлечение данных..."
grep -E '^  [a-zA-Z_]+ = ' "$SOURCE_FILE" | \
    grep -v '^  locale = ' | \
    grep -v '^  name = "' > "$TEMP_DIR/all_lines.txt"

# Разделяем на ключи и значения
awk -F ' = ' '{print $1}' "$TEMP_DIR/all_lines.txt" | sed 's/^  //' > "$TEMP_DIR/keys.txt"
sed 's/^[^=]*= //' "$TEMP_DIR/all_lines.txt" | sed 's/,$//' > "$TEMP_DIR/values.txt"

KEY_COUNT=$(wc -l < "$TEMP_DIR/keys.txt")
echo "🎯 Найдено для перевода: $KEY_COUNT элементов"

# Пакетный перевод
echo "🔄 Пакетный перевод..."
if trans -brief "$SOURCE_LANG:$TARGET_LANG" -i "$TEMP_DIR/values.txt" > "$TEMP_DIR/translated.txt" 2>/dev/null; then
    echo "✅ Перевод выполнен"

    # Получаем название языка (с очисткой от переносов строк)
    TARGET_NAME_LINE=$(grep '^  name = ' "$SOURCE_FILE" | sed 's/.*= "\(.*\)".*/\1/')
    TARGET_NAME=$(echo "$TARGET_NAME_LINE" | trans -brief "$SOURCE_LANG:$TARGET_LANG" 2>/dev/null | tr -d '\n\r' || echo "$TARGET_LANG")

    # Очищаем переводы от лишних переносов строк в конце каждой строки
    sed -i '' 's/[[:space:]]*$//' "$TEMP_DIR/translated.txt"

    # Собираем переведенные ключи
    paste "$TEMP_DIR/keys.txt" "$TEMP_DIR/translated.txt" | while IFS=$'\t' read -r key value; do
        # Очищаем value от лишних пробелов
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Определяем тип значения
        if [[ "$value" =~ ^\{.*\}$ ]]; then
            # Это массив
            echo "  $key = $value,"
        else
            # Это строка - экранируем кавычки
            escaped=$(echo "$value" | sed 's/"/\\"/g')
            echo "  $key = \"$escaped\","
        fi
    done > "$TEMP_DIR/content.txt"

    # Создаем файл
    if [ -f "$TEMPLATE" ]; then
        # Используем template.lua с безопасной заменой
        cp "$TEMPLATE" "$TEMP_DIR/output.lua"
        # Заменяем плейсхолдеры по одному
        sed -i '' "s/{{LANGUAGE_NAME}}/$TARGET_NAME/g" "$TEMP_DIR/output.lua"
        sed -i '' "s/{{LOCALE_CODE}}/$TARGET_LOCALE/g" "$TEMP_DIR/output.lua"
        # Вставляем контент
        sed -i '' "/{{TRANSLATED_KEYS}}/r $TEMP_DIR/content.txt" "$TEMP_DIR/output.lua"
        sed -i '' "/{{TRANSLATED_KEYS}}/d" "$TEMP_DIR/output.lua"
        cp "$TEMP_DIR/output.lua" "$NEW_FILE"
    else
        # Без шаблона
        {
            echo "-- $TARGET_LANG localization"
            echo "return {"
            echo "  locale = \"$TARGET_LOCALE\","
            echo "  name = \"$TARGET_NAME\","
            echo ""
            cat "$TEMP_DIR/content.txt"
            echo "}"
        } > "$NEW_FILE"
    fi

    echo "✅ Создан: $NEW_FILE"

    # Проверка
    if luac -p "$NEW_FILE" 2>/dev/null; then
        echo "✅ Синтаксис корректен"
    else
        echo "❌ Ошибка синтаксиса"
    fi
else
    echo "❌ Ошибка перевода"
fi

