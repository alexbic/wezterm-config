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

# Кроссплатформенная функция sed для in-place редактирования
cross_platform_sed() {
    local pattern="$1"
    local file="$2"
    
    if [ "$PLATFORM" = "macos" ]; then
        sed -i '' "$pattern" "$file"
    else
        sed -i "$pattern" "$file"
    fi
}

# Кроссплатформенная функция sed для пайпов
cross_platform_sed_pipe() {
    if [ "$PLATFORM" = "macos" ]; then
        sed "$1"
    else
        sed "$1"
    fi
}

# Кроссплатформенная функция mktemp
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

# Автоопределение исходного языка из файла (кроссплатформенно)
SOURCE_LANG=$(grep -m1 'locale' "$SOURCE_FILE" | cross_platform_sed_pipe 's/.*"\([a-z][a-z]\)_.*/\1/')
if [ -z "$SOURCE_LANG" ]; then
  BASENAME=$(basename "$SOURCE_FILE" .lua)
  SOURCE_LANG="${BASENAME:0:2}"
fi

# Автоопределение locale назначения
case "$TARGET_LANG" in
    "en") TARGET_LOCALE="en_US.UTF-8"; TARGET_NAME="English" ;;
    "de") TARGET_LOCALE="de_DE.UTF-8"; TARGET_NAME="German" ;;
    "fr") TARGET_LOCALE="fr_FR.UTF-8"; TARGET_NAME="French" ;;
    "es") TARGET_LOCALE="es_ES.UTF-8"; TARGET_NAME="Spanish" ;;
    "it") TARGET_LOCALE="it_IT.UTF-8"; TARGET_NAME="Italian" ;;
    *) TARGET_LOCALE="${TARGET_LANG}_${TARGET_LANG^^}.UTF-8"; TARGET_NAME="Unknown" ;;
esac

SOURCE_DIR=$(dirname "$SOURCE_FILE")
NEW_FILE="$SOURCE_DIR/${TARGET_LANG}.lua"
TEMP_DIR=$(cross_platform_mktemp)
trap "rm -rf $TEMP_DIR" EXIT

echo "🌐 Универсальный перевод ($PLATFORM): $SOURCE_LANG → $TARGET_LANG"
echo "📊 Извлечение данных..."

# Извлекаем ВСЕ переводимые строки (кроме служебных)
grep -E '^  [a-zA-Z_]+ = ".*",' "$SOURCE_FILE" | \
    grep -v '^  locale = ' | \
    grep -v '^  name = ' > "$TEMP_DIR/translatable_lines.txt"

# Разделяем на ключи и значения (кроссплатформенно)
awk -F ' = "' '{print $1}' "$TEMP_DIR/translatable_lines.txt" | cross_platform_sed_pipe 's/^  //' > "$TEMP_DIR/keys.txt"
awk -F ' = "' '{print $2}' "$TEMP_DIR/translatable_lines.txt" | cross_platform_sed_pipe 's/",$//' > "$TEMP_DIR/values.txt"

KEY_COUNT=$(wc -l < "$TEMP_DIR/keys.txt")
echo "🎯 Найдено: $KEY_COUNT элементов для перевода"

# Пакетный перевод
echo "🔄 Пакетный перевод..."
if trans -brief "$SOURCE_LANG:$TARGET_LANG" -i "$TEMP_DIR/values.txt" > "$TEMP_DIR/translated.txt" 2>/dev/null; then
    echo "✅ Перевод выполнен"
    
    # Очистка переведенных значений от кавычек (кроссплатформенно)
    cross_platform_sed 's/^["\x27]*//;s/["\x27]*$//' "$TEMP_DIR/translated.txt"
    
    # Создаем новый файл
    {
        echo "-- $TARGET_NAME localization"
        echo "return {"
        echo "  locale = \"$TARGET_LOCALE\","
        echo "  name = \"$TARGET_NAME\","
        echo ""
        
        # Добавляем переведенные строки
        paste "$TEMP_DIR/keys.txt" "$TEMP_DIR/translated.txt" | while IFS=$'\t' read -r key value; do
            echo "  $key = \"$value\","
        done
        
        # Копируем массивы без изменений
        grep -E '  (days|months) = \{' "$SOURCE_FILE"
        
        echo "}"
    } > "$NEW_FILE"
    
    echo "✅ Создан: $NEW_FILE"
    
    # Проверка синтаксиса
    if command -v luac >/dev/null 2>&1; then
        if luac -p "$NEW_FILE" 2>/dev/null; then
            echo "✅ Синтаксис корректен"
        else
            echo "❌ Ошибка синтаксиса"
        fi
    else
        echo "ℹ️  luac недоступен - проверка синтаксиса пропущена"
    fi
else
    echo "❌ Ошибка перевода"
fi
