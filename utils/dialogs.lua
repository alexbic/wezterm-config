-- cat > ~/.config/wezterm/utils/dialogs.lua << 'EOF'
--
-- ОПИСАНИЕ: Утилиты для создания диалогов с улучшенным оформлением
-- Централизованные функции для создания красивых диалогов сохранения с рамками и подсказками.
--
-- ЗАВИСИМОСТИ: wezterm, config.environment

local wezterm = require 'wezterm'

local M = {}

-- === ТИПЫ ДИАЛОГОВ ===
M.DIALOG_TYPES = {
  SAVE_WORKSPACE = "save_workspace",
  SAVE_WINDOW = "save_window",
  SAVE_TAB = "save_tab"
}

-- === ФУНКЦИЯ ПОДСЧЕТА ДЛИНЫ UTF-8 СТРОКИ ===
local function utf8_len(str)
  if not str then return 0 end
  local len = 0
  for _ in str:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
    len = len + 1
  end
  return len
end

-- === ФУНКЦИЯ СОЗДАНИЯ РАМКИ ЧЕРЕЗ wezterm.format ===
local function create_format_box(lines_data, hint_text, border_color, content_color, hint_color)
  local min_width = 40
  local max_width = 80
  local pad = 2

  -- Вычисляем максимальную ширину контента
  local content_width = 0
  for _, line_data in ipairs(lines_data) do
    local line_len = 0
    for _, part in ipairs(line_data) do
      if part.text then
        line_len = line_len + utf8_len(part.text)
      end
    end
    content_width = math.max(content_width, line_len)
  end

  -- Учитываем подсказки с правильным форматированием
  local hint_full = "┤ " .. hint_text .. " ├"
  local hint_width = utf8_len(hint_full)
  local min_tail = 4 -- минимальный хвостик справа

  -- Определяем итоговую ширину рамки
  local dynamic_width = math.max(content_width + pad * 2, hint_width + min_tail)
  local box_width = math.max(min_width, math.min(max_width, dynamic_width))
  local inner_width = box_width - 2  -- без рамок │ │

  -- Создаем массив форматированных элементов
  local format_elements = {}

  -- Верхняя рамка
  table.insert(format_elements, { Foreground = { Color = border_color } })
  table.insert(format_elements, { Text = "╭" .. string.rep("─", inner_width) .. "╮\n" })

  -- Пустая строка после верхней рамки
  table.insert(format_elements, { Foreground = { Color = border_color } })
  table.insert(format_elements, { Text = "│" .. string.rep(" ", inner_width) .. "│\n" })

  -- Контентные строки
  for i, line_data in ipairs(lines_data) do
    -- Начало строки с рамкой
    table.insert(format_elements, { Foreground = { Color = border_color } })
    table.insert(format_elements, { Text = "│" .. string.rep(" ", pad) })

    -- Контент строки с цветами
    local line_len = 0
    for _, part in ipairs(line_data) do
      if part.color then
        table.insert(format_elements, { Foreground = { Color = part.color } })
      else
        table.insert(format_elements, { Foreground = { Color = content_color } })
      end
      if part.text then
        table.insert(format_elements, { Text = part.text })
        line_len = line_len + utf8_len(part.text)
      end
    end

    -- Заполняем оставшееся место пробелами
    local remaining = inner_width - pad * 2 - line_len
    if remaining > 0 then
      table.insert(format_elements, { Foreground = { Color = content_color } })
      table.insert(format_elements, { Text = string.rep(" ", remaining) })
    end

    -- Отступ справа и закрывающая рамка
    table.insert(format_elements, { Text = string.rep(" ", pad) })
    table.insert(format_elements, { Foreground = { Color = border_color } })
    table.insert(format_elements, { Text = "│\n" })

    -- Пустая строка между контентными строками (кроме последней)
    if i < #lines_data then
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
    local max_hint_len = inner_width - 6 -- ┤ ├ + минимум 2 символа рамки
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

  return format_elements
end

-- === СОЗДАНИЕ ОПИСАНИЯ ДИАЛОГА СОХРАНЕНИЯ ===
M.create_save_description = function(wezterm, dialog_type, current_info, environment, icons, colors, env_utils)
  local t = environment.locale.t

  -- Цвета для разных типов диалогов
  local dialog_colors = {
    [M.DIALOG_TYPES.SAVE_WORKSPACE] = {
      border = env_utils.get_color(colors, "dialog_save_border") or "#50FA7B",
      content = env_utils.get_color(colors, "dialog_content") or "#F8F8F2",
      hint = env_utils.get_color(colors, "dialog_hint") or "#FFB86C"
    },
    [M.DIALOG_TYPES.SAVE_WINDOW] = {
      border = env_utils.get_color(colors, "dialog_border") or "#BD93F9",
      content = env_utils.get_color(colors, "dialog_content") or "#F8F8F2",
      hint = env_utils.get_color(colors, "dialog_hint") or "#FFB86C"
    },
    [M.DIALOG_TYPES.SAVE_TAB] = {
      border = env_utils.get_color(colors, "dialog_delete_border") or "#FF5555",
      content = env_utils.get_color(colors, "dialog_content") or "#F8F8F2",
      hint = env_utils.get_color(colors, "dialog_hint") or "#FFB86C"
    }
  }

  local color_scheme = dialog_colors[dialog_type] or dialog_colors[M.DIALOG_TYPES.SAVE_WORKSPACE]

  -- Подготавливаем данные строк с цветовой информацией
  local lines_data = {}

  -- Заголовок диалога
  if dialog_type == M.DIALOG_TYPES.SAVE_WORKSPACE then
    local workspace_icon = env_utils.get_icon(icons, "workspace")
    table.insert(lines_data, {
      { text = workspace_icon .. " " .. t("save_workspace_tab_title"), color = color_scheme.content }
    })
    
    table.insert(lines_data, {
      { text = t("current_workspace", current_info or "default"), color = color_scheme.content }
    })
  elseif dialog_type == M.DIALOG_TYPES.SAVE_WINDOW then
    local window_icon = env_utils.get_icon(icons, "window")
    table.insert(lines_data, {
      { text = window_icon .. " " .. t("save_window_tab_title"), color = color_scheme.content }
    })
    
    table.insert(lines_data, {
      { text = t("save_window_default", current_info or "window"), color = color_scheme.content }
    })
  elseif dialog_type == M.DIALOG_TYPES.SAVE_TAB then
    local tab_icon = env_utils.get_icon(icons, "tab")
    table.insert(lines_data, {
      { text = tab_icon .. " " .. t("save_tab_tab_title"), color = color_scheme.content }
    })
    
    table.insert(lines_data, {
      { text = t("save_tab_default", current_info or "tab"), color = color_scheme.content }
    })
  end

  -- Инструкция
  table.insert(lines_data, {
    { text = "Введите имя в поле ввода ниже:", color = color_scheme.content }
  })

  -- Создаем рамку
  local format_elements = create_format_box(
    lines_data,
    "enter: сохранить  esc: отмена",
    color_scheme.border,
    color_scheme.content,
    color_scheme.hint
  )

  return wezterm.format(format_elements)
end

-- === СОЗДАНИЕ ДИАЛОГА ЗАГРУЗКИ ===
M.create_load_description = function(wezterm, sessions_count, environment, icons, colors, env_utils)
  local t = environment.locale.t
  
  local color_scheme = {
    border = env_utils.get_color(colors, "dialog_load_border") or "#8BE9FD",
    content = env_utils.get_color(colors, "dialog_content") or "#F8F8F2",
    hint = env_utils.get_color(colors, "dialog_hint") or "#FFB86C"
  }

  local lines_data = {
    {
      { text = "📂 " .. t("loading_sessions_title"), color = color_scheme.content }
    },
    {
      { text = t("loading_sessions_description"), color = color_scheme.content }
    },
    {
      { text = string.format("Найдено сессий: %d", sessions_count or 0), color = color_scheme.content }
    }
  }

  local format_elements = create_format_box(
    lines_data,
    "enter: загрузить  /: поиск  esc: отмена",
    color_scheme.border,
    color_scheme.content,
    color_scheme.hint
  )

  return wezterm.format(format_elements)
end

-- === СОЗДАНИЕ ДИАЛОГА УДАЛЕНИЯ ===
M.create_delete_description = function(wezterm, sessions_count, environment, icons, colors, env_utils)
  local t = environment.locale.t
  
  local color_scheme = {
    border = env_utils.get_color(colors, "dialog_delete_border") or "#FF5555",
    content = env_utils.get_color(colors, "dialog_content") or "#F8F8F2",
    hint = env_utils.get_color(colors, "dialog_hint") or "#FFB86C"
  }

  local lines_data = {
    {
      { text = "🗑️ " .. t("deleting_sessions_title"), color = color_scheme.content }
    },
    {
      { text = t("deleting_sessions_description"), color = color_scheme.content }
    },
    {
      { text = string.format("Найдено сессий: %d", sessions_count or 0), color = color_scheme.content }
    }
  }

  local format_elements = create_format_box(
    lines_data,
    "enter: удалить  /: поиск  esc: отмена",
    color_scheme.border,
    color_scheme.content,
    color_scheme.hint
  )

  return wezterm.format(format_elements)
end

return M
