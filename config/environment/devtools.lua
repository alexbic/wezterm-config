-- cat > ~/.config/wezterm/config/environment/devtools.lua << 'EOF'
--
-- ОПИСАНИЕ: Настройки редакторов и инструментов разработки
-- Определяет переменные окружения для редакторов, git, pager и других dev-инструментов.
--
-- ЗАВИСИМОСТИ: нет

local paths = require('config.environment.paths')

local M = {
  EDITOR = 'nvim',
  VISUAL = 'nvim',
  GIT_EDITOR = 'nvim',
  PAGER = 'less',
  LESS = '-R',
  NODE_ENV = 'development',
  PYTHONPATH = paths.home .. '/.local/lib/python3.11/site-packages',
  BAT_THEME = 'TwoDark',
  FZF_DEFAULT_OPTS = '--height 40% --layout=reverse --border',
}

return M
