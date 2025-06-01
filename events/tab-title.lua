-- cat > ~/.config/wezterm/events/tab-title.lua << 'EOF'
--
-- ОПИСАНИЕ: Настройка заголовков вкладок
-- Определяет внешний вид заголовков вкладок, включая форматирование, 
-- отображение иконки администратора, и индикатор непрочитанного вывода.
-- ОБНОВЛЕНО: Интеграция с централизованной системой иконок для служебных окон
--
-- ЗАВИСИМОСТИ: Загружается в основном wezterm.lua

local wezterm = require("wezterm")
local environment = require('config.environment')
local icons = require('config.environment.icons')
local colors = require('config.environment.colors')
local env_utils = require('utils.environment')

-- Используем UTF-8 символы вместо строковых литералов
local GLYPH_SEMI_CIRCLE_LEFT = utf8.char(0xe0b6) -- ""
local GLYPH_SEMI_CIRCLE_RIGHT = utf8.char(0xe0b4) -- ""
local GLYPH_CIRCLE = utf8.char(0xf111) -- ""
local GLYPH_ADMIN = utf8.char(0xfc7e) -- "ﱾ"
local GLYPH_TILDE = utf8.char(0x223c) -- "~"

local M = {}

M.cells = {}

M.set_process_name = function(s)
   local a = string.gsub(s, "(.*[/\\])(.*)", "%2")
   return a:gsub("%.exe$", "")
end

M.set_title = function(process_name, static_title, active_title, max_width, inset)
   local title
   inset = inset or 6
   
   -- Сначала проверяем, это служебное окно?
   local service_type = env_utils.detect_service_window_type(static_title, active_title, process_name)
   if service_type then
      -- Для служебных окон показываем иконку + сокращенное название
      local icon = env_utils.get_icon(icons, service_type)
      local short_title = env_utils.get_service_window_display_name(service_type)
      title = icon .. " " .. short_title
   else
      -- Для обычных окон используем старую логику
      if process_name:len() > 0 and static_title:len() == 0 then
         title = process_name .. " " .. GLYPH_TILDE .. " "
      elseif static_title:len() > 0 then
         title = static_title .. " " .. GLYPH_TILDE .. " "
      else
         title = active_title .. " ㉿ "
      end
   end

   if title:len() > max_width - inset then
      local diff = title:len() - max_width + inset
      title = wezterm.truncate_right(title, title:len() - diff)
   end

   return title
end

M.check_if_admin = function(p)
   if p:match("^Administrator: ") then
      return true
   end
   return false
end

---@param fg string
---@param bg string
---@param attribute table
---@param text string
M.push = function(bg, fg, attribute, text)
   table.insert(M.cells, { Background = { Color = bg } })
   table.insert(M.cells, { Foreground = { Color = fg } })
   table.insert(M.cells, { Attribute = attribute })
   table.insert(M.cells, { Text = text })
end

M.setup = function()
   wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
      M.cells = {}

      local bg
      local fg
      local process_name = M.set_process_name(tab.active_pane.foreground_process_name)
      local is_admin = M.check_if_admin(tab.active_pane.title)
      local title = M.set_title(process_name, tab.tab_title, tab.active_pane.title, max_width, (is_admin and 8))

      -- Определяем тип служебного окна для цвета
      local service_type = env_utils.detect_service_window_type(tab.tab_title, tab.active_pane.title, process_name)
      
      if tab.is_active then
         if service_type then
            -- Для служебных окон используем специальные цвета из centralized system
            bg = env_utils.get_color(colors, service_type)
            fg = env_utils.get_color(colors, "tab_service_fg")
         else
            bg = env_utils.get_color(colors, "tab_active_bg")
            fg = env_utils.get_color(colors, "tab_active_fg")
         end
      elseif hover then
         bg = env_utils.get_color(colors, "tab_hover_bg")
         fg = env_utils.get_color(colors, "tab_hover_fg")
      else
         bg = env_utils.get_color(colors, "tab_default_bg")
         fg = env_utils.get_color(colors, "tab_default_fg")
      end

      local has_unseen_output = false
      for _, pane in ipairs(tab.panes) do
         if pane.has_unseen_output then
            has_unseen_output = true
            break
         end
      end

      -- Left semi-circle
      M.push(fg, bg, { Intensity = "Bold" }, GLYPH_SEMI_CIRCLE_LEFT)

      -- Admin Icon
      if is_admin then
         M.push(bg, fg, { Intensity = "Bold" }, " " .. GLYPH_ADMIN)
      end

      -- Title
      M.push(bg, fg, { Intensity = "Bold" }, " " .. title)

      -- Unseen output alert
      if has_unseen_output then
         local unseen_color = env_utils.get_color(colors, "tab_unseen_output")
         M.push(bg, unseen_color, { Intensity = "Bold" }, " " .. GLYPH_CIRCLE)
      end

      -- Right padding
      M.push(bg, fg, { Intensity = "Bold" }, " ")

      -- Right semi-circle
      M.push(fg, bg, { Intensity = "Bold" }, GLYPH_SEMI_CIRCLE_RIGHT)

      return M.cells
   end)
end

return M
