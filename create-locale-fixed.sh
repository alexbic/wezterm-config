#!/bin/bash

SOURCE_FILE="$1"
TARGET_LANG="$2"

if [ -z "$SOURCE_FILE" ] || [ -z "$TARGET_LANG" ]; then
    echo "❌ Использование: $0 <source_file.lua> <target_lang_code>"
    exit 1
fi

# ИСПРАВЛЕНО: Корректное определение исходного языка
SOURCE_LANG=$(grep -m1 'locale[[:space:]]*=' "$SOURCE_FILE" | sed -n 's/.*locale[[:space:]]*=[[:space:]]*"\([a-z][a-z]\)_.*/\1/p')
if [ -z "$SOURCE_LANG" ]; then
  BASENAME=$(basename "$SOURCE_FILE" .lua)
  SOURCE_LANG="${BASENAME:0:2}"
fi

echo "🌐 Универсальный перевод: $SOURCE_LANG → $TARGET_LANG"

# ИСПРАВЛЕНО: Правильное определение locale
case "$TARGET_LANG" in
    "en") TARGET_LOCALE="en_US.UTF-8"; TARGET_NAME="English" ;;
    "de") TARGET_LOCALE="de_DE.UTF-8"; TARGET_NAME="German" ;;
    "fr") TARGET_LOCALE="fr_FR.UTF-8"; TARGET_NAME="French" ;;
    *) TARGET_LOCALE="${TARGET_LANG}_${TARGET_LANG^^}.UTF-8"; TARGET_NAME="Unknown" ;;
esac

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

    # Убираем лишние пробелы/переносы в конце строк перевода
    sed -i 's/[[:space:]]*$//' "$TEMP_DIR/translated.txt"

    # ИСПРАВЛЕНО: Собираем переведённые ключи без двойного экранирования
    paste "$TEMP_DIR/keys.txt" "$TEMP_DIR/translated.txt" | while IFS=$'\t' read -r key value; do
        # Очищаем value от пробелов
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Определяем тип значения
        if [[ "$value" =~ ^\{.*\}$ ]]; then
            # Массив - вставляем как есть
            echo "  $key = $value,"
        else
            # ИСПРАВЛЕНО: Строка - НЕ экранируем кавычки если они уже есть
            if [[ "$value" =~ ^\".*\"$ ]]; then
                # Значение уже в кавычках
                echo "  $key = $value,"
            else
                # Добавляем кавычки
                echo "  $key = \"$value\","
            fi
        fi
    done > "$TEMP_DIR/content.txt"

    # Создаем файл с шаблоном или без
    if [ -f "$TEMPLATE" ]; then
        cp "$TEMPLATE" "$TEMP_DIR/output.lua"
        sed -i "s/{{LANGUAGE_NAME}}/$TARGET_NAME/g" "$TEMP_DIR/output.lua"
        sed -i "s/{{LOCALE_CODE}}/$TARGET_LOCALE/g" "$TEMP_DIR/output.lua"
        sed -i "/{{TRANSLATED_KEYS}}/r $TEMP_DIR/content.txt" "$TEMP_DIR/output.lua"
        sed -i "/{{TRANSLATED_KEYS}}/d" "$TEMP_DIR/output.lua"
        cp "$TEMP_DIR/output.lua" "$NEW_FILE"
    else
        {
            echo "-- $TARGET_NAME localization"
            echo "return {"
            echo "  locale = \"$TARGET_LOCALE\","
            echo "  name = \"$TARGET_NAME\","
            echo ""
            cat "$TEMP_DIR/content.txt"
            echo "}"
        } > "$NEW_FILE"
    fi

    echo "✅ Создан: $NEW_FILE"

    # Проверка синтаксиса
    if luac -p "$NEW_FILE" 2>/dev/null; then
        echo "✅ Синтаксис корректен"
    else
        echo "❌ Ошибка синтаксиса"
    fi
else
    echo "❌ Ошибка перевода"
fi
