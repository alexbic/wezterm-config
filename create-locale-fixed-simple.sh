#!/bin/bash

SOURCE_FILE="$1"
TARGET_LANG="$2"

if [ -z "$SOURCE_FILE" ] || [ -z "$TARGET_LANG" ]; then
    echo "❌ Использование: $0 <source_file.lua> <target_lang_code>"
    exit 1
fi

# Определение платформы
PLATFORM="macos"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    PLATFORM="windows"
fi

# Простое определение исходного языка
SOURCE_LANG=$(grep -m1 'locale' "$SOURCE_FILE" | sed 's/.*"\([a-z][a-z]\)_.*/\1/')
if [ -z "$SOURCE_LANG" ]; then
  BASENAME=$(basename "$SOURCE_FILE" .lua)
  SOURCE_LANG="${BASENAME:0:2}"
fi

echo "🌐 Простой перевод ($PLATFORM): $SOURCE_LANG → $TARGET_LANG"

# Определение locale
case "$TARGET_LANG" in
    "en") TARGET_LOCALE="en_US.UTF-8"; TARGET_NAME="English" ;;
    "de") TARGET_LOCALE="de_DE.UTF-8"; TARGET_NAME="German" ;;

SOURCE_DIR=$(dirname "$SOURCE_FILE")# Временные файлы
SOURCE_DIR=$(dirname "$SOURCE_FILE")TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "📊 Извлечение данных..."

# Упрощенное извлечение - без сложных пайпов
grep -E '^  [a-zA-Z_]+ = ".*",' "$SOURCE_FILE" > "$TEMP_DIR/string_lines.txt"

# Простое разделение
awk -F ' = "' '{print $1}' "$TEMP_DIR/string_lines.txt" | sed 's/^  //' > "$TEMP_DIR/keys.txt"
awk -F ' = "' '{print $2}' "$TEMP_DIR/string_lines.txt" | sed 's/",$//' > "$TEMP_DIR/values.txt"

KEY_COUNT=$(wc -l < "$TEMP_DIR/keys.txt")
echo "🎯 Найдено: $KEY_COUNT элементов"

if [ $KEY_COUNT -gt 0 ]; then
    echo "🔄 Перевод..."
    if trans -brief "$SOURCE_LANG:$TARGET_LANG" -i "$TEMP_DIR/values.txt" > "$TEMP_DIR/translated.txt" 2>/dev/null; then
        echo "✅ Перевод готов"
        
        # Создаем файл
        {
            echo "-- $TARGET_NAME localization"
            echo "return {"
            echo "  locale = \"$TARGET_LOCALE\","
            echo "  name = \"$TARGET_NAME\","
            echo ""
            paste "$TEMP_DIR/keys.txt" "$TEMP_DIR/translated.txt" | while IFS=$'\t' read -r key value; do
                # Убираем все кавычки из value и добавляем свои
                clean_value=$(echo "$value" | sed 's/^["\x27]*//;s/["\x27]*$//')
                echo "  $key = \"$clean_value\","
            done
            echo "}"
        } > "$SOURCE_DIR/${TARGET_LANG}.lua"
        
        echo "✅ Создан: $SOURCE_DIR/${TARGET_LANG}.lua"
    else
        echo "❌ Ошибка перевода"
    fi
else
    echo "❌ Нет строк для перевода"
fi
