-- cat > ~/.config/wezterm/config/general.lua << 'EOF'
--
-- ОПИСАНИЕ: Общие настройки WezTerm
-- Содержит основные параметры поведения терминала: перезагрузка конфигурации,
-- проверка обновлений, поведение при выходе, правила для гиперссылок и т.д.
--
-- ЗАВИСИМОСТИ: Импортируется и применяется в wezterm.lua

local wezterm = require('wezterm')

return {
   -- Показывать кнопки управления окном в заголовке
   window_decorations = "INTEGRATED_BUTTONS|RESIZE",
   -- Настройки позиционирования и размера окна
   initial_cols = 120,
   initial_rows = 30,
   window_padding = {
     left = 10,
     right = 10,
     top = 10,
     bottom = 10,
   },
   -- НЕ показывать заголовок в панели вкладок (чтобы системные кнопки были видны)
   -- behaviours
   automatically_reload_config = true,
   check_for_updates = false,
   exit_behavior = 'CloseOnCleanExit', -- if the shell program exited with a successful status
   status_update_interval = 1000,

   -- scrollbar
   scrollback_lines = 5000,

   -- paste behaviours
   canonicalize_pasted_newlines = 'CarriageReturn',

   -- 🔔 VISUAL BELL для copy_mode с оранжевой рамкой со всех сторон
   visual_bell = {
      fade_in_duration_ms = 75,
      fade_out_duration_ms = 225,
      fade_in_function = 'EaseIn',
      fade_out_function = 'EaseOut',
      target = 'BackgroundColor',
   },

   hyperlink_rules = {
      -- Matches: a URL in parens: (URL)
      {
         regex = '\\((\\w+://\\S+)\\)',
         format = '$1',
         highlight = 1,
      },
      -- Matches: a URL in brackets: [URL]
      {
         regex = '\\[(\\w+://\\S+)\\]',
         format = '$1',
         highlight = 1,
      },
      -- Matches: a URL in curly braces: {URL}
      {
         regex = '\\{(\\w+://\\S+)\\}',
         format = '$1',
         highlight = 1,
      },
      -- Matches: a URL in angle brackets: <URL>
      {
         regex = '<(\\w+://\\S+)>',
         format = '$1',
      },
      -- Then handle URLs not wrapped in brackets
      {
         regex = '\\b\\w+://\\S+[)/a-zA-Z0-9-]+',
         format = '$0',
      },
      -- implicit mailto link
      {
         regex = '\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b',
         format = 'mailto:$0',
      },
   },

   -- Настройки для fancy tab bar с интегрированными кнопками управления
   use_fancy_tab_bar = true,
   window_decorations = "INTEGRATED_BUTTONS|RESIZE",
   tab_bar_at_bottom = false,
   
   -- 🖼️ WINDOW FRAME с оранжевыми границами для copy_mode
   window_frame = {
     font = wezterm.font("Menlo", { weight = "Light" }),
     font_size = 11,
     -- Оранжевые границы со всех сторон 6px для copy_mode
     border_left_width = '6px',
     border_right_width = '6px',
     border_bottom_height = '6px',
     border_top_height = '6px',
     border_left_color = '#FF8C00',
     border_right_color = '#FF8C00',
     border_bottom_color = '#FF8C00',
     border_top_color = '#FF8C00',
   },

   -- Интегрированные кнопки управления окном
   integrated_title_button_style = "Windows",
   integrated_title_button_color = "auto",
   integrated_title_button_alignment = "Right",
   window_close_confirmation = "NeverPrompt",
   skip_close_confirmation_for_processes_named = { "bash", "sh", "zsh", "fish", "tmux" },
}
