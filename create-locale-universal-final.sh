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
cross_platform_sed_inplace() {
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
    local pattern="$1"
    sed "$pattern"
}

# Кроссплатформенная функция создания временной директории
cross_platform_mktemp() {
    if [ "$PLATFORM" = "windows" ]; then
        mktemp -d -t wezterm_locale_XXXXXX
    else
        mktemp -d
    fi
}

# Кроссплатформенная команда перевода
cross_platform_translate() {
    local source_lang="$1"
    local target_lang="$2"
    local input_file="$3"
    local output_file="$4"
    
    if command -v trans >/dev/null 2>&1; then
        trans -brief "$source_lang:$target_lang" -i "$input_file" > "$output_file" 2>/dev/null
    elif command -v translate >/dev/null 2>&1; then
        translate --from "$source_lang" --to "$target_lang" < "$input_file" > "$output_file" 2>/dev/null
    else
        echo "❌ Переводчик не найден. Установите translate-shell"
        return 1
    fi
}

# Проверка аргументов
if [ -z "$SOURCE_FILE" ] || [ -z "$TARGET_LANG" ]; then
    echo "❌ Использование: $0 <source_file.lua> <target_lang_code>"
    exit 1
fi

# Корректное определение исходного языка (кроссплатформенно)
SOURCE_LANG=$(grep -m1 'locale[[:space:]]*=' "$SOURCE_FILE" | cross_platform_sed_pipe -n 's/.*locale[[:space:]]*=[[:space:]]*"\([a-z][a-z]\)_.*/\1/p')
if [ -z "$SOURCE_LANG" ]; then
  BASENAME=$(basename "$SOURCE_FILE" .lua)
  SOURCE_LANG="${BASENAME:0:2}"
fi

echo "🌐 Универсальный перевод ($PLATFORM): $SOURCE_LANG → $TARGET_LANG"

# Правильное определение locale и названий
case "$TARGET_LANG" in
    "en") TARGET_LOCALE="en_US.UTF-8"; TARGET_NAME="English" ;;
    "de") TARGET_LOCALE="de_DE.UTF-8"; TARGET_NAME="German" ;;
    "fr") TARGET_LOCALE="fr_FR.UTF-8"; TARGET_NAME="French" ;;
    "es") TARGET_LOCALE="es_ES.UTF-8"; TARGET_NAME="Spanish" ;;
    "it") TARGET_LOCALE="it_IT.UTF-8"; TARGET_NAME="Italian" ;;
    "pt") TARGET_LOCALE="pt_PT.UTF-8"; TARGET_NAME="Portuguese" ;;
    *) 
        local lang_upper=$(echo "$TARGET_LANG" | tr '[:lower:]' '[:upper:]')
        TARGET_LOCALE="${TARGET_LANG}_${lang_upper}.UTF-8"
        TARGET_NAME="Unknown"
        ;;
esac

# Пути
SOURCE_DIR=$(dirname "$SOURCE_FILE")
NEW_FILE="$SOURCE_DIR/${TARGET_LANG}.lua"

# Временные файлы (кроссплатформенно)
TEMP_DIR=$(cross_platform_mktemp)
trap "rm -rf $TEMP_DIR" EXIT

# Извлекаем данные
echo "📊 Извлечение данных..."
grep -E '^  [a-zA-Z_]+ = ' "$SOURCE_FILE" | \
    grep -v '^  locale = ' | \
    grep -v '^  name = "' > "$TEMP_DIR/all_lines.txt"

# Разделяем на ключи и значения (используем кроссплатформенные функции)
awk -F ' = ' '{print $1}' "$TEMP_DIR/all_lines.txt" | cross_platform_sed_pipe 's/^  //' > "$TEMP_DIR/keys.txt"
cross_platform_sed_pipe 's/^[^=]*= //;s/,$//' "$TEMP_DIR/all_lines.txt" > "$TEMP_DIR/values.txt"

KEY_COUNT=$(wc -l < "$TEMP_DIR/keys.txt")
echo "🎯 Найдено для перевода: $KEY_COUNT элементов"

# Пакетный перевод
echo "🔄 Пакетный перевод..."
if cross_platform_translate "$SOURCE_LANG" "$TARGET_LANG" "$TEMP_DIR/values.txt" "$TEMP_DIR/translated.txt"; then
    echo "✅ Перевод выполнен"

    # АГРЕССИВНАЯ ОЧИСТКА ВСЕХ КАВЫЧЕК (кроссплатформенно)
    cross_platform_sed_inplace 's/^["\x27„""«»][[:space:]]*//' "$TEMP_DIR/translated.txt"
    cross_platform_sed_inplace 's/[[:space:]]*["\x27""«»]$//' "$TEMP_DIR/translated.txt"
    cross_platform_sed_inplace 's/[[:space:]]*$//' "$TEMP_DIR/translated.txt"

    # Собираем переведённые ключи
    paste "$TEMP_DIR/keys.txt" "$TEMP_DIR/translated.txt" | while IFS=$'\t' read -r key value; do
        # Очищаем value от пробелов
        value=$(echo "$value" | cross_platform_sed_pipe 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Определяем тип значения
        if [[ "$value" =~ ^\{.*\}$ ]]; then
            # Массив - вставляем как есть
            echo "  $key = $value,"
        else
            # Строка - добавляем ТОЛЬКО двойные кавычки
            echo "  $key = \"$value\","
        fi
    done > "$TEMP_DIR/content.txt"

    # Создаем файл
    {
        echo "-- $TARGET_NAME localization"
        echo "return {"
        echo "  locale = \"$TARGET_LOCALE\","
        echo "  name = \"$TARGET_NAME\","
        echo ""
        cat "$TEMP_DIR/content.txt"
        echo "}"
    } > "$NEW_FILE"

    echo "✅ Создан: $NEW_FILE"

    # Проверка синтаксиса (если lua доступна)
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
