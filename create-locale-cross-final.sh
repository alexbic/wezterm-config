#!/bin/bash

SOURCE_FILE="$1"
TARGET_LANG="$2"

# Определение платформы
detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"  
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

PLATFORM=$(detect_platform)

# Кроссплатформенные функции
cross_platform_sed() {
    local pattern="$1"
    local file="$2"
    if [ "$PLATFORM" = "macos" ]; then
        sed -i '' "$pattern" "$file"
    else
        sed -i "$pattern" "$file"
    fi
}

cross_platform_sed_pipe() {
    sed "$1"
}

cross_platform_mktemp() {
    if [ "$PLATFORM" = "windows" ]; then
        mktemp -d -t wezterm_locale_XXXXXX
    else
        mktemp -d
    fi
}

if [ -z "$SOURCE_FILE" ] || [ -z "$TARGET_LANG" ]; then
    echo "❌ Использование: $0 <source_file.lua> <target_lang_code>"
    exit 1
fi

# Автоопределение исходного языка (кроссплатформенно)
SOURCE_LANG=$(grep -m1 'locale' "$SOURCE_FILE" | cross_platform_sed_pipe 's/.*"\([a-z][a-z]\)_.*/\1/')
if [ -z "$SOURCE_LANG" ]; then
  BASENAME=$(basename "$SOURCE_FILE" .lua)
  SOURCE_LANG="${BASENAME:0:2}"
fi

# Определение локали назначения
case "$TARGET_LANG" in
    "en") TARGET_LOCALE="en_US.UTF-8"; TARGET_NAME="English" ;;
    "de") TARGET_LOCALE="de_DE.UTF-8"; TARGET_NAME="German" ;;
    "fr") TARGET_LOCALE="fr_FR.UTF-8"; TARGET_NAME="French" ;;
    *) TARGET_LOCALE="${TARGET_LANG}_${TARGET_LANG^^}.UTF-8"; TARGET_NAME="Unknown" ;;
esac

SOURCE_DIR=$(dirname "$SOURCE_FILE")
NEW_FILE="$SOURCE_DIR/${TARGET_LANG}.lua"
TEMP_DIR=$(cross_platform_mktemp)
trap "rm -rf $TEMP_DIR" EXIT

echo "🌐 Кроссплатформенный перевод ($PLATFORM): $SOURCE_LANG → $TARGET_LANG"

# Извлекаем строки (кроссплатформенно)
grep -E '^  [a-zA-Z_]+ = ".*",' "$SOURCE_FILE" | \
    grep -v '^  locale = ' | \
    grep -v '^  name = ' | \
    grep -v 'days = ' | \
    grep -v 'months = ' > "$TEMP_DIR/strings_only.txt"

grep -E '^  (days|months) = ' "$SOURCE_FILE" > "$TEMP_DIR/arrays.txt"

# Обрабатываем данные (кроссплатформенно)
awk -F ' = "' '{print $1}' "$TEMP_DIR/strings_only.txt" | cross_platform_sed_pipe 's/^  //' > "$TEMP_DIR/keys.txt"
awk -F ' = "' '{print $2}' "$TEMP_DIR/strings_only.txt" | cross_platform_sed_pipe 's/",$//' > "$TEMP_DIR/values.txt"
cross_platform_sed_pipe 's/.*= //;s/,$//' "$TEMP_DIR/arrays.txt" > "$TEMP_DIR/array_values.txt"

echo "🎯 Строк: $(wc -l < "$TEMP_DIR/keys.txt"), Массивов: $(wc -l < "$TEMP_DIR/arrays.txt")"

# Переводы
echo "🔄 Перевод..."
if trans -brief "$SOURCE_LANG:$TARGET_LANG" -i "$TEMP_DIR/values.txt" > "$TEMP_DIR/translated_strings.txt" 2>/dev/null && \
   trans -brief "$SOURCE_LANG:$TARGET_LANG" -i "$TEMP_DIR/array_values.txt" > "$TEMP_DIR/translated_arrays.txt" 2>/dev/null; then
    
    echo "✅ Перевод выполнен"
    
    # Агрессивная очистка переводов (кроссплатформенно)
    cross_platform_sed 's/^["\x27„""«»]*//;s/["\x27„""«»]*,*$//;s/^[[:space:]]*//;s/[[:space:]]*$//' "$TEMP_DIR/translated_strings.txt"
    
    # Создаем файл
    {
        echo "-- $TARGET_NAME localization"
        echo "return {"
        echo "  locale = \"$TARGET_LOCALE\","
        echo "  name = \"$TARGET_NAME\","
        echo ""
        
        paste "$TEMP_DIR/keys.txt" "$TEMP_DIR/translated_strings.txt" | while IFS=$'\t' read -r key value; do
            echo "  $key = \"$value\","
        done
        
        echo ""
        awk '{print $1}' "$TEMP_DIR/arrays.txt" | cross_platform_sed_pipe 's/^  //' > "$TEMP_DIR/array_keys.txt"
        paste "$TEMP_DIR/array_keys.txt" "$TEMP_DIR/translated_arrays.txt" | while IFS=$'\t' read -r key value; do
            echo "  $key = $value,"
        done
        
        echo "}"
    } > "$NEW_FILE"
    
    echo "✅ Создан: $NEW_FILE"
    
    if command -v luac >/dev/null 2>&1; then
        if luac -p "$NEW_FILE" 2>/dev/null; then
            echo "✅ Синтаксис корректен"
        else
            echo "❌ Ошибка синтаксиса"
        fi
    fi
else
    echo "❌ Ошибка перевода"
fi
