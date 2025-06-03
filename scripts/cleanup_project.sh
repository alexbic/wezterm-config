#!/bin/bash

# Цвета для вывода (более контрастные)
RED='\033[0;91m'         # Ярко-красный
GREEN='\033[0;92m'       # Ярко-зеленый
YELLOW='\033[0;93m'      # Ярко-желтый
BLUE='\033[0;94m'        # Ярко-синий
PURPLE='\033[0;95m'      # Ярко-фиолетовый
CYAN='\033[0;96m'        # Ярко-циан
ORANGE='\033[0;33m'      # Оранжевый для файлов
NC='\033[0m'             # No Color

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

PLATFORM=$(detect_platform)

echo -e "${BLUE}🧹 Универсальная очистка проекта WezTerm (${PLATFORM})${NC}"
echo ""

# Определение директории проекта кроссплатформенно
if [ "$PLATFORM" = "windows" ]; then
    PROJECT_DIR="$USERPROFILE/.config/wezterm"
else
    PROJECT_DIR="$HOME/.config/wezterm"
fi

# Переходим в директорию проекта
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}❌ Директория проекта не найдена: $PROJECT_DIR${NC}"
    exit 1
fi

cd "$PROJECT_DIR" || exit 1

# Паттерны для поиска ненужных файлов (кроссплатформенные)
PATTERNS=(
    "*.backup*"
    "*.bak"
    "*.backup[0-9]*"
    "*.prebackup"
    "test_*.lua"
    "test_*.sh" 
    "test-*.lua"
    "test-*.sh"
    "*test*.lua"
    "*test*.sh"
    ".!*!*.lua"
    "*.!*"
    "temp_*.lua"
    "tmp_*.lua"
    "*.tmp"
    "*.log"
    "*debug*.tmp"
    "rollback_*.sh"
    "*_old.*"
    "*_deprecated.*"
    "*log_info*"
    "Thumbs.db"
    "desktop.ini"
    "*~"
    ".*.swp"
    ".*.swo"
)

# Кроссплатформенная функция find
cross_platform_find() {
    local pattern="$1"
    
    if [ "$PLATFORM" = "windows" ]; then
        powershell.exe -Command "Get-ChildItem -Path '.' -Filter '$pattern' -Recurse -File | ForEach-Object { \$_.FullName.Replace((Get-Location).Path + '\\', '.\\').Replace('\\', '/') }"
    else
        find . -name "$pattern" -type f 2>/dev/null
    fi
}

# Функция поиска файлов по паттернам (БЕЗ echo в stdout)
find_files_to_delete() {
    echo -e "${CYAN}🔍 Поиск файлов для удаления по паттернам...${NC}" >&2
    
    local all_files=()
    for pattern in "${PATTERNS[@]}"; do
        while IFS= read -r file; do
            if [[ -f "$file" && "$file" != "./cleanup_project.sh" ]]; then
                all_files+=("$file")
            fi
        done < <(cross_platform_find "$pattern")
    done
    
    # Выводим уникальные файлы, фильтруем пустые строки
    if [ ${#all_files[@]} -gt 0 ]; then
        printf '%s\n' "${all_files[@]}" | sort -u | grep -v '^[[:space:]]*$'
    fi
}

# Функция отображения найденных файлов
show_files_to_delete() {
    local files=("$@")
    local count=${#files[@]}
    
    if [ $count -eq 0 ]; then
        echo -e "${GREEN}✅ Файлов для удаления не найдено!${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}📋 Найдено файлов для удаления: $count${NC}"
    echo ""
    
    # Группируем по категориям
    local backups=()
    local tests=()
    local artifacts=()
    local temp=()
    local others=()
    
    for file in "${files[@]}"; do
        if [[ "$file" =~ \.(backup|bak) ]]; then
            backups+=("$file")
        elif [[ "$file" =~ test ]]; then
            tests+=("$file")
        elif [[ "$file" =~ \.!.*!|_old|_deprecated|log_info ]]; then
            artifacts+=("$file")
        elif [[ "$file" =~ temp_|tmp_|\.tmp|\.log ]]; then
            temp+=("$file")
        else
            others+=("$file")
        fi
    done
    
    # Показываем по категориям
    show_category "📋 Резервные копии" "${backups[@]}"
    show_category "🧪 Тестовые файлы" "${tests[@]}"
    show_category "🔧 Системные артефакты" "${artifacts[@]}"
    show_category "⏰ Временные файлы" "${temp[@]}"
    show_category "📄 Прочие файлы" "${others[@]}"
    
    return 0
}

# Функция показа категории файлов
show_category() {
    local title="$1"
    shift
    local files=("$@")
    
    if [ ${#files[@]} -gt 0 ]; then
        echo -e "${PURPLE}$title:${NC}"
        for file in "${files[@]}"; do
            echo -e "  ${ORANGE}🗑️  $file${NC}"
        done
        echo ""
    fi
}

# Функция запроса подтверждения
confirm_deletion() {
    echo -e "${YELLOW}❓ Удалить все найденные файлы? (y/N):${NC} \c"
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Основная логика
main() {
    # Поиск файлов - исправленная логика
    local files_to_delete=()
    while IFS= read -r line; do 
        if [[ -n "$line" ]]; then  # Фильтруем пустые строки
            files_to_delete+=("$line")
        fi
    done < <(find_files_to_delete)
    
    # Показ найденных файлов
    if show_files_to_delete "${files_to_delete[@]}"; then
        echo ""
        if confirm_deletion; then
            echo -e "${GREEN}✅ Удаление выполнено бы здесь${NC}"
        else
            echo -e "${CYAN}📋 Удаление отменено пользователем${NC}"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}✨ Операция завершена!${NC}"
}

# Запуск
main
