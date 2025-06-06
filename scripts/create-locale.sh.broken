#!/bin/bash

# Создание новой локали с автопереводом
# Использование: ./create-locale.sh <source_file> <target_lang> [-v]

SOURCE_FILE="$1"
TARGET_LANG="$2"
VERBOSE=""

# Проверка флага вербозности
for arg in "$@"; do
    case $arg in
        -v|--verbose)
            VERBOSE="-v"
            ;;
    esac
done

if [ -z "$SOURCE_FILE" ] || [ -z "$TARGET_LANG" ]; then
    echo "❌ Использование: $0 <source_file> <target_lang> [-v]"
    echo ""
    echo "📝 Примеры:"
    echo "   $0 config/locales/ru.lua en           # Тихий режим"
    echo "   $0 config/locales/ru.lua de -v        # С логированием"
    echo ""
    exit 1
fi

if [ ! -f "$SOURCE_FILE" ]; then
    echo "❌ Исходный файл не найден: $SOURCE_FILE"
    exit 1
fi

# Определяем путь для нового файла
SOURCE_DIR=$(dirname "$SOURCE_FILE")
NEW_FILE="$SOURCE_DIR/${TARGET_LANG}.lua"

# Определяем локаль и имя языка по коду
case "$TARGET_LANG" in
    "en") 
        TARGET_LOCALE="en_US.UTF-8"
        TARGET_NAME="English"
        ;;
    "de") 
        TARGET_LOCALE="de_DE.UTF-8"
        TARGET_NAME="German"
        ;;
    "fr") 
        TARGET_LOCALE="fr_FR.UTF-8"
        TARGET_NAME="French"
        ;;
    "es") 
        TARGET_LOCALE="es_ES.UTF-8"
        TARGET_NAME="Spanish"
        ;;
    *)
        TARGET_LOCALE="${TARGET_LANG}_${TARGET_LANG^^}.UTF-8"
        TARGET_NAME="Unknown"
        ;;
esac

if [ -f "$NEW_FILE" ]; then
    [ "$VERBOSE" ] && echo "⚠️  Файл $NEW_FILE уже существует - перезаписываем"
fi

[ "$VERBOSE" ] && echo "🚀 Создание локали: $(basename $SOURCE_FILE) → $TARGET_LANG ($TARGET_NAME)"

# Получаем исходное имя языка
SOURCE_NAME=$(grep 'name = ' "$SOURCE_FILE" | sed 's/.*name = "\([^"]*\)".*/\1/')

# Создаем новый файл локали
cat > "$NEW_FILE" << LOCALE_EOF
-- ${TARGET_NAME} localization (generated from $(basename $SOURCE_FILE) - ${SOURCE_NAME})
return {
  locale = "${TARGET_LOCALE}",
  name = "${TARGET_NAME}",
  
$(grep -E "^  [a-zA-Z_]+ = \".*\",$" "$SOURCE_FILE" | while IFS= read -r line; do
    key=$(echo "$line" | sed 's/^  \([a-zA-Z_]*\) = .*/\1/')
    value=$(echo "$line" | sed 's/^  [a-zA-Z_]* = \(.*\),$/\1/')
    
    # Пропускаем служебные ключи
    if [[ "$key" == "locale" || "$key" == "name" ]]; then
        continue
    fi
    
    echo "  $key = $value, -- TODO: translate"
done)
}
LOCALE_EOF

# Проверяем синтаксис
if ! luac -p "$NEW_FILE" 2>/dev/null; then
    echo "❌ Ошибка синтаксиса в созданном файле!"
    rm -f "$NEW_FILE"
    exit 1
fi

[ "$VERBOSE" ] && echo "✅ Базовый файл создан: $NEW_FILE"
[ "$VERBOSE" ] && echo "📊 Ключей для перевода: $(grep -c "TODO: translate" "$NEW_FILE")"

# Автоматический перевод (всегда включен)
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/auto-translate.sh" ]; then
    "$SCRIPT_DIR/auto-translate.sh" "$NEW_FILE" "$TARGET_LANG" $VERBOSE
else
    echo "❌ Скрипт auto-translate.sh не найден"
    exit 1
fi

echo "✨ Готово! Локаль $TARGET_LANG создана."
