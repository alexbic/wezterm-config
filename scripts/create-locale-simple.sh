#!/bin/bash
SOURCE_FILE="$1"
TARGET_LANG="$2"
SOURCE_DIR=$(dirname "$SOURCE_FILE")
NEW_FILE="$SOURCE_DIR/${TARGET_LANG}.lua"

cp "$SOURCE_FILE" "$NEW_FILE"
case "$TARGET_LANG" in
    "en") TARGET_LOCALE="en_US.UTF-8"; TARGET_NAME="English" ;;
    "de") TARGET_LOCALE="de_DE.UTF-8"; TARGET_NAME="German" ;;
    *) TARGET_LOCALE="${TARGET_LANG}_${TARGET_LANG^^}.UTF-8"; TARGET_NAME="Unknown" ;;
esac

sed -i '' "s/ru_RU\.UTF-8/$TARGET_LOCALE/g" "$NEW_FILE"
sed -i '' "s/\"Русский\"/\"$TARGET_NAME\"/g" "$NEW_FILE"
echo "✅ $TARGET_NAME локаль создана: $NEW_FILE (без автоперевода)"
