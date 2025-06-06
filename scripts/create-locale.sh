#!/bin/bash
# Исправленная версия без UTF-8 проблем
SOURCE_FILE="$1"
TARGET_LANG="$2"
if [ -z "$SOURCE_FILE" ] || [ -z "$TARGET_LANG" ]; then
    echo "❌ Использование: $0 <source_file> <target_lang>"
    exit 1
fi
if [ ! -f "$SOURCE_FILE" ]; then
    echo "❌ Исходный файл не найден: $SOURCE_FILE"
    exit 1
fi
SOURCE_DIR=$(dirname "$SOURCE_FILE")
NEW_FILE="$SOURCE_DIR/${TARGET_LANG}.lua"
case "$TARGET_LANG" in
    "en") TARGET_LOCALE="en_US.UTF-8"; TARGET_NAME="English" ;;
    "de") TARGET_LOCALE="de_DE.UTF-8"; TARGET_NAME="German" ;;
    "fr") TARGET_LOCALE="fr_FR.UTF-8"; TARGET_NAME="French" ;;
    *) TARGET_LOCALE="${TARGET_LANG}_${TARGET_LANG^^}.UTF-8"; TARGET_NAME="Unknown" ;;
esac
cp "$SOURCE_FILE" "$NEW_FILE"
sed -i '' "s/ru_RU\.UTF-8/$TARGET_LOCALE/g" "$NEW_FILE"
sed -i '' "s/\"Русский\"/\"$TARGET_NAME\"/g" "$NEW_FILE"
sed -i '' "s/-- Русская локализация.*/-- $TARGET_NAME localization/" "$NEW_FILE"
if luac -p "$NEW_FILE" 2>/dev/null; then
    echo "✅ $TARGET_NAME локаль создана: $NEW_FILE"
else
    echo "❌ Ошибка синтаксиса!"
    rm -f "$NEW_FILE"
    exit 1
fi
