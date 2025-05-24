-- cat > ~/.config/wezterm/utils/platform.lua << 'EOF'
--
-- ОПИСАНИЕ: Определение операционной системы и локали
-- Этот модуль определяет операционную систему и локаль, на которой запущен WezTerm.
-- Результат используется для настройки платформо-зависимого поведения.
--
-- ЗАВИСИМОСТИ: Используется в config.fonts, config.bindings, config.launch, events.right-status

local wezterm = require('wezterm')

local function is_found(str, pattern)
   return string.find(str, pattern) ~= nil
end

-- Определяем платформу заранее
local is_win = is_found(wezterm.target_triple, 'windows')
local is_linux = is_found(wezterm.target_triple, 'linux')
local is_mac = is_found(wezterm.target_triple, 'apple')
local is_wsl = os.getenv("WSL_DISTRO_NAME") ~= nil

-- Безопасная загрузка конфигурации локали (только один раз)
local locale_config = {}
local locale_config_loaded = false

local function load_locale_config()
  if locale_config_loaded then
    return locale_config
  end
  
  local status, config = pcall(require, 'config.locale')
  if status then
    locale_config = config
    wezterm.log_info("Загружена конфигурация локали: язык = " .. (locale_config.force_language or "auto") .. ", локаль = " .. (locale_config.force_locale or "auto"))
  else
    wezterm.log_info("Конфигурация локали не найдена, используем системные настройки")
  end
  
  locale_config_loaded = true
  return locale_config
end

-- Глобальный кэш для локали и языка
local cached_locale = nil
local cached_language = nil
local cache_initialized = false

-- Функция для определения локали с приоритетом настроек WezTerm
local function get_system_locale()
  -- Если локаль уже кэширована, возвращаем её БЕЗ логирования
  if cached_locale then
    return cached_locale
  end
  
  local config = load_locale_config()
  
  -- Сначала проверяем принудительную настройку из конфигурации
  if config.force_locale then
    cached_locale = config.force_locale:lower()
    wezterm.log_info("Использована принудительная локаль из конфигурации: " .. cached_locale)
    return cached_locale
  end
  
  -- Затем проверяем переменные окружения WezTerm из environment.lua
  local wezterm_lang = os.getenv("LANG") or ""
  local wezterm_lc_all = os.getenv("LC_ALL") or ""
  local wezterm_lc_time = os.getenv("LC_TIME") or ""
  
  wezterm.log_info("Переменные окружения - LANG: " .. wezterm_lang .. ", LC_ALL: " .. wezterm_lc_all .. ", LC_TIME: " .. wezterm_lc_time)
  
  -- Приоритет: LC_ALL > LC_TIME > LANG
  local locale = wezterm_lc_all
  if locale == "" then
    locale = wezterm_lc_time
  end
  if locale == "" then
    locale = wezterm_lang
  end
  if locale == "" then
    locale = "en_US.UTF-8" -- fallback
  end
  
  -- Кэшируем результат
  cached_locale = locale:lower()
  wezterm.log_info("Определенная локаль в platform.lua: " .. cached_locale)
  return cached_locale
end

-- Функция для определения языка из локали
local function get_language_from_locale(locale)
  -- Если язык уже кэширован, возвращаем его БЕЗ логирования
  if cached_language then
    return cached_language
  end
  
  local config = load_locale_config()
  
  -- Сначала проверяем принудительную настройку из конфигурации
  if config.force_language then
    cached_language = config.force_language
    wezterm.log_info("Использован принудительный язык из конфигурации: " .. cached_language)
    return cached_language
  end
  
  -- Определяем язык из локали
  if locale:find("ru") then
    cached_language = "ru"
  elseif locale:find("de") then
    cached_language = "de"
  elseif locale:find("fr") then
    cached_language = "fr"
  elseif locale:find("es") then
    cached_language = "es"
  elseif locale:find("it") then
    cached_language = "it"
  elseif locale:find("pt") then
    cached_language = "pt"
  elseif locale:find("zh") then
    cached_language = "zh"
  elseif locale:find("ja") then
    cached_language = "ja"
  elseif locale:find("ko") then
    cached_language = "ko"
  else
    cached_language = "en" -- default to English
  end
  
  wezterm.log_info("Определен язык из локали: " .. cached_language)
  return cached_language
end

-- Функция для получения информации о процессоре
local function get_arch_info()
  local target = wezterm.target_triple
  local arch = "unknown"
  
  if target:find("x86_64") then
    arch = "x86_64"
  elseif target:find("aarch64") or target:find("arm64") then
    arch = "arm64"
  elseif target:find("i686") then
    arch = "i686"
  end
  
  return arch
end

-- Функция для принудительного обновления локали
local function refresh_locale_info(platform_info)
  -- Сбрасываем весь кэш
  cached_locale = nil
  cached_language = nil
  cache_initialized = false
  locale_config_loaded = false
  locale_config = {}
  
  local locale = get_system_locale()
  local language = get_language_from_locale(locale)
  
  platform_info.locale = locale
  platform_info.language = language
  cache_initialized = true
  
  wezterm.log_info("Обновлена локаль: " .. locale .. ", язык: " .. language)
  return platform_info
end

-- НОВАЯ ФУНКЦИЯ: Безопасное выполнение команды с проверкой результата
local function safe_execute(cmd)
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then
    return nil, "Failed to execute command"
  end
  
  local result = handle:read("*a")
  local success = handle:close()
  
  if success then
    return result
  else
    return nil, result
  end
end

-- НОВАЯ ФУНКЦИЯ: Получение списка файлов в директории (кроссплатформенно)
local function get_files_in_directory(dir, pattern)
  local files = {}
  
  if not dir or dir == "" then
    return files
  end
  
  local cmd
  if is_win then
    -- Windows команда для получения файлов
    -- Используем where или dir в зависимости от паттерна
    if pattern then
      -- Экранируем путь для Windows
      dir = dir:gsub("/", "\\")
      cmd = string.format('dir /b /s "%s\\%s" 2>nul', dir, pattern)
    else
      dir = dir:gsub("/", "\\")
      cmd = string.format('dir /b /s "%s" 2>nul', dir)
    end
  else
    -- Unix-подобные системы
    if pattern then
      cmd = string.format('find "%s" -type f -name "%s" 2>/dev/null', dir, pattern)
    else
      cmd = string.format('find "%s" -type f 2>/dev/null', dir)
    end
  end
  
  local result, err = safe_execute(cmd)
  if result then
    -- Разбираем результат по строкам
    for line in result:gmatch("[^\r\n]+") do
      local trimmed = line:match("^%s*(.-)%s*$") -- trim whitespace
      if trimmed and trimmed ~= "" then
        -- На Windows преобразуем обратные слеши в прямые для консистентности
        if is_win then
          trimmed = trimmed:gsub("\\", "/")
        end
        table.insert(files, trimmed)
      end
    end
  else
    wezterm.log_warn("Ошибка при получении списка файлов: " .. (err or "unknown error"))
  end
  
  return files
end

-- НОВАЯ ФУНКЦИЯ: Проверка существования директории
local function directory_exists(path)
  if not path or path == "" then
    return false
  end
  
  local cmd
  
  if is_win then
    path = path:gsub("/", "\\")
    cmd = string.format('if exist "%s\\" (echo 1) else (echo 0)', path)
  else
    cmd = string.format('[ -d "%s" ] && echo 1 || echo 0', path)
  end
  
  local result, err = safe_execute(cmd)
  if result then
    return result:match("1") ~= nil
  end
  
  return false
end

-- НОВАЯ ФУНКЦИЯ: Проверка существования файла
local function file_exists(path)
  if not path or path == "" then
    return false
  end
  
  local cmd
  
  if is_win then
    path = path:gsub("/", "\\")
    cmd = string.format('if exist "%s" (echo 1) else (echo 0)', path)
  else
    cmd = string.format('[ -f "%s" ] && echo 1 || echo 0', path)
  end
  
  local result, err = safe_execute(cmd)
  if result then
    return result:match("1") ~= nil
  end
  
  return false
end

-- НОВАЯ ФУНКЦИЯ: Нормализация путей для текущей платформы
local function normalize_path(path)
  if not path then return "" end
  
  if is_win then
    -- Для Windows преобразуем / в \
    return path:gsub("/", "\\")
  else
    -- Для Unix преобразуем \ в /
    return path:gsub("\\", "/")
  end
end

-- НОВАЯ ФУНКЦИЯ: Объединение путей
local function join_paths(...)
  local separator = is_win and "\\" or "/"
  
  local parts = {...}
  local result = ""
  
  for i, part in ipairs(parts) do
    if part and part ~= "" then
      if result == "" then
        result = part
      else
        -- Убираем лишние разделители
        if result:sub(-1) == separator or result:sub(-1) == "/" or result:sub(-1) == "\\" then
          result = result:sub(1, -2)
        end
        if part:sub(1, 1) == separator or part:sub(1, 1) == "/" or part:sub(1, 1) == "\\" then
          part = part:sub(2)
        end
        result = result .. separator .. part
      end
    end
  end
  
  return normalize_path(result)
end

local function platform()
   -- Инициализируем кэш только один раз
   if not cache_initialized then
     cached_locale = get_system_locale()
     cached_language = get_language_from_locale(cached_locale)
     cache_initialized = true
   end
   
   local arch = get_arch_info()
   
   local platform_info = {
      is_win = is_win,
      is_linux = is_linux,
      is_mac = is_mac,
      is_wsl = is_wsl,
      arch = arch,
      target_triple = wezterm.target_triple,
      locale = cached_locale,
      language = cached_language,
      
      -- Добавляем новые функции для работы с файловой системой
      get_files_in_directory = get_files_in_directory,
      directory_exists = directory_exists,
      file_exists = file_exists,
      normalize_path = normalize_path,
      join_paths = join_paths,
      
      refresh_locale = function(self)
         return refresh_locale_info(self)
      end
   }
   
   return platform_info
end


return platform
