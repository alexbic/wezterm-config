-- cat > ~/.config/wezterm/utils/dialog.lua << 'EOF'
--
-- ОПИСАНИЕ: Универсальная система диалоговых окон для WezTerm
-- Создание красивых диалогов с адаптивными рамками и параметризованными цветами
-- ПОЛНОСТЬЮ САМОДОСТАТОЧНЫЙ МОДУЛЬ - все зависимости передаются как параметры
--
-- ЗАВИСИМОСТИ: НЕТ

local M = {}

-- Функция подсчета длины UTF-8 строки
local function utf8_len(str)
  if not str then return 0 end
  local len = 0
  for _ in str:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
    len = len + 1
  end
  return len
end

-- Главная функция создания диалогового окна
M.create_dialog_box = function(config)
  local wezterm = require('wezterm')
  
  -- Новые параметры для единообразного интерфейса
  local action_type = config.action_type or "session"
  local icon_key = config.icon_key or "workspace"
  local current_value = config.current_value or "default"
  local default_value = config.default_value
  
  -- Получаем цвета: если передан ключ, получаем из централизованной системы, иначе используем как цвет
  local function get_color_value(color_param, default_color)
    if not color_param then return default_color end
    if type(color_param) == "string" and color_param:match("^dialog_") then
      local colors = require("config.environment.colors")
      local env_utils = require("utils.environment")
      return env_utils.get_color(colors, color_param)
    else
      return color_param
    end
  end
  
  local border_color = get_color_value(config.border_color, "#BD93F9")
  local content_color = get_color_value(config.content_color, "#F8F8F2")
  local hint_color = get_color_value(config.hint_color, "#FFB86C")
  
  -- Создаем строки содержимого
  local lines = {}
  if config.lines then
    -- Совместимость со старым API
    lines = config.lines
  else
    -- Новый единообразный шаблон
    local icons = require("config.environment.icons")
    local env_utils = require("utils.environment")
    local icon = env_utils.get_icon(icons, icon_key)
    
    -- Определяем правильное название по типу
    local type_names = {
      workspace = "Текущая сессия",
      window = "Текущее окно", 
      tab = "Текущая вкладка"
    }
    local display_name = type_names[icon_key] or "Текущая сессия"
    
    -- Добавляем placeholder для цветной первой строки
    table.insert(lines, "PLACEHOLDER_FOR_COLORED_FIRST_LINE")
    table.insert(lines, "Введите имя в поле ввода ниже:")
  end
  
  local hint_text = config.hint_text or "enter: ok  esc: cancel"
  local min_width = config.min_width or 40
  local max_width = config.max_width or 80
  local padding = 2

  -- Вычисляем максимальную ширину контента
  local content_width = 0
  for _, line in ipairs(lines) do
    -- Для placeholder используем примерную длину цветной строки
    if line == "PLACEHOLDER_FOR_COLORED_FIRST_LINE" then
      local icons = require("config.environment.icons")
      local env_utils = require("utils.environment")
      local icon = env_utils.get_icon(icons, icon_key)
      local type_names = {
        workspace = "Текущая сессия",
        window = "Текущее окно",
        tab = "Текущая вкладка"
      }
      local display_name = type_names[icon_key] or "Текущая сессия"
      local estimated_len = utf8_len(icon .. " " .. display_name .. ": " .. current_value)
      content_width = math.max(content_width, estimated_len)
    else
      content_width = math.max(content_width, utf8_len(line))
    end
  end

  -- Вычисляем ширину подсказки
  local hint_full = "┤ " .. hint_text .. " ├"
  local hint_width = utf8_len(hint_full)
  local min_tail = 4

  -- Определяем итоговую ширину рамки
  local dynamic_width = math.max(content_width + padding * 2, hint_width + min_tail)
  local box_width = math.max(min_width, math.min(max_width, dynamic_width))
  local inner_width = box_width - 2

  -- Создаем массив форматированных элементов
  local format_elements = {}

  -- Верхняя рамка
  table.insert(format_elements, { Foreground = { Color = border_color } })
  table.insert(format_elements, { Text = "╭" .. string.rep("─", inner_width) .. "╮\n" })

  -- Пустая строка после верхней рамки
  table.insert(format_elements, { Foreground = { Color = border_color } })
  table.insert(format_elements, { Text = "│" .. string.rep(" ", inner_width) .. "│\n" })

  -- Контентные строки
  for i, line in ipairs(lines) do
    -- Начало строки с рамкой
    table.insert(format_elements, { Foreground = { Color = border_color } })
    table.insert(format_elements, { Text = "│" .. string.rep(" ", padding) })

    -- Специальная обработка для placeholder цветной первой строки
    if line == "PLACEHOLDER_FOR_COLORED_FIRST_LINE" then
      local icons = require("config.environment.icons")
      local env_utils = require("utils.environment")
      local icon = env_utils.get_icon(icons, icon_key)
      
      local type_names = {
        workspace = "Текущая сессия",
        window = "Текущее окно",
        tab = "Текущая вкладка"
      }
      local display_name = type_names[icon_key] or "Текущая сессия"
      
      -- Иконка в цвете рамки
      table.insert(format_elements, { Foreground = { Color = border_color } })
      table.insert(format_elements, { Text = icon .. " " })
      
      -- Название в бирюзовом
      table.insert(format_elements, { Foreground = { Color = border_color } })
      table.insert(format_elements, { Text = display_name })
      
      -- Двоеточие в белом
      table.insert(format_elements, { Foreground = { Color = content_color } })
      table.insert(format_elements, { Text = ": " })
      
      -- Значение в белом
      table.insert(format_elements, { Foreground = { Color = content_color } })
      table.insert(format_elements, { Text = current_value })
      
      -- Вычисляем оставшееся место
      local colored_line_len = utf8_len(icon .. " " .. display_name .. ": " .. current_value)
      local remaining = inner_width - padding * 2 - colored_line_len
      if remaining > 0 then
        table.insert(format_elements, { Foreground = { Color = content_color } })
        table.insert(format_elements, { Text = string.rep(" ", remaining) })
      end
    else
      -- Обычная строка
      local line_len = utf8_len(line)
      local remaining = inner_width - padding * 2 - line_len
      
      if remaining >= 0 then
        table.insert(format_elements, { Foreground = { Color = content_color } })
        table.insert(format_elements, { Text = line })
        table.insert(format_elements, { Foreground = { Color = content_color } })
        table.insert(format_elements, { Text = string.rep(" ", remaining) })
      else
        -- Обрезаем слишком длинную строку
        local max_len = inner_width - padding * 2 - 3
        local truncated = string.sub(line, 1, max_len) .. "..."
        table.insert(format_elements, { Foreground = { Color = content_color } })
        table.insert(format_elements, { Text = truncated })
      end
    end

    -- Отступ справа и закрывающая рамка
    table.insert(format_elements, { Foreground = { Color = border_color } })
    table.insert(format_elements, { Text = string.rep(" ", padding) })
    table.insert(format_elements, { Foreground = { Color = border_color } })
    table.insert(format_elements, { Text = "│\n" })

    -- Пустая строка между контентными строками (кроме последней)
    if i < #lines then
      table.insert(format_elements, { Foreground = { Color = border_color } })
      table.insert(format_elements, { Text = "│" .. string.rep(" ", inner_width) .. "│\n" })
    end
  end

  -- Пустая строка перед нижней рамкой
  table.insert(format_elements, { Foreground = { Color = border_color } })
  table.insert(format_elements, { Text = "│" .. string.rep(" ", inner_width) .. "│\n" })

  -- Нижняя рамка с встроенной подсказкой
  local left_border_width = inner_width - hint_width
  if left_border_width < 2 then
    -- Если подсказка слишком длинная, обрезаем её
    local max_hint_len = inner_width - 6
    hint_text = string.sub(hint_text, 1, max_hint_len)
    hint_full = "┤ " .. hint_text .. " ├"
    hint_width = utf8_len(hint_full)
    left_border_width = inner_width - hint_width
  end

  table.insert(format_elements, { Foreground = { Color = border_color } })
  table.insert(format_elements, { Text = "╰" .. string.rep("─", left_border_width) })
  table.insert(format_elements, { Foreground = { Color = border_color } })
  table.insert(format_elements, { Text = "┤ " })
  table.insert(format_elements, { Foreground = { Color = hint_color } })
  table.insert(format_elements, { Text = hint_text })
  table.insert(format_elements, { Foreground = { Color = border_color } })
  table.insert(format_elements, { Text = " ├" })
  table.insert(format_elements, { Foreground = { Color = border_color } })
  table.insert(format_elements, { Text = "╯" })

  return wezterm.format(format_elements)
end

return M
