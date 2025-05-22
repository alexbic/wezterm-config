-- cat > ~/.config/wezterm/events/new-tab-button.lua << 'EOF'
--
-- ОПИСАНИЕ: Обработчик событий для кнопки новой вкладки
-- Добавляет функционал для левого и правого клика по кнопке "+" в панели вкладок.
-- Левый клик создает новую вкладку, правый показывает лаунчер.
--
-- ЗАВИСИМОСТИ: Загружается в основном wezterm.lua

local wezterm = require('wezterm')

local M = {}

M.setup = function()
   wezterm.on('new-tab-button-click', function(window, pane, button, default_action)
      wezterm.log_info('new-tab', window, pane, button, default_action)
      if default_action and button == 'Left' then
         window:perform_action(default_action, pane)
      end

      if default_action and button == 'Right' then
         window:perform_action(
            wezterm.action.ShowLauncherArgs({ title = '  Select/Search:', flags = 'FUZZY|LAUNCH_MENU_ITEMS|DOMAINS'}), pane
         )
      end
      return false
   end)
end

return M
