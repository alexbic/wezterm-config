#!/bin/bash

# Универсальный скрипт для создания новой локали с опциональным автопереводом
# Использование: ./create-locale.sh <source_lang> <target_lang> <target_name> <target_locale_string> [--auto-translate]
# Пример: ./create-locale.sh ru en English en_US.UTF-8 --auto-translate

SOURCE_LANG="$1"
TARGET_LANG="$2"
TARGET_NAME="$3"
TARGET_LOCALE_STRING="$4"
AUTO_TRANSLATE="$5"

if [ -z "$SOURCE_LANG" ] || [ -z "$TARGET_LANG" ] || [ -z "$TARGET_NAME" ] || [ -z "$TARGET_LOCALE_STRING" ]; then
    echo "❌ Использование: $0 <source_lang> <target_lang> <target_name> <target_locale_string> [--auto-translate]"
    echo ""
    echo "📝 Примеры:"
    echo "   $0 ru en English en_US.UTF-8                    # Только создание шаблона"
    echo "   $0 ru en English en_US.UTF-8 --auto-translate  # С автоматическим переводом"
    echo "   $0 en de German de_DE.UTF-8 --auto-translate   # Английский → Немецкий"
    echo ""
    echo "📂 Доступные исходные локали:"
    ls ~/.config/wezterm/config/locales/*.lua 2>/dev/null | sed 's/.*\/\([^.]*\)\.lua/   \1/' | grep -v locale-manager || echo "   (нет файлов)"
    exit 1
fi

BASE_FILE="$HOME/.config/wezterm/config/locales/${SOURCE_LANG}.lua"
NEW_FILE="$HOME/.config/wezterm/config/locales/${TARGET_LANG}.lua"
SCRIPT_DIR="$(dirname "$0")"

if [ ! -f "$BASE_FILE" ]; then
    echo "❌ Исходный файл не найден: $BASE_FILE"
    exit 1
fi

if [ -f "$NEW_FILE" ]; then
    echo "⚠️  Файл $NEW_FILE уже существует!"
    read -p "🤔 Перезаписать? (y/N): " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

echo "🚀 Создание локали: $SOURCE_LANG → $TARGET_LANG ($TARGET_NAME)"

# Определяем название исходной локали
SOURCE_NAME=$(grep 'name = ' "$BASE_FILE" | sed 's/.*name = "\([^"]*\)".*/\1/')

# Создаем новый файл локали
cat > "$NEW_FILE" << LOCALE_EOF
-- ${TARGET_NAME} localization (generated from ${SOURCE_LANG}.lua - ${SOURCE_NAME})
return {
  locale = "${TARGET_LOCALE_STRING}",
  name = "${TARGET_NAME}",
  
$(grep -E "^  [a-zA-Z_]+ = \".*\",$" "$BASE_FILE" | while IFS= read -r line; do
    key=$(echo "$line" | sed 's/^  \([a-zA-Z_]*\) = .*/\1/')
    value=$(echo "$line" | sed 's/^  [a-zA-Z_]* = \(.*\),$/\1/')
    
    # Пропускаем уже заданные ключи
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

echo "✅ Базовый файл локали создан!"
echo "📝 Файл: $NEW_FILE"
echo "📊 Ключей для перевода: $(grep -c "TODO: translate" "$NEW_FILE")"

# Автоматический перевод, если запрошен
if [ "$AUTO_TRANSLATE" = "--auto-translate" ]; then
    echo ""
    echo "🌐 Запуск автоматического перевода..."
    
    # Проверяем наличие скрипта автоперевода
    if [ -f "$SCRIPT_DIR/auto-translate.sh" ]; then
        if "$SCRIPT_DIR/auto-translate.sh" "$NEW_FILE" "$TARGET_LANG"; then
            echo "🎉 Автоматический перевод завершен!"
        else
            echo "⚠️  Автоматический перевод завершился с ошибками"
        fi
    else
        echo "❌ Скрипт auto-translate.sh не найден в $SCRIPT_DIR"
    fi
else
    echo "💡 Для автоматического перевода добавьте флаг --auto-translate"
fi

echo ""
echo "✨ Готово! Локаль $TARGET_LANG создана."
if [ "$AUTO_TRANSLATE" != "--auto-translate" ]; then
    echo "🔧 Следующий шаг: отредактируйте файл и переведите строки с -- TODO: translate"
fi
