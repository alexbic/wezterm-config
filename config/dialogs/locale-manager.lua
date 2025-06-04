-- cat > ~/.config/wezterm/config/dialogs/locale-manager.lua << 'EOF'
--
-- ОПИСАНИЕ: UI управления локализацией WezTerm
-- Интерфейс для переключения между языками и управления локалями.
-- Использует новую систему кэширования локализации.
--
-- ЗАВИСИМОСТИ: utils.environment, config.environment.globals

local wezterm = require('wezterm')
local env_utils = require('utils.environment')
local globals = require('config.environment.globals')

local M = {}

-- Получение списка доступных и недоступных языков
local function get_language_status()
  local create_platform_info = require('utils.platform')
  local platform = create_platform_info(wezterm.target_triple)
  
  local available_languages = env_utils.scan_locale_files(wezterm.config_dir, platform)
  local stats = env_utils.get_locale_stats(available_languages)
  
  local result = {
    available = {},
    missing = {},
    current = os.getenv("WEZTERM_LANG") or globals.DEFAULT_LANGUAGE
  }
  
  -- Проверяем каждый поддерживаемый язык
  for _, lang_code in ipairs(globals.SUPPORTED_LANGUAGES) do
    if available_languages[lang_code] then
      table.insert(result.available, {
        code = lang_code,
        name = available_languages[lang_code].name,
        locale = available_languages[lang_code].locale,
        keys = stats.languages[lang_code] and stats.languages[lang_code].keys or 0
      })
    else
      table.insert(result.missing, {
        code = lang_code,
        name = "Unknown Language",
        status = "Файл не найден"
      })
    end
  end
  
  return result
end

-- Создание выборов для InputSelector
local function create_choices(language_status)
  local choices = {}
  
  -- Заголовок
  table.insert(choices, {
    id = "header",
    label = "🌍 УПРАВЛЕНИЕ ЛОКАЛИЗАЦИЕЙ"
  })
  
  table.insert(choices, {
    id = "separator1", 
    label = "─────────────────────────────────────"
  })
  
  -- Текущий язык
  table.insert(choices, {
    id = "current",
    label = "📍 Текущий язык: " .. language_status.current
  })
  
  table.insert(choices, {
    id = "separator2", 
    label = "─────────────────────────────────────"
  })
  
  -- Доступные языки
  if #language_status.available > 0 then
    table.insert(choices, {
      id = "available_header",
      label = "✅ ДОСТУПНЫЕ ЯЗЫКИ:"
    })
    
    for _, lang in ipairs(language_status.available) do
      local status_icon = (lang.code == language_status.current) and "🟢" or "⚪"
      local label = string.format("%s %s (%s) - %d ключей", 
        status_icon, lang.name, lang.code, lang.keys)
      
      table.insert(choices, {
        id = "switch_" .. lang.code,
        label = label
      })
    end
  end
  
  -- Недоступные языки
  if #language_status.missing > 0 then
    table.insert(choices, {
      id = "separator3", 
      label = "─────────────────────────────────────"
    })
    
    table.insert(choices, {
      id = "missing_header",
      label = "❌ НЕДОСТУПНЫЕ ЯЗЫКИ:"
    })
    
    for _, lang in ipairs(language_status.missing) do
      table.insert(choices, {
        id = "create_" .. lang.code,
        label = "📝 Создать " .. lang.code .. " локаль"
      })
    end
  end
  
  -- Управляющие команды
  table.insert(choices, {
    id = "separator4", 
    label = "─────────────────────────────────────"
  })
  
  table.insert(choices, {
    id = "regenerate",
    label = "🔄 Перегенерировать кэш текущего языка"
  })
  
  table.insert(choices, {
    id = "stats",
    label = "📊 Показать статистику локализации"
  })
  
  table.insert(choices, {
    id = "exit",
    label = "🚪 Выход"
  })
  
  return choices
end

-- Обработка выбора пользователя
local function handle_choice(window, pane, choice_id, language_status)
  if not choice_id or choice_id == "exit" or choice_id:match("separator") or choice_id:match("_header") or choice_id == "header" or choice_id == "current" then
    return
  end
  
  local create_platform_info = require('utils.platform')
  local platform = create_platform_info(wezterm.target_triple)
  
  if choice_id:match("^switch_") then
    -- Переключение языка
    local lang_code = choice_id:match("^switch_(.+)$")
    if lang_code and lang_code ~= language_status.current then
      local success = env_utils.switch_language_and_rebuild(wezterm.config_dir, platform, lang_code)
      if success then
        window:toast_notification("Локализация", "Язык переключен на: " .. lang_code, nil, 3000)
        -- Перезагружаем конфигурацию
        wezterm.reload_configuration()
      else
        window:toast_notification("Ошибка", "Не удалось переключить язык", nil, 3000)
      end
    end
    
  elseif choice_id:match("^create_") then
    -- Создание нового языка
    local lang_code = choice_id:match("^create_(.+)$")
    window:toast_notification("Информация", "Создание локали " .. lang_code .. " пока не реализовано", nil, 3000)
    
  elseif choice_id == "regenerate" then
    -- Перегенерация кэша
    local success = env_utils.rebuild_locale_cache_file(wezterm.config_dir, platform, language_status.current)
    if success then
      window:toast_notification("Локализация", "Кэш перегенерирован для: " .. language_status.current, nil, 3000)
      -- Перезагружаем конфигурацию
      wezterm.reload_configuration()
    else
      window:toast_notification("Ошибка", "Не удалось перегенерировать кэш", nil, 3000)
    end
    
  elseif choice_id == "stats" then
    -- Показ статистики
    local available_languages = env_utils.scan_locale_files(wezterm.config_dir, platform)
    local stats = env_utils.get_locale_stats(available_languages)
    local stats_text = string.format("Всего языков: %d, Максимум ключей: %d", 
      stats.total_languages, stats.total_keys)
    window:toast_notification("Статистика локализации", stats_text, nil, 5000)
  end
end

-- Главная функция показа менеджера локализации
M.show_locale_manager = function(window, pane)
  local language_status = get_language_status()
  local choices = create_choices(language_status)
  
  window:perform_action(
    wezterm.action.InputSelector({
      action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
        handle_choice(inner_window, inner_pane, id, language_status)
      end),
      title = "🌍 Менеджер локализации WezTerm",
      description = "Выберите действие для управления языками",
      fuzzy = false,
      alphabet = "",
      choices = choices,
    }),
    pane
  )
end

return M
