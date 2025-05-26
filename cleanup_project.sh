#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Начинаем очистку проекта WezTerm${NC}"
echo ""

# Переходим в директорию проекта
cd ~/.myshell/wezterm

# Создаем финальную резервную копию перед очисткой
BACKUP_DIR="backup_before_cleanup_$(date +%Y%m%d_%H%M%S)"
echo -e "${YELLOW}📦 Создаем финальную резервную копию: $BACKUP_DIR${NC}"
mkdir -p "../$BACKUP_DIR"
cp -r . "../$BACKUP_DIR/"

# Счетчики
deleted_count=0
kept_count=0

# Функция для безопасного удаления
safe_delete() {
    local file="$1"
    local reason="$2"
    if [ -f "$file" ]; then
        echo -e "${RED}🗑️  Удаляем: $file ($reason)${NC}"
        rm "$file"
        ((deleted_count++))
    fi
}

# Функция для подсчета сохраненных файлов
mark_kept() {
    local file="$1"
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ Сохраняем: $file${NC}"
        ((kept_count++))
    fi
}

echo -e "${YELLOW}🔍 Анализируем и удаляем ненужные файлы...${NC}"
echo ""

# 1. Удаляем .DS_Store файлы (macOS системные файлы)
echo -e "${BLUE}📁 Удаляем .DS_Store файлы...${NC}"
find . -name ".DS_Store" -type f | while read file; do
    safe_delete "$file" "macOS system file"
done

# 2. Удаляем резервные копии (.backup, .bak файлы)
echo -e "${BLUE}📋 Удаляем резервные копии...${NC}"

# Appearance backups
safe_delete "config/appearance/events.lua.backup" "backup file"
safe_delete "config/appearance/init.lua.backup" "backup file"
safe_delete "config/appearance/init.lua.backup6" "backup file"

# Bindings backups
safe_delete "config/bindings/init.lua.backup" "backup file"
safe_delete "config/bindings/keyboard-tables.lua.backup" "backup file"
safe_delete "config/bindings/keyboard-tables.lua.backup2" "backup file"
safe_delete "config/bindings/keyboard-tables.lua.bak" "backup file"
safe_delete "config/bindings/keyboard.lua.backup" "backup file"
safe_delete "config/bindings/keyboard.lua.bak" "backup file"

# Environment backups
safe_delete "config/environment/domains.lua.backup" "backup file"
safe_delete "config/environment/domains.lua.backup4" "backup file"
safe_delete "config/environment/init.lua.backup" "backup file"
safe_delete "config/environment/paths.lua.backup" "backup file"

# Config backups
safe_delete "config/general.lua.backup" "backup file"
safe_delete "config/launch.lua.backup" "backup file"

# Resurrect backups (множественные)
safe_delete "config/resurrect.lua.backup" "backup file"
safe_delete "config/resurrect.lua.backup_20250525_085816" "dated backup file"
safe_delete "config/resurrect.lua.backup_20250526_023730" "dated backup file"
safe_delete "config/resurrect.lua.backup_debug" "debug backup file"

# Workspace switcher backups
safe_delete "config/workspace-switcher.lua.backup_20250526_015700" "dated backup file"
safe_delete "config/workspace-switcher.lua.bak" "backup file"

# Events backups
safe_delete "events/right-status.lua.backup" "backup file"
safe_delete "events/right-status.lua.backup2" "backup file"
safe_delete "events/session-status.lua.backup" "backup file"
safe_delete "events/session-status.lua.bak" "backup file"
safe_delete "events/tab-title.lua.backup" "backup file"
safe_delete "events/workspace-events.lua.bak" "backup file"
safe_delete "events/workspace-events.lua.bak2" "backup file"

# Utils backups
safe_delete "utils/appearance.lua.backup" "backup file"
safe_delete "utils/appearance.lua.bak" "backup file"

# Main config backups
safe_delete "wezterm.lua.backup" "backup file"
safe_delete "wezterm.lua.backup_20250525_005500" "dated backup file"
safe_delete "wezterm.lua.backup4" "backup file"
safe_delete "wezterm.lua.bak" "backup file"

# 3. Удаляем временные и сломанные файлы
echo -e "${BLUE}🔧 Удаляем временные и сломанные файлы...${NC}"
safe_delete "temp_right_status_fix.lua" "temporary file"
safe_delete "ezterm.log_info(\"Обработчик события resurrect.save_state\")" "broken filename"
safe_delete "ezterm.lua" "empty/broken file"

# 4. Удаляем неиспользуемые workspace модули (они дублируют функциональность)
echo -e "${BLUE}🏗️  Удаляем дублированные workspace модули...${NC}"
safe_delete "config/session-management.lua" "duplicate functionality with resurrect"
safe_delete "config/workspace-manager.lua" "duplicate functionality"  
safe_delete "config/workspace-sessions.lua" "duplicate functionality"

# 5. Удаляем старый скрипт отката
echo -e "${BLUE}🔄 Удаляем старые утилиты...${NC}"
safe_delete "rollback_workspace_integration.sh" "old rollback script"

echo ""
echo -e "${BLUE}✨ Отмечаем сохраненные основные файлы...${NC}"

# Отмечаем ключевые файлы которые сохраняем
mark_kept "wezterm.lua"
mark_kept "config/general.lua"
mark_kept "config/resurrect.lua"
mark_kept "config/launch.lua"

# Appearance
mark_kept "config/appearance/init.lua"
mark_kept "config/appearance/backgrounds.lua"
mark_kept "config/appearance/events.lua"
mark_kept "config/appearance/transparency.lua"

# Bindings
mark_kept "config/bindings/global.lua"
mark_kept "config/bindings/init.lua"
mark_kept "config/bindings/keyboard.lua"
mark_kept "config/bindings/keyboard-tables.lua"
mark_kept "config/bindings/mouse.lua"

# Environment
mark_kept "config/environment/init.lua"
mark_kept "config/environment/apps.lua"
mark_kept "config/environment/colors.lua"
mark_kept "config/environment/devtools.lua"
mark_kept "config/environment/domains.lua"
mark_kept "config/environment/fonts.lua"
mark_kept "config/environment/locale.lua"
mark_kept "config/environment/paths.lua"
mark_kept "config/environment/terminal.lua"

# Events
mark_kept "events/new-tab-button.lua"
mark_kept "events/right-status.lua"
mark_kept "events/session-status.lua"
mark_kept "events/tab-title.lua"
mark_kept "events/workspace-events.lua"

# Utils
mark_kept "utils/appearance.lua"
mark_kept "utils/bindings.lua"
mark_kept "utils/environment.lua"
mark_kept "utils/math.lua"
mark_kept "utils/notifications.lua"
mark_kept "utils/platform.lua"
mark_kept "utils/safe-require.lua"

# Workspace switcher (оставляем только основной)
mark_kept "config/workspace-switcher.lua"

echo ""
echo -e "${GREEN}🎉 Очистка завершена!${NC}"
echo -e "${YELLOW}📊 Статистика:${NC}"
echo -e "   🗑️  Удалено файлов: ${RED}$deleted_count${NC}"
echo -e "   ✅ Сохранено файлов: ${GREEN}$kept_count${NC}"
echo ""
echo -e "${BLUE}📦 Резервная копия сохранена в: ../$BACKUP_DIR${NC}"
echo -e "${YELLOW}⚠️  В случае проблем, вы можете восстановить из резервной копии${NC}"
echo ""
echo -e "${GREEN}✨ Проект очищен и готов к дальнейшей работе!${NC}"

