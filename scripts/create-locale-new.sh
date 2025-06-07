#!/bin/bash
# Создание локали через шаблон + пакетный перевод

SOURCE_FILE="$1"
TARGET_LANG="$2"

# Функции определения locale и названий
get_locale_for_language() {
    case "$1" in
        "en") echo "en_US.UTF-8" ;;
        "de") echo "de_DE.UTF-8" ;;
        *) echo "${1}_$(echo "$1" | tr '[:lower:]' '[:upper:]').UTF-8" ;;
    esac
}

get_language_name() {
    case "$1" in
        "en") echo "English" ;;
        "de") echo "German" ;;
        *) echo "Unknown" ;;
    esac
}

# Основная логика
TARGET_LOCALE=$(get_locale_for_language "$TARGET_LANG")
TARGET_NAME=$(get_language_name "$TARGET_LANG")
SOURCE_DIR=$(dirname "$SOURCE_FILE")
NEW_FILE="$SOURCE_DIR/${TARGET_LANG}.lua"

echo "🌐 Создание $TARGET_NAME локали через шаблон"

# СБОР КЛЮЧЕЙ ДЛЯ ПЕРЕВОДА
KEYS_AND_VALUES=$(grep -E '^  [a-zA-Z_]+ = "[^"]*[а-яё][^"]*"' "$SOURCE_FILE" | grep -v 'name = "Русский"')
echo "🎯 Найдено ключей: $(echo "$KEYS_AND_VALUES" | wc -l)"

# Извлекаем русские тексты для перевода
RUSSIAN_TEXTS=$(echo "$KEYS_AND_VALUES" | sed 's/.*= "\(.*\)",/\1/')
echo "🔄 Подготовка к пакетному переводу..."

# Создаем временные файлы
BATCH_INPUT=$(mktemp)
BATCH_OUTPUT=$(mktemp)

# Записываем тексты для перевода
echo "$RUSSIAN_TEXTS" > "$BATCH_INPUT"

# ПАКЕТНЫЙ ПЕРЕВОД
echo "⏳ Пакетный перевод $(echo "$RUSSIAN_TEXTS" | wc -l) строк..."
if gtimeout 120 trans -brief "ru:${TARGET_LANG}" -i "$BATCH_INPUT" > "$BATCH_OUTPUT" 2>/dev/null; then
    echo "✅ Перевод выполнен!"
    
    # Формируем блок переведенных ключей
    TRANSLATED_BLOCK=""
    KEY_NAMES=$(echo "$KEYS_AND_VALUES" | sed 's/ = .*//')
    TRANSLATIONS=$(cat "$BATCH_OUTPUT")
    
    # Объединяем ключи с переводами
    paste <(echo "$KEY_NAMES") <(echo "$TRANSLATIONS") | while IFS=$'\t' read key translation; do
        echo "$key = \"$translation\","
    done > /tmp/translated_keys.tmp
    
    TRANSLATED_KEYS=$(cat /tmp/translated_keys.tmp)
    
    # Создаем файл из шаблона
    sed -e "s/{{LANGUAGE_NAME}}/$TARGET_NAME/g" \
        -e "s/{{LOCALE_CODE}}/$TARGET_LOCALE/g" \
        -e "/{{TRANSLATED_KEYS}}/r /tmp/translated_keys.tmp" \
        -e "/{{TRANSLATED_KEYS}}/d" \
        ~/.config/wezterm/config/locales/template.lua > "$NEW_FILE"
    
    echo "✅ $TARGET_NAME локализация создана: $NEW_FILE"
    
    # Проверка синтаксиса
    if luac -p "$NEW_FILE" 2>/dev/null; then
        echo "✅ Синтаксис корректен!"
    else
        echo "❌ Ошибка синтаксиса!"
    fi
    
    # Очистка
    rm -f "$BATCH_INPUT" "$BATCH_OUTPUT" /tmp/translated_keys.tmp
else
    echo "❌ Ошибка перевода!"
fi
