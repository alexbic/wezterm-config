#!/bin/bash

# Кроссплатформенный автоматический перевод через Translate Shell
# Поддержка: macOS, Linux, Windows (WSL/MSYS2/Cygwin)
# Использование: ./auto-translate.sh <lang_file> <target_lang> [-v]

LANG_FILE="$1"
TARGET_LANG="$2"
VERBOSE=""

for arg in "$@"; do
    case $arg in
        -v|--verbose)
            VERBOSE="true"
            ;;
    esac
done

if [ -z "$LANG_FILE" ] || [ -z "$TARGET_LANG" ] || [ ! -f "$LANG_FILE" ]; then
    echo "❌ Использование: $0 <lang_file> <target_lang> [-v]"
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

# Автоустановка Translate Shell
install_translate_shell() {
    local platform="$1"
    
    echo "📦 Translate Shell не найден. Устанавливаем..."
    
    case "$platform" in
        "macos")
            if command -v brew &> /dev/null; then
                brew install translate-shell
            else
                echo "❌ Homebrew не найден. Установите: https://brew.sh"
                return 1
            fi
            ;;
        "linux")
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y translate-shell
            elif command -v yum &> /dev/null; then
                sudo yum install -y translate-shell
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y translate-shell
            elif command -v pacman &> /dev/null; then
                sudo pacman -S translate-shell
            else
                # Fallback - компиляция из исходников
                echo "📦 Устанавливаем из исходников..."
                local temp_dir=$(mktemp -d)
                cd "$temp_dir"
                git clone https://github.com/soimort/translate-shell.git
                cd translate-shell
                make && sudo make install
                cd - > /dev/null
                rm -rf "$temp_dir"
            fi
            ;;
        "windows")
            echo "🪟 Windows: устанавливаем через исходники..."
            local temp_dir=$(mktemp -d)
            cd "$temp_dir"
            curl -L https://github.com/soimort/translate-shell/archive/develop.tar.gz | tar -xz
            cd translate-shell-develop
            make install PREFIX="$HOME/.local"
            cd - > /dev/null
            rm -rf "$temp_dir"
            # Добавляем в PATH для текущей сессии
            export PATH="$HOME/.local/bin:$PATH"
            ;;
        *)
            echo "❌ Неподдерживаемая платформа: $platform"
            return 1
            ;;
    esac
}

# Проверяем/устанавливаем Translate Shell
PLATFORM=$(detect_platform)
if ! command -v trans &> /dev/null; then
    [ "$VERBOSE" ] && echo "🔍 Translate Shell не найден для платформы: $PLATFORM"
    
    if ! install_translate_shell "$PLATFORM"; then
        echo "❌ Не удалось установить Translate Shell"
        echo "💡 Ручная установка:"
        case "$PLATFORM" in
            "macos") echo "   brew install translate-shell" ;;
            "linux") echo "   sudo apt install translate-shell  # или ваш пакетный менеджер" ;;
            "windows") echo "   Скачайте с https://github.com/soimort/translate-shell" ;;
        esac
        exit 1
    fi
    
    # Проверяем установку
    if ! command -v trans &> /dev/null; then
        echo "❌ Установка не удалась"
        exit 1
    fi
    
    echo "✅ Translate Shell успешно установлен!"
fi

# Массив для непереведенных строк
UNTRANSLATED=()

[ "$VERBOSE" ] && echo "🌐 Автоматический перевод файла: $LANG_FILE"
[ "$VERBOSE" ] && echo "🎯 Целевой язык: $TARGET_LANG"
[ "$VERBOSE" ] && echo "🖥️  Платформа: $PLATFORM"

cp "$LANG_FILE" "${LANG_FILE}.backup"
TEMP_FILE=$(mktemp)
cp "$LANG_FILE" "$TEMP_FILE"

TOTAL_KEYS=0
TRANSLATED_KEYS=0
LINE_NUMBER=0

[ "$VERBOSE" ] && echo "🔄 Начинаем перевод..."

while IFS= read -r line; do
    LINE_NUMBER=$((LINE_NUMBER + 1))
    
    if echo "$line" | grep "\-\- TODO: translate" >/dev/null; then
        TOTAL_KEYS=$((TOTAL_KEYS + 1))
        
        russian_text=$(echo "$line" | sed 's/.*= "\(.*\)", -- TODO: translate/\1/')
        
        if [ -n "$russian_text" ] && [ "$russian_text" != "$line" ]; then
            [ "$VERBOSE" ] && echo "📝 Переводим: $russian_text"
            # Отладка команды перевода
            [ "$VERBOSE" ] && echo "   🔧 Команда: trans -brief "ru:${TARGET_LANG}" "$russian_text""            
            # Используем trans для перевода с таймаутом
            translated_text=$(trans -brief "ru:${TARGET_LANG}" "$russian_text" 2>/dev/null)
            
            if [ $? -eq 0 ] && [ -n "$translated_text" ] && [ "$translated_text" != "$russian_text" ]; then
                # Кроссплатформенная замена
                if [[ "$PLATFORM" == "macos" ]]; then
                    sed -i '' "/${russian_text//\//\\/}/s/TODO: translate/Auto-translated/" "$TEMP_FILE"
                    sed -i '' "s|\"${russian_text//\//\\/}\"|\"${translated_text//\//\\/}\"|" "$TEMP_FILE"
                else
                    sed -i "/${russian_text//\//\\/}/s/TODO: translate/Auto-translated/" "$TEMP_FILE"
                    sed -i "s|\"${russian_text//\//\\/}\"|\"${translated_text//\//\\/}\"|" "$TEMP_FILE"
                fi
                
                TRANSLATED_KEYS=$((TRANSLATED_KEYS + 1))
                [ "$VERBOSE" ] && echo "   ✅ → $translated_text"
                sleep 0.2  # Пауза для API
            else
                UNTRANSLATED+=("Строка $LINE_NUMBER: \"$russian_text\"")
                [ "$VERBOSE" ] && echo "   ⚠️  Перевод не получен"
            fi
        fi
    fi
done < "$LANG_FILE"

# Проверка синтаксиса (кроссплатформенная)
if command -v luac &> /dev/null && luac -p "$TEMP_FILE" 2>/dev/null; then
    mv "$TEMP_FILE" "$LANG_FILE"
    rm -f "${LANG_FILE}.backup"
    
    echo "✅ Автоматический перевод завершен!"
    echo "📊 Всего ключей: $TOTAL_KEYS"
    echo "📊 Переведено: $TRANSLATED_KEYS"
    echo "📊 Осталось: $((TOTAL_KEYS - TRANSLATED_KEYS))"
    
    if [ ${#UNTRANSLATED[@]} -gt 0 ]; then
        echo ""
        echo "⚠️  НЕПЕРЕВЕДЕННЫЕ СТРОКИ:"
        for item in "${UNTRANSLATED[@]}"; do
            echo "   $item"
        done
        echo ""
        echo "💡 Для редактирования:"
        case "$PLATFORM" in
            "windows") echo "   notepad $LANG_FILE" ;;
            *) echo "   nano +НОМЕР_СТРОКИ $LANG_FILE" ;;
        esac
    fi
else
    echo "❌ Ошибка синтаксиса или луа не установлен! Восстанавливаем backup..."
    mv "${LANG_FILE}.backup" "$LANG_FILE"
    rm -f "$TEMP_FILE"
    exit 1
fi
