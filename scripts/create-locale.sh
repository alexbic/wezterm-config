#!/bin/bash

SOURCE_FILE="$1"
TARGET_LANG="$2"

if [ -z "$SOURCE_FILE" ] || [ -z "$TARGET_LANG" ]; then
    echo "❌ Использование: $0 <source_file.lua> <target_lang_code>"
    exit 1
fi

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

# Функция очистки переводов
clean_translation() {
    local text="$1"
    echo "$text" | cross_platform_sed_pipe 's/^["\x27„""«»][[:space:]]*//' | cross_platform_sed_pipe 's/[[:space:]]*["\x27""«»]$//' | cross_platform_sed_pipe 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Функция проверки целостности массива
validate_array() {
    local array_text="$1"
    if [[ "$array_text" =~ ^\{.*\}$ ]] && [[ "$array_text" =~ \{.*\".*\".*\} ]]; then
        echo "valid"
    else
        echo "invalid"
    fi
}

# Функция отображения прогресс-бара
show_progress() {
    local current="$1"
    local total="$2"
    local source_lang="$3"
    local target_lang="$4"
    
    local percent=$((current * 100 / total))
    local filled=$((percent * 20 / 100))
    local empty=$((20 - filled))
    
    local bar=""
    for ((i=1; i<=filled; i++)); do bar+="█"; done
    for ((i=1; i<=empty; i++)); do bar+="░"; done
    
    printf "\r🌐 Создание %s.lua из %s.lua %s [%d/%d]" "$target_lang" "$source_lang" "$bar" "$current" "$total"
}

# Определение исходного языка
SOURCE_LANG=$(grep -m1 'locale[[:space:]]*=' "$SOURCE_FILE" | cross_platform_sed_pipe -n 's/.*locale[[:space:]]*=[[:space:]]*"\([a-z][a-z]\)_.*/\1/p')
if [ -z "$SOURCE_LANG" ]; then
    BASENAME=$(basename "$SOURCE_FILE" .lua)
    SOURCE_LANG="${BASENAME%.*}"
    SOURCE_LANG="${SOURCE_LANG:0:2}"
fi

# Определение целевой локали
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

echo "Создание $TARGET_NAME локализации из $SOURCE_LANG"

# Извлекаем все ключи для перевода
grep -E '^  [a-zA-Z_]+ = ' "$SOURCE_FILE" | \
    grep -v '^  locale = ' | \
    grep -v '^  name = ' > "$TEMP_DIR/all_lines.txt"

TOTAL_KEYS=$(wc -l < "$TEMP_DIR/all_lines.txt")
CURRENT_KEY=0

echo "Найдено ключей для перевода: $TOTAL_KEYS"

# Массив для сбора переведенных строк
TRANSLATED_LINES=()

# Построчная обработка с прогресс-баром
while IFS= read -r line; do
    ((CURRENT_KEY++))
    
    show_progress "$CURRENT_KEY" "$TOTAL_KEYS" "$SOURCE_LANG" "$TARGET_LANG"
    
    key=$(echo "$line" | awk -F ' = ' '{print $1}' | cross_platform_sed_pipe 's/^  //')
    value=$(echo "$line" | cross_platform_sed_pipe 's/^[^=]*= //' | cross_platform_sed_pipe 's/,$//')
    
    if [[ "$value" =~ ^\{.*\}$ ]]; then
        # Это массив - переводим содержимое
        array_content=$(echo "$value" | cross_platform_sed_pipe 's/^{\(.*\)}$/\1/')
        if translated_array=$(trans -brief "$SOURCE_LANG:$TARGET_LANG" "$array_content" 2>/dev/null); then
            full_array="{$translated_array}"
            if [ "$(validate_array "$full_array")" = "valid" ]; then
                TRANSLATED_LINES+=("  $key = $full_array,")
            else
                TRANSLATED_LINES+=("  $key = $value,")
            fi
        else
            TRANSLATED_LINES+=("  $key = $value,")
        fi
    else
        # Это строка - убираем кавычки перед переводом
        clean_value=$(echo "$value" | cross_platform_sed_pipe 's/^"\(.*\)"$/\1/')
        if translated_text=$(trans -brief "$SOURCE_LANG:$TARGET_LANG" "$clean_value" 2>/dev/null); then
            cleaned_text=$(clean_translation "$translated_text")
            TRANSLATED_LINES+=("  $key = \"$cleaned_text\",")
        else
            TRANSLATED_LINES+=("  $key = $value,")
        fi
    fi
    
    sleep 0.1
    
done < "$TEMP_DIR/all_lines.txt"

echo ""
echo "✅ Перевод завершен!"

# Создаем финальный файл
{
    echo "-- $TARGET_NAME localization"
    echo "return {"
    echo "  locale = \"$TARGET_LOCALE\","
    echo "  name = \"$TARGET_NAME\","
    echo ""
    printf '%s\n' "${TRANSLATED_LINES[@]}"
    echo "}"
} > "$NEW_FILE"

echo "📄 Создан файл: $NEW_FILE"

# Проверка синтаксиса
if command -v luac >/dev/null 2>&1; then
    if luac -p "$NEW_FILE" 2>/dev/null; then
        echo "✅ Синтаксис корректен"
    else
        echo "❌ Ошибка синтаксиса"
    fi
fi

# Статистика
SUCCESS_COUNT=$(grep -c '= ".*",' "$NEW_FILE" 2>/dev/null || echo "0")
echo "📊 Статистика: обработано $TOTAL_KEYS ключей, успешно переведено $SUCCESS_COUNT"
