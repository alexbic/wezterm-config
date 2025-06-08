#!/bin/bash

###############################################################################
# Скрипт create-locale.sh
# Назначение: Автоматически создать файл локализации .lua на нужном языке
# из другого lua-файла с переводами, используя CLI-интерфейс переводчика `trans`.
#
# Поддержка кросс-платформ: macOS, Linux, Windows (через Git Bash)
#
# Аргументы:
#   $1 — путь до исходного lua-файла (например, en.lua)
#   $2 — целевой язык (например, fr, de, es)
#
# Использование:
#   ./scripts/create-locale.sh ./locales/en.lua fr
###############################################################################

# ========== 1. ПАРАМЕТРЫ ВХОДА ==========
SOURCE_FILE="$1"     # Путь к исходному lua-файлу (en.lua)
TARGET_LANG="$2"     # Целевой язык (двухбуквенный код)

# Проверка обязательных параметров
if [ -z "$SOURCE_FILE" ] || [ -z "$TARGET_LANG" ]; then
    echo "❌ Использование: $0 <source_file.lua> <target_lang_code>"
    exit 1
fi

# ========== 2. ОБНАРУЖЕНИЕ ПЛАТФОРМЫ ==========
detect_platform() {
    # Функция определяет операционную систему (macOS, Linux, Windows)
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

# ========== 3. АДАПТАЦИЯ sed и mktemp ДЛЯ РАЗНЫХ ОС ==========
cross_platform_sed() {
    # Выполняет замену текста в файле (in-place), с учётом особенностей macOS
    local pattern="$1"
    local file="$2"
    if [ "$PLATFORM" = "macos" ]; then
        sed -i '' "$pattern" "$file"
    else
        sed -i "$pattern" "$file"
    fi
}

cross_platform_mktemp() {
    # Создаёт временную директорию, универсально для всех ОС
    if [ "$PLATFORM" = "windows" ]; then
        mktemp -d -t wezterm_locale_XXXXXX
    else
        mktemp -d
    fi
}

# ========== 4. ПУТИ К ФАЙЛАМ ==========
SCRIPT_DIR=$(dirname "$0")                    # Путь к директории со скриптом
CONFIG_DIR=$(dirname "$SCRIPT_DIR")           # Корень проекта
LOCALE_CACHE="$CONFIG_DIR/config/environment/locale.lua"  # Файл кеша с переводами

# ========== 5. ФУНКЦИЯ ЛОКАЛИЗАЦИИ СООБЩЕНИЙ ==========
get_localized_message() {
    # Показывает сообщение по ключу, сначала пытаясь найти в locale.lua
    local key="$1"
    shift
    local args=("$@")
    if [ -f "$LOCALE_CACHE" ]; then
        local message=$(grep "^  $key = " "$LOCALE_CACHE" | sed 's/.*= "\(.*\)",$/\1/')
        if [ -n "$message" ]; then
            printf "$message" "${args[@]}"
            return
        fi
    fi

    # Запасные сообщения (если нет locale.lua)
    case "$key" in
        "locale_creation_start") printf "🌐 Creating %s locale from %s" "${args[@]}" ;;
        "locale_keys_found") printf "🎯 Found: %d elements for translation" "${args[@]}" ;;
        "locale_translation_progress") printf "🌐 Translating %s.lua from %s.lua %s [%d/%d keys]" "${args[@]}" ;;
        "locale_translation_complete") printf "✅ Translation completed" ;;
        "locale_translation_error") printf "❌ Translation error" ;;
        "locale_syntax_check") printf "✅ %s localization created: %s" "${args[@]}" ;;
        "locale_syntax_error") printf "❌ Syntax error in %s" "${args[@]}" ;;
        "locale_template_not_found") printf "❌ Template not found: %s" "${args[@]}" ;;
        "locale_no_strings") printf "❌ No strings for translation" ;;
        *) printf "%s" "$key" ;;
    esac
}

# ========== 6. ВИЗУАЛЬНЫЙ ПРОГРЕСС-БАР ==========
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
    printf "\r"
    get_localized_message "locale_translation_progress" \
        "$target_lang" "$source_lang" "$bar" "$current" "$total"
}

# ========== 7. ВЫЧИСЛЕНИЕ ЯЗЫКА ИМПОРТА ==========
SOURCE_LANG=$(grep -m1 'locale' "$SOURCE_FILE" \
    | sed -n 's/.*"\([a-z][a-z]\)_.*/\1/p')
if [ -z "$SOURCE_LANG" ]; then
    BASENAME=$(basename "$SOURCE_FILE" .lua)
    SOURCE_LANG="${BASENAME:0:2}"
fi

# ========== 8. КАРТА КОДОВ ЯЗЫКОВ ==========
case "$TARGET_LANG" in
    "en") TARGET_LOCALE="en_US.UTF-8"; TARGET_NAME="English" ;;
    "de") TARGET_LOCALE="de_DE.UTF-8"; TARGET_NAME="German" ;;
    "fr") TARGET_LOCALE="fr_FR.UTF-8"; TARGET_NAME="French" ;;
    "es") TARGET_LOCALE="es_ES.UTF-8"; TARGET_NAME="Spanish" ;;
    *) TARGET_LOCALE="${TARGET_LANG}_${TARGET_LANG^^}.UTF-8"; TARGET_NAME="Unknown" ;;
esac

SOURCE_DIR=$(dirname "$SOURCE_FILE")
NEW_FILE="$SOURCE_DIR/${TARGET_LANG}.lua"
TEMPLATE="$SOURCE_DIR/template.lua"
TEMP_DIR=$(cross_platform_mktemp)
trap "rm -rf $TEMP_DIR" EXIT

echo

# ========== 9. ИЗВЛЕКАЕМ ВСЕ ПЕРЕВОДИМЫЕ СТРОКИ ==========
grep -E '^  [a-zA-Z_]+ = ".*",' "$SOURCE_FILE" \
    | grep -v '^  locale = ' \
    | grep -v '^  name = ' > "$TEMP_DIR/string_lines.txt"

TOTAL_KEYS=$(wc -l < "$TEMP_DIR/string_lines.txt")
echo

# ========== 10. ПЕРЕВОД КЛЮЧЕЙ ==========
if [ "$TOTAL_KEYS" -gt 0 ]; then
    TRANSLATED_LINES=()
    CURRENT_KEY=0
    TRANSLATION_SUCCESS=true

    while IFS= read -r line; do
        ((CURRENT_KEY++))
        show_progress "$CURRENT_KEY" "$TOTAL_KEYS" "$SOURCE_LANG" "$TARGET_LANG"

        # Разделение на ключ и значение
        key=$(echo "$line" | awk -F ' = "' '{print $1}' | sed 's/^  //')
        value=$(echo "$line" | awk -F ' = "' '{print $2}' | sed 's/",$//')

        # Перевод с помощью trans
        if translated_text=$(trans -brief "$SOURCE_LANG:$TARGET_LANG" "$value" 2>/dev/null); then
            cleaned_text=$(echo "$translated_text" | tr -d '"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            TRANSLATED_LINES+=("  $key = \"$cleaned_text\",")
        else
            TRANSLATED_LINES+=("  $key = \"$value\",")
            TRANSLATION_SUCCESS=false
        fi

        sleep 0.1
    done < "$TEMP_DIR/string_lines.txt"

    echo

    # Сообщение об успехе/ошибке
    if $TRANSLATION_SUCCESS; then
        get_localized_message "locale_translation_complete"
    else
        get_localized_message "locale_translation_error"
    fi
    echo

    # ========== 11. СОЗДАНИЕ ФАЙЛА ПЕРЕВОДА ==========
    printf '%s\n' "${TRANSLATED_LINES[@]}" > "$TEMP_DIR/content.txt"

    if [ -f "$TEMPLATE" ]; then
        cp "$TEMPLATE" "$TEMP_DIR/output.lua"
        cross_platform_sed "s/{{LANGUAGE_NAME}}/$TARGET_NAME/g" "$TEMP_DIR/output.lua"
        cross_platform_sed "s/{{LOCALE_CODE}}/$TARGET_LOCALE/g" "$TEMP_DIR/output.lua"
        cross_platform_sed "/{{TRANSLATED_KEYS}}/r $TEMP_DIR/content.txt" "$TEMP_DIR/output.lua"
        cross_platform_sed "/{{TRANSLATED_KEYS}}/d" "$TEMP_DIR/output.lua"

        if $TRANSLATION_SUCCESS; then
            cross_platform_sed "/name = \"$TARGET_NAME\",/a\\
  translation_completed = true," "$TEMP_DIR/output.lua"
        else
            cross_platform_sed "/name = \"$TARGET_NAME\",/a\\
  translation_completed = false," "$TEMP_DIR/output.lua"
        fi

        cp "$TEMP_DIR/output.lua" "$NEW_FILE"

        # ========== 12. ПРОВЕРКА СИНТАКСИСА LUA ==========
        if luac -p "$NEW_FILE" 2>/dev/null; then
            get_localized_message "locale_syntax_check" "$TARGET_NAME" "$NEW_FILE"
            echo
        else
            get_localized_message "locale_syntax_error" "$NEW_FILE"
            echo
            exit 1
        fi
    else
        get_localized_message "locale_template_not_found" "$TEMPLATE"
        echo
        exit 1
    fi
else
    get_localized_message "locale_no_strings"
    echo
    exit 1
fi
