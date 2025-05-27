-- cat > ~/.config/wezterm/config/environment/colors.lua << 'EOF'
--
-- ОПИСАНИЕ: Цветовые схемы и переменные для командной строки и интерфейса
-- Содержит пользовательскую цветовую схему (catppucchin mocha) и переменные для ls, grep и других утилит.
--
-- ЗАВИСИМОСТИ: используется в config.appearance

-- Пользовательская цветовая схема catppucchin mocha
local mocha = {
   rosewater = "#f5e0dc",
   flamingo = "#f2cdcd",
   pink = "#f5c2e7",
   mauve = "#cba6f7",
   red = "#f38ba8",
   maroon = "#eba0ac",
   peach = "#fab387",
   yellow = "#f9e2af",
   green = "#a6e3a1",
   teal = "#94e2d5",
   sky = "#89dceb",
   sapphire = "#74c7ec",
   blue = "#89b4fa",
   lavender = "#b4befe",
   text = "#cdd6f4",
   subtext1 = "#bac2de",
   subtext0 = "#a6adc8",
   overlay2 = "#9399b2",
   overlay1 = "#7f849c",
   overlay0 = "#6c7086",
   surface2 = "#585b70",
   surface1 = "#45475a",
   surface0 = "#313244",
   base = "#1f1f28",
   mantle = "#181825",
   crust = "#11111b",
}

local colorscheme = {
   foreground = mocha.text,
   background = mocha.base,
   cursor_bg = mocha.rosewater,
   cursor_border = mocha.rosewater,
   cursor_fg = mocha.crust,
   selection_bg = mocha.surface2,
   selection_fg = mocha.text,
   ansi = {
      "#0C0C0C", "#C50F1F", "#13A10E", "#C19C00",
      "#0037DA", "#881798", "#3A96DD", "#CCCCCC",
   },
   brights = {
      "#767676", "#E74856", "#16C60C", "#F9F1A5",
      "#3B78FF", "#B4009E", "#61D6D6", "#F2F2F2",
   },
   tab_bar = {
      background = "#313244",
      active_tab = {
         bg_color = mocha.surface2,
         fg_color = mocha.text,
      },
      inactive_tab = {
         bg_color = mocha.surface0,
         fg_color = mocha.subtext1,
      },
      inactive_tab_hover = {
         bg_color = mocha.surface0,
         fg_color = mocha.text,
      },
      new_tab = {
         bg_color = mocha.base,
         fg_color = mocha.text,
      },
      new_tab_hover = {
         bg_color = mocha.mantle,
         fg_color = mocha.text,
         italic = true,
      },
   },
   -- 🟠 ОРАНЖЕВЫЙ VISUAL BELL для copy_mode
   visual_bell = "#FF8C00",
   indexed = {
      [16] = mocha.peach,
      [17] = mocha.rosewater,
   },
   scrollbar_thumb = mocha.surface2,
   split = mocha.overlay0,
   compose_cursor = mocha.flamingo,
}

local M = {
  mocha = mocha,
  colorscheme = colorscheme,
  -- переменные для командной строки:
  CLICOLOR = '1',
  LSCOLORS = 'ExFxBxDxCxegedabagacad',
  LS_COLORS = 'di=1;34:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43',
  GREP_COLOR = '1;32',
  GREP_OPTIONS = '--color=auto',
}

return M
