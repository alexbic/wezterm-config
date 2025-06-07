#!/bin/bash
# Создание локали с пакетным переводом (РАБОЧАЯ ВЕРСИЯ)

# Функция прогресс-бара
show_progress() {
    local duration=$1
    local message="$2"
    echo -n "$message "
    for i in $(seq 1 $duration); do
        echo -n "."
        sleep 1
    done
    echo ""
}
SOURCE_FILE="$1"
TARGET_LANG="$2"
VERBOSE=""

for arg in "$@"; do
    case $arg in
        -v|--verbose) VERBOSE="true" ;;
    esac
done

if [ -z "$SOURCE_FILE" ] || [ -z "$TARGET_LANG" ]; then
    echo "❌ Использование: $0 <source_file> <target_lang> [-v]"
    exit 1
fi

if [ ! -f "$SOURCE_FILE" ]; then
    echo "❌ Исходный файл не найден: $SOURCE_FILE"
    exit 1
fi

# Функции определения locale и названий
get_locale_for_language() {
    case "$1" in
        "en") echo "en_US.UTF-8" ;;
        "de") echo "de_DE.UTF-8" ;;
        "ru") echo "ru_RU.UTF-8" ;;
        "fr") echo "fr_FR.UTF-8" ;;
        *) echo "${1}_$(echo "$1" | tr '[:lower:]' '[:upper:]').UTF-8" ;;
    esac
}

get_language_name() {
    case "$1" in
        "en") echo "English" ;;
        "de") echo "German" ;;
        "ru") echo "Русский" ;;
        "fr") echo "French" ;;
        *) echo "Unknown" ;;
    esac
}

SOURCE_DIR=$(dirname "$SOURCE_FILE")
NEW_FILE="$SOURCE_DIR/${TARGET_LANG}.lua"
TARGET_LOCALE=$(get_locale_for_language "$TARGET_LANG")
TARGET_NAME=$(get_language_name "$TARGET_LANG")

echo "🌐 Создание $TARGET_NAME локали"

# Создаем файл и заменяем метаданные
cp "$SOURCE_FILE" "$NEW_FILE"
sed -i '' "s/ru_RU\.UTF-8/$TARGET_LOCALE/g" "$NEW_FILE"
sed -i '' "s/\"Русский\"/\"$TARGET_NAME\"/g" "$NEW_FILE"
sed -i '' "s/-- Русская локализация.*/-- $TARGET_NAME localization/" "$NEW_FILE"

# Добавляем TODO маркеры
sed -i '' 's/ = "\([^"]*[а-яё][^"]*\)"/ = "\1", -- TODO:translate/gi' "$NEW_FILE"

# СБОР ДАННЫХ ДЛЯ ПАКЕТНОГО ПЕРЕВОДА
KEYS=()
RUSSIAN_TEXTS=()

while IFS= read -r line; do
    if echo "$line" | grep "TODO:translate" >/dev/null; then
        key_name=$(echo "$line" | sed 's/^[[:space:]]*\([^[:space:]]*\) = .*/\1/')
        russian_text=$(echo "$line" | sed 's/.*= "\(.*\)" -- TODO:translate/\1/')
        
        if [ -n "$russian_text" ] && [ "$russian_text" != "$line" ]; then
            KEYS+=("$key_name")
            RUSSIAN_TEXTS+=("$russian_text")
        fi
    fi
done < "$NEW_FILE"

TOTAL_KEYS=${#KEYS[@]}
echo "🎯 Найдено: $TOTAL_KEYS ключей"

if [ $TOTAL_KEYS -eq 0 ]; then
    echo "✅ Нет ключей для перевода"
    exit 0
fi

# Подготовка файлов
BATCH_INPUT=$(mktemp)
BATCH_OUTPUT=$(mktemp)

for russian_text in "${RUSSIAN_TEXTS[@]}"; do
    echo "$russian_text" >> "$BATCH_INPUT"
done

echo "🔄 Пакетный перевод $TOTAL_KEYS строк"
show_progress 3 "⏳ Отправка данных на сервер"
# ВЫПОЛНЯЕМ ПАКЕТНЫЙ ПЕРЕВОД
if gtimeout 120 trans -brief "ru:${TARGET_LANG}" -i "$BATCH_INPUT" > "$BATCH_OUTPUT" 2>/dev/null; then
    echo "✅ Пакетный перевод выполнен!"
    
    # ЧИТАЕМ РЕЗУЛЬТАТЫ ПЕРЕВОДА
    TRANSLATIONS=()
    while IFS= read -r line; do
        clean_line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/,$//')
        TRANSLATIONS+=("$clean_line")
    done < "$BATCH_OUTPUT"
    
    # ПРИМЕНЯЕМ ПЕРЕВОДЫ К ФАЙЛУ безопасным способом
    cp "$NEW_FILE" "${NEW_FILE}.backup"
    TRANSLATED_COUNT=0
    
    for i in "${!KEYS[@]}"; do
        if [ $i -lt ${#TRANSLATIONS[@]} ]; then
            russian_text="${RUSSIAN_TEXTS[$i]}"
            translated_text="${TRANSLATIONS[$i]}"
            
            if [ -n "$translated_text" ] && [ "$translated_text" != "$russian_text" ]; then
                # Используем awk для безопасной замены
                awk -v old="\"$russian_text\" -- TODO:translate" -v new="\"$translated_text\" -- Auto-translated" '{gsub(old,new)}1' "$NEW_FILE" > "${NEW_FILE}.tmp" && mv "${NEW_FILE}.tmp" "$NEW_FILE"
                TRANSLATED_COUNT=$((TRANSLATED_COUNT + 1))
            fi
        fi
    done
    
    echo "📊 Переведено: $TRANSLATED_COUNT/$TOTAL_KEYS"
    
else
    echo "❌ Ошибка пакетного перевода!"
    TRANSLATED_COUNT=0
fi

# Очистка временных файлов
rm -f "$BATCH_INPUT" "$BATCH_OUTPUT"

# Проверка синтаксиса
if luac -p "$NEW_FILE" 2>/dev/null; then
    rm -f "${NEW_FILE}.backup"
    echo "✅ $TARGET_NAME локализация: $NEW_FILE"
else
    echo "❌ Ошибка синтаксиса!"
    mv "${NEW_FILE}.backup" "$NEW_FILE"
    exit 1
fi
