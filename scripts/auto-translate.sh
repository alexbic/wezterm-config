#!/bin/bash

# Скрипт автоматического перевода локали с использованием Google Translate
# Использование: ./auto-translate.sh <lang_file> <target_lang_code>

LANG_FILE="$1"
TARGET_LANG="$2"

if [ -z "$LANG_FILE" ] || [ -z "$TARGET_LANG" ] || [ ! -f "$LANG_FILE" ]; then
    echo "❌ Использование: $0 <lang_file> <target_lang_code>"
    echo "📝 Пример: $0 config/locales/en.lua en"
    exit 1
fi

# Функция перевода через Google Translate (бесплатный API)
translate_text() {
    local text="$1"
    local target="$2"
    
    # Экранируем специальные символы для URL
    local encoded_text=$(printf '%s' "$text" | sed 's/ /%20/g; s/://g; s/\.\.\./…/g')
    
    # Используем Google Translate через веб-интерфейс
    local url="https://translate.googleapis.com/translate_a/single?client=gtx&sl=ru&tl=${target}&dt=t&q=${encoded_text}"
    
    # Получаем перевод
    local result=$(curl -s -A "Mozilla/5.0" "$url" 2>/dev/null | sed 's/\[\[\["//' | sed 's/".*//' | head -1)
    
    if [ -n "$result" ] && [ "$result" != "null" ]; then
        echo "$result"
    else
        echo "$text"  # возвращаем оригинал, если перевод не удался
    fi
}

echo "🌐 Автоматический перевод файла: $LANG_FILE"
echo "🎯 Целевой язык: $TARGET_LANG"

# Создаем backup
cp "$LANG_FILE" "${LANG_FILE}.backup"

# Временный файл для обработки
TEMP_FILE=$(mktemp)
cp "$LANG_FILE" "$TEMP_FILE"

# Счетчики
TOTAL_KEYS=0
TRANSLATED_KEYS=0

echo "🔄 Начинаем перевод..."

# ИСПРАВЛЕНО: Используем grep с правильным экранированием
while IFS= read -r line; do
    if echo "$line" | grep -F "-- TODO: translate" >/dev/null; then
        TOTAL_KEYS=$((TOTAL_KEYS + 1))
        
        # Извлекаем русский текст между кавычками
        russian_text=$(echo "$line" | sed 's/.*= "\(.*\)", -- TODO: translate/\1/')
        
        if [ -n "$russian_text" ] && [ "$russian_text" != "$line" ]; then
            echo "📝 Переводим: $russian_text"
            
            # Переводим текст
            translated_text=$(translate_text "$russian_text" "$TARGET_LANG")
            
            if [ "$translated_text" != "$russian_text" ] && [ -n "$translated_text" ]; then
                # Заменяем в файле (экранируем спецсимволы)
                escaped_russian=$(printf '%s\n' "$russian_text" | sed 's/[[\.*^$()+?{|]/\\&/g')
                escaped_translated=$(printf '%s\n' "$translated_text" | sed 's/[[\.*^$()+?{|]/\\&/g')
                
                sed -i '' "s/= \"${escaped_russian}\", -- TODO: translate/= \"${escaped_translated}\", -- Auto-translated/g" "$TEMP_FILE"
                
                TRANSLATED_KEYS=$((TRANSLATED_KEYS + 1))
                echo "   ✅ → $translated_text"
            else
                echo "   ⚠️  Перевод не удался, оставляем оригинал"
            fi
            
            # Пауза между запросами к API
            sleep 1
        fi
    fi
done < "$LANG_FILE"

# Проверяем синтаксис результата
if luac -p "$TEMP_FILE" 2>/dev/null; then
    mv "$TEMP_FILE" "$LANG_FILE"
    rm -f "${LANG_FILE}.backup"
    
    echo ""
    echo "✅ Автоматический перевод завершен!"
    echo "📊 Всего ключей для перевода: $TOTAL_KEYS"
    echo "📊 Успешно переведено: $TRANSLATED_KEYS"
    echo "📊 Осталось перевести вручную: $((TOTAL_KEYS - TRANSLATED_KEYS))"
else
    echo "❌ Ошибка синтаксиса! Восстанавливаем из backup..."
    mv "${LANG_FILE}.backup" "$LANG_FILE"
    rm -f "$TEMP_FILE"
    exit 1
fi
