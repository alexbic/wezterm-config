-- cat > ~/.config/wezterm/config/environment.lua << 'EOF'
--
-- ОПИСАНИЕ: Настройки переменных окружения для WezTerm
-- Централизованное управление локалью, путями и другими переменными окружения
-- Позволяет задавать специфичные для терминала настройки без изменения системных
--
-- ЗАВИСИМОСТИ: utils.platform, config.locale

local wezterm = require('wezterm')
local platform = require('utils.platform')()

-- Безопасная загрузка конфигурации локали
local locale_config = {}
local status, config = pcall(require, 'config.locale')
if status then
  locale_config = config
else
  -- Fallback значения если config.locale отсутствует
  locale_config = {
    force_language = "ru",
    force_locale = "ru_RU.UTF-8"
  }
end

-- Определяем базовые пути в зависимости от платформы
local paths = {
  home = wezterm.home_dir,
  config = wezterm.config_dir,
}

-- Расширяем пути в зависимости от ОС
if platform.is_mac then
  paths.brew = "/opt/homebrew"
  paths.applications = "/Applications"
elseif platform.is_linux then
  paths.local_bin = paths.home .. "/.local/bin"
  paths.usr_local = "/usr/local"
elseif platform.is_win then
  paths.program_files = "C:\\Program Files"
  paths.appdata = os.getenv("APPDATA") or ""
end

-- Настройки локали с приоритетом конфигурации
local locale_settings = {}

if locale_config.force_locale then
  wezterm.log_info("Применяется принудительная локаль: " .. locale_config.force_locale)
  locale_settings = {
    LANG = locale_config.force_locale,
    LC_ALL = locale_config.force_locale,
    LC_TIME = locale_config.force_locale,
    LC_NUMERIC = locale_config.force_locale,
    LC_MONETARY = locale_config.force_locale,
  }
else
  -- Русская локаль по умолчанию
  locale_settings = {
    LANG = 'ru_RU.UTF-8',
    LC_ALL = 'ru_RU.UTF-8',
    LC_TIME = 'ru_RU.UTF-8',
    LC_NUMERIC = 'ru_RU.UTF-8',
    LC_MONETARY = 'ru_RU.UTF-8',
  }
end

-- Настройки редакторов и инструментов разработки
local dev_tools = {
  -- Основной редактор
  EDITOR = 'nvim',                    -- или 'vim', 'nano', 'code'
  VISUAL = 'nvim',
  
  -- Git настройки
  GIT_EDITOR = 'nvim',
  
  -- Pager
  PAGER = 'less',
  LESS = '-R',                        -- Поддержка цветов в less
  
  -- Настройки Node.js
  NODE_ENV = 'development',
  
  -- Настройки Python
  PYTHONPATH = paths.home .. '/.local/lib/python3.11/site-packages',
  
  -- Настройки для различных инструментов
  BAT_THEME = 'TwoDark',              -- Тема для bat (аналог cat с подсветкой)
  FZF_DEFAULT_OPTS = '--height 40% --layout=reverse --border',
}

-- Пути для PATH в зависимости от платформы
local path_additions = {}

if platform.is_mac then
  table.insert(path_additions, "/opt/homebrew/bin")
  table.insert(path_additions, "/opt/homebrew/sbin")
  table.insert(path_additions, paths.home .. "/.cargo/bin")
  table.insert(path_additions, paths.home .. "/go/bin")
elseif platform.is_linux then
  table.insert(path_additions, paths.home .. "/.local/bin")
  table.insert(path_additions, paths.home .. "/.cargo/bin")
  table.insert(path_additions, paths.home .. "/go/bin")
  table.insert(path_additions, "/usr/local/go/bin")
elseif platform.is_win then
  table.insert(path_additions, paths.home .. "\\.cargo\\bin")
  table.insert(path_additions, "C:\\Go\\bin")
end

-- Функция для построения PATH
local function build_path()
  local current_path = os.getenv("PATH") or ""
  local separator = platform.is_win and ";" or ":"
  
  -- Добавляем наши пути в начало PATH
  for _, path in ipairs(path_additions) do
    current_path = path .. separator .. current_path
  end
  
  return current_path
end

-- Цветовые схемы для различных инструментов
local color_settings = {
  -- Настройки цветов для ls (на macOS и Linux)
  CLICOLOR = '1',
  LSCOLORS = 'ExFxBxDxCxegedabagacad',  -- macOS
  LS_COLORS = 'di=1;34:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43', -- Linux
  
  -- Настройки для grep
  GREP_COLOR = '1;32',
  GREP_OPTIONS = '--color=auto',
}

-- Настройки терминала
local terminal_settings = {
  TERM = 'xterm-256color',
  COLORTERM = 'truecolor',
  
  -- История команд
  HISTSIZE = '10000',
  HISTFILESIZE = '20000',
  
  -- Настройки для различных shell
  ZSH_THEME = 'powerlevel10k/powerlevel10k',  -- Если используется oh-my-zsh
}

-- Настройки для конкретных приложений
local app_settings = {
  -- Docker
  DOCKER_BUILDKIT = '1',
  COMPOSE_DOCKER_CLI_BUILD = '1',
  
  -- Kubernetes
  KUBE_EDITOR = 'nvim',
  
  -- Rust
  RUST_BACKTRACE = '1',
  CARGO_INCREMENTAL = '1',
  
  -- Go
  GOPROXY = 'https://proxy.golang.org,direct',
  GOSUMDB = 'sum.golang.org',
  
  -- Java (если используется)
  -- JAVA_HOME = '/usr/lib/jvm/java-11-openjdk',
}

-- Объединяем все настройки
local function get_environment_variables()
  local env_vars = {}
  
  -- Добавляем PATH
  env_vars.PATH = build_path()
  
  -- Функция для слияния таблиц
  local function merge_tables(target, source)
    for k, v in pairs(source) do
      target[k] = v
    end
  end
  
  -- Объединяем все настройки
  merge_tables(env_vars, locale_settings)
  merge_tables(env_vars, dev_tools)
  merge_tables(env_vars, color_settings)
  merge_tables(env_vars, terminal_settings)
  merge_tables(env_vars, app_settings)
  
  -- Добавляем пути как переменные для использования в конфигурации
  env_vars.WEZTERM_CONFIG_DIR = paths.config
  env_vars.WEZTERM_HOME = paths.home
  
  -- Логируем некоторые важные настройки
  wezterm.log_info("Установка локали: " .. (env_vars.LANG or "не задана"))
  wezterm.log_info("Редактор: " .. (env_vars.EDITOR or "не задан"))
  wezterm.log_info("Платформа: " .. (platform.is_mac and "macOS" or platform.is_linux and "Linux" or platform.is_win and "Windows" or "Unknown"))
  
  return env_vars
end

-- Возвращаем только сериализуемые данные (без функций)
return {
  set_environment_variables = get_environment_variables(),
}
