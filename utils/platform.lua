-- cat > ~/.config/wezterm/utils/platform.lua << 'EOF'
--
-- ОПИСАНИЕ: Определение операционной системы и локали
-- Этот модуль определяет операционную систему и локаль, на которой запущен WezTerm.
-- Результат используется для настройки платформо-зависимого поведения.
-- ПОЛНОСТЬЮ САМОДОСТАТОЧНЫЙ МОДУЛЬ - НЕ ЛОГИРУЕТ, ТОЛЬКО ВОЗВРАЩАЕТ ДАННЫЕ.
--
-- ЗАВИСИМОСТИ: НЕТ

local function is_found(str, pattern)
   return string.find(str, pattern) ~= nil
end

-- Функция для определения платформы (принимает target_triple как параметр)
local function platform(target_triple)
   if not target_triple then
      error("target_triple parameter is required")
   end
   -- Определяем платформу заранее
   local is_win = is_found(target_triple, 'windows')
   local is_linux = is_found(target_triple, 'linux')
   local is_mac = is_found(target_triple, 'apple')
   local is_wsl = os.getenv("WSL_DISTRO_NAME") ~= nil
   
   -- Функция для получения информации о процессоре
   local function get_arch_info()
     local arch = "unknown"
     
     if target_triple:find("x86_64") then
       arch = "x86_64"
     elseif target_triple:find("aarch64") or target_triple:find("arm64") then
       arch = "arm64"
     elseif target_triple:find("i686") then
       arch = "i686"
     end
     
     return arch
   end
   
   local arch = get_arch_info()
   
   local platform_info = {
      is_win = is_win,
      is_linux = is_linux,
      is_mac = is_mac,
      is_wsl = is_wsl,
      arch = arch,
      target_triple = target_triple,
   }
   
   return platform_info
end

-- Глобальный кэш для локали и языка
local cached_locale = nil
local cached_language = nil
local cache_initialized = false

-- Функция для определения локали без логирования
local function get_system_locale()
  if cached_locale then
    return cached_locale
  end
  
  -- Проверяем переменные окружения
  local lang = os.getenv("LANG") or ""
  local lc_all = os.getenv("LC_ALL") or ""
  local lc_time = os.getenv("LC_TIME") or ""
  
  -- Приоритет: LC_ALL > LC_TIME > LANG
  local locale = lc_all
  if locale == "" then
    locale = lc_time
  end
  if locale == "" then
    locale = lang
  end
  if locale == "" then
    locale = "en_US.UTF-8" -- fallback
  end
  
  cached_locale = locale:lower()
  return cached_locale
end

-- Функция для определения языка из локали
local function get_language_from_locale(locale)
  if cached_language then
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
  
  return cached_language
end

-- Безопасное выполнение команды с проверкой результата
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

-- Получение списка файлов в директории (кроссплатформенно)
local function get_files_in_directory(dir, pattern, is_win)
  local files = {}
  
  if not dir or dir == "" then
    return files
  end
  
  local cmd
  if is_win then
    if pattern then
      dir = dir:gsub("/", "\\")
      cmd = string.format('dir /b /s "%s\\%s" 2>nul', dir, pattern)
    else
      dir = dir:gsub("/", "\\")
      cmd = string.format('dir /b /s "%s" 2>nul', dir)
    end
  else
    if pattern then
      cmd = string.format('find "%s" -type f -name "%s" 2>/dev/null', dir, pattern)
    else
      cmd = string.format('find "%s" -type f 2>/dev/null', dir)
    end
  end
  
  local result, err = safe_execute(cmd)
  if result then
    for line in result:gmatch("[^\r\n]+") do
      local trimmed = line:match("^%s*(.-)%s*$")
      if trimmed and trimmed ~= "" then
        if is_win then
          trimmed = trimmed:gsub("\\", "/")
        end
        table.insert(files, trimmed)
      end
    end
  end
  
  return files
end

-- Проверка существования директории
local function directory_exists(path, is_win)
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

-- Проверка существования файла
local function file_exists(path, is_win)
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

-- Нормализация путей для текущей платформы
local function normalize_path(path, is_win)
  if not path then return "" end
  
  if is_win then
    return path:gsub("/", "\\")
  else
    return path:gsub("\\", "/")
  end
end

-- Объединение путей
local function join_paths(is_win, ...)
  local separator = is_win and "\\" or "/"
  
  local parts = {...}
  local result = ""
  
  for i, part in ipairs(parts) do
    if part and part ~= "" then
      if result == "" then
        result = part
      else
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
  
  return normalize_path(result, is_win)
end

-- Главная функция создания platform объекта
local function create_platform_info(target_triple)
   -- Инициализируем кэш только один раз
   if not cache_initialized then
     cached_locale = get_system_locale()
     cached_language = get_language_from_locale(cached_locale)
     cache_initialized = true
   end
   
   local base_info = platform(target_triple)
   
   -- Добавляем локаль и язык
   base_info.locale = cached_locale
   base_info.language = cached_language
   
   -- Добавляем файловые функции с привязкой к платформе
   base_info.get_files_in_directory = function(dir, pattern)
     return get_files_in_directory(dir, pattern, base_info.is_win)
   end
   
   base_info.directory_exists = function(path)
     return directory_exists(path, base_info.is_win)
   end
   
   base_info.file_exists = function(path)
     return file_exists(path, base_info.is_win)
   end
   
   base_info.normalize_path = function(path)
     return normalize_path(path, base_info.is_win)
   end
   
   base_info.join_paths = function(...)
     return join_paths(base_info.is_win, ...)
   end
   
   base_info.refresh_locale = function(self)
     -- Сбрасываем кэш для обновления
     cached_locale = nil
     cached_language = nil
     cache_initialized = false
     
     cached_locale = get_system_locale()
     cached_language = get_language_from_locale(cached_locale)
     cache_initialized = true
     
     self.locale = cached_locale
     self.language = cached_language
     
     return self
   end
   
   return base_info
end

return create_platform_info
