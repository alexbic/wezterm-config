local wezterm = require('wezterm')
local math = require('utils.math')
local M = {}

M.separator_char = ' '
M.colors = {
   date_fg = '#dac835',
   date_bg = '#181825',
   battery_fg = '#dac835',
   battery_bg = '#181825',
   separator_fg = '#dccb00',
   separator_bg = '#181825',
   -- Цвета для режимов
   mode_fg = '#50fa7b', -- Зеленый для режимов
   mode_bg = '#181825',
}

M.cells = {} -- wezterm FormatItems (ref: https://wezfurlong.org/wezterm/config/lua/wezterm/format.html)

---@param text string
---@param icon string
---@param fg string
---@param bg string
---@param separate boolean
M.push = function(text, icon, fg, bg, separate)
   table.insert(M.cells, { Foreground = { Color = fg } })
   table.insert(M.cells, { Background = { Color = bg } })
   table.insert(M.cells, { Attribute = { Intensity = 'Bold' } })
   table.insert(M.cells, { Text = icon .. ' ' .. text .. ' ' })
   if separate then
      table.insert(M.cells, { Foreground = { Color = M.colors.separator_fg } })
      table.insert(M.cells, { Background = { Color = M.colors.separator_bg } })
      table.insert(M.cells, { Text = M.separator_char })
   end
   table.insert(M.cells, 'ResetAttributes')
end

M.set_date = function()
   local date = wezterm.strftime(' %a %H:%M')
   M.push(date, '', M.colors.date_fg, M.colors.date_bg, true)
end

M.set_battery = function()
   -- ref: https://wezfurlong.org/wezterm/config/lua/wezterm/battery_info.html
   local discharging_icons = { '', '', '', '', '', '', '', '', '', '' }
   local charging_icons = { '', '', '', '', '', '', '', '', '', '' }
   local charge = ''
   local icon = ''
   for _, b in ipairs(wezterm.battery_info()) do
      local idx = math.clamp(math.round(b.state_of_charge * 10), 1, 10)
      charge = string.format('%.0f%%', b.state_of_charge * 100)
      if b.state == 'Charging' then
         icon = charging_icons[idx]
      else
         icon = discharging_icons[idx]
      end
   end
   M.push(charge, icon, M.colors.battery_fg, M.colors.battery_bg, false)
end

-- Новая функция для отображения активного режима
M.set_mode = function(window)
   local name = window:active_key_table()
   if name then
      local mode_icon = ""
      local mode_text = ""
      
      -- Определяем иконку и текст в зависимости от режима
      if name == "pane_control" then
         mode_icon = "󰯊"  -- Иконка для режима панелей
         mode_text = "PANE"
      elseif name == "font_control" then
         mode_icon = "󰛖"  -- Иконка для режима шрифта
         mode_text = "FONT"
      else
         mode_icon = "󰌌"  -- Общая иконка для других режимов
         mode_text = name
      end
      
      -- Добавляем в строку статуса
      M.push(mode_text, mode_icon, M.colors.mode_fg, M.colors.mode_bg, true)
   end
end

M.setup = function()
   wezterm.on('update-right-status', function(window, _pane)
      M.cells = {}
      
      -- Сначала отображаем активный режим (если есть)
      M.set_mode(window)
      
      -- Затем дату и батарею
      M.set_date()
      M.set_battery()
      
      window:set_right_status(wezterm.format(M.cells))
   end)
end

return M
