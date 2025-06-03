-- cat > ~/.config/wezterm/utils/dialog.lua << 'EOF'
--
-- ОПИСАНИЕ: Универсальная система диалоговых окон для WezTerm
-- Создание красивых диалогов с адаптивными рамками, правильным выравниванием и цветовым оформлением.
-- ПОЛНОСТЬЮ САМОДОСТАТОЧНЫЙ МОДУЛЬ - все зависимости передаются как параметры.
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

-- Функция усечения строки с многоточием
local function truncate_string(str, max_width)
  if not str then return "" end
  if utf8_len(str) <= max_width then
    return str
  end
  
  local result = ""
  local count = 0
  for char in str:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
    if count >= max_width - 1 then
      break
    end
    result = result .. char
    count = count + 1
  end
  return result .. "…"
end

-- Функция создания цветного диалога
-- Универсальная функция для создания диалогов разных типов
M.create_save_dialog = function(dialog_type, workspace_name, environment, icons, colors, env_utils)
  local wezterm = require("wezterm")
  
  local dialog_configs = {
    workspace = {
      border_color = "dialog_workspace_border",
      icon = "workspace",
      title_key = "dialog_workspace_title"
    },
    window = {
      border_color = "dialog_window_border",
      icon = "window", 
      title_key = "dialog_window_title"
    },
    tab = {
      border_color = "dialog_tab_border",
      icon = "tab",
      title_key = "dialog_tab_title"
    }
  }
  
  local config = dialog_configs[dialog_type] or dialog_configs.workspace
  
  return M.create_dialog_box({
    lines = {
      env_utils.get_icon(icons, config.icon) .. " " .. environment.locale.t(config.title_key) .. " " .. workspace_name,
      environment.locale.t("dialog_input_prompt")
    },
    hint_text = environment.locale.t("dialog_hint_save"),
    min_width = 50,
    max_width = 80,
    border_color = env_utils.get_color(colors, config.border_color)
  })
end
M.create_dialog_box = function(config)
  local wezterm = require('wezterm')
  local colors = require('config.environment.colors')
  local env_utils = require('utils.environment')
  local icons = require('config.environment.icons')  
  local environment = require('config.environment')  local lines = config.lines or {}
  local hint_text = config.hint_text or ""
  local min_width = config.min_width or 40
  local max_width = config.max_width or 80
  local padding = config.padding or 2
  
  -- Цвета диалога
  local dialog_colors = {
    border = config.border_color or env_utils.get_color(colors, "dialog_workspace_border") or "#B8A8E8",
    content = config.border_color or env_utils.get_color(colors, "dialog_workspace_border") or "#B8A8E8",
    icon = env_utils.get_color(colors, "dialog_icon") or "#B8A8E8",
    label = env_utils.get_color(colors, "dialog_label") or "#4ECDC4",
    value = env_utils.get_color(colors, "dialog_value") or "#F8F8F2",
    text = env_utils.get_color(colors, "dialog_text") or "#F8F8F2",
    hint = env_utils.get_color(colors, "dialog_hint_text") or "#888888"
  }  -- Определяем максимальную ширину контента
  local content_width = 0
  for _, line in ipairs(lines) do
    content_width = math.max(content_width, utf8_len(line))
  end
  
  -- Вычисляем ширину подсказки (только текст + разделители)
  local hint_text_width = utf8_len(hint_text)
  local separators_width = 6 -- "┤ " + " ├─"
  local total_hint_width = hint_text_width + separators_width
  
  -- Вычисляем итоговую ширину рамки
  local required_width = math.max(
    content_width + padding * 2,
    total_hint_width + 4
  )
  local box_width = math.max(min_width, math.min(max_width, required_width))
  
  -- Если подсказка не влезает, обрезаем
  if total_hint_width > box_width - 4 then
    local available_hint_width = box_width - separators_width - 4
    hint_text = truncate_string(hint_text, available_hint_width)
    hint_text_width = utf8_len(hint_text)
    total_hint_width = hint_text_width + separators_width
  end
  
  -- Создаем форматированные элементы
  local format_elements = {}
  
  -- Верхняя рамка
  table.insert(format_elements, { Foreground = { Color = dialog_colors.border } })
  table.insert(format_elements, { Text = "╭" .. string.rep("─", box_width) .. "╮\n" })
  
  -- Пустая строка сверху
  table.insert(format_elements, { Foreground = { Color = dialog_colors.border } })
  table.insert(format_elements, { Text = "│" .. string.rep(" ", box_width) .. "│\n" })
  
  -- Строки контента
  for i, line in ipairs(lines) do
    local truncated = truncate_string(line, box_width - padding * 2)
    local content_len = utf8_len(truncated)
    local right_padding = box_width - padding - content_len
    
    -- Начало строки с рамкой
    table.insert(format_elements, { Foreground = { Color = dialog_colors.border } })
    table.insert(format_elements, { Text = "│" .. string.rep(" ", padding) })
    
    -- Контент строки с разными цветами
    if i == 1 then
      -- Первая строка - разбиваем на части: иконка + "Текущая сессия:" + имя
      local icon = env_utils.get_icon(icons, "workspace")
      local label_text = " " .. environment.locale.t("dialog_workspace_title") .. " "
      local workspace_name = truncated:match(label_text .. "(.+)$") or ""
      
      -- Иконка - цвет из переменной
      table.insert(format_elements, { Foreground = { Color = dialog_colors.icon } })
      table.insert(format_elements, { Text = icon })
      
      -- "Текущая сессия:" - бирюзовый цвет
      table.insert(format_elements, { Foreground = { Color = dialog_colors.label } })
      table.insert(format_elements, { Text = label_text })
      
      -- Имя workspace - белый цвет
      table.insert(format_elements, { Foreground = { Color = dialog_colors.value } })
      table.insert(format_elements, { Text = workspace_name })    else
      -- Остальные строки - белый цвет
      table.insert(format_elements, { Foreground = { Color = "#F8F8F2" } })
      table.insert(format_elements, { Text = truncated })
    end    
    -- Заполняем пробелами справа
    table.insert(format_elements, { Text = string.rep(" ", right_padding) })
    
    -- Закрывающая рамка
    table.insert(format_elements, { Foreground = { Color = dialog_colors.border } })
    table.insert(format_elements, { Text = "│\n" })
    
    -- Пустая строка между строками (кроме последней)
    if i < #lines then
      table.insert(format_elements, { Foreground = { Color = dialog_colors.border } })
      table.insert(format_elements, { Text = "│" .. string.rep(" ", box_width) .. "│\n" })
    end
  end
  
  -- Пустая строка снизу  table.insert(format_elements, { Foreground = { Color = dialog_colors.border } })
  table.insert(format_elements, { Text = "│" .. string.rep(" ", box_width) .. "│\n" })
  
  -- Нижняя рамка с подсказкой
  local left_border_length = box_width - total_hint_width + 1
  table.insert(format_elements, { Foreground = { Color = dialog_colors.border } })
  table.insert(format_elements, { Text = "╰" .. string.rep("─", left_border_length) .. "┤ " })
  table.insert(format_elements, { Foreground = { Color = dialog_colors.hint } })
  table.insert(format_elements, { Attribute = { Intensity = "Half" } })
  table.insert(format_elements, { Text = hint_text })
  table.insert(format_elements, { Foreground = { Color = dialog_colors.border } })
  table.insert(format_elements, { Text = " ├─╯" })
  
  return wezterm.format(format_elements)
end

return M
