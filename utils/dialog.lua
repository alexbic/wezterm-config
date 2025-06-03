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
  
  local lines = config.lines or {}
  local hint_text = config.hint_text or "enter: ok  esc: cancel"
  local min_width = config.min_width or 40
  local max_width = config.max_width or 80
  local border_color = config.border_color or "#BD93F9"
  local content_color = config.content_color or "#F8F8F2"
  local hint_color = config.hint_color or "#FFB86C"
  local padding = 2

  -- Вычисляем максимальную ширину контента
  local content_width = 0
  for _, line in ipairs(lines) do
    content_width = math.max(content_width, utf8_len(line))
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
    local line_len = utf8_len(line)
    local remaining = inner_width - padding * 2 - line_len
    
    -- Начало строки с рамкой
    table.insert(format_elements, { Foreground = { Color = border_color } })
    table.insert(format_elements, { Text = "│" .. string.rep(" ", padding) })

    -- Контент строки
    if remaining >= 0 then
      table.insert(format_elements, { Foreground = { Color = content_color } })
      table.insert(format_elements, { Text = line })
      table.insert(format_elements, { Text = string.rep(" ", remaining) })
    else
      -- Обрезаем слишком длинную строку
      local max_len = inner_width - padding * 2 - 3
      local truncated = string.sub(line, 1, max_len) .. "..."
      table.insert(format_elements, { Foreground = { Color = content_color } })
      table.insert(format_elements, { Text = truncated })
    end

    -- Отступ справа и закрывающая рамка
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
  table.insert(format_elements, { Foreground = { Color = hint_color } })
  table.insert(format_elements, { Text = hint_full })
  table.insert(format_elements, { Foreground = { Color = border_color } })
  table.insert(format_elements, { Text = "╯" })

  return wezterm.format(format_elements)
end

return M
