#!/bin/bash
echo "🔄 Откатываем изменения workspace integration..."

# Ищем последние резервные копии
workspace_backup=$(ls events/workspace-events.lua.backup_* 2>/dev/null | tail -1)
keyboard_backup=$(ls config/bindings/keyboard-tables.lua.backup_* 2>/dev/null | tail -1)

if [ -n "$workspace_backup" ]; then
    echo "📁 Восстанавливаем $workspace_backup"
    cp "$workspace_backup" events/workspace-events.lua
fi

if [ -n "$keyboard_backup" ]; then
    echo "⌨️  Восстанавливаем $keyboard_backup"
    cp "$keyboard_backup" config/bindings/keyboard-tables.lua
fi

echo "✅ Откат завершён. Перезагрузите WezTerm."
