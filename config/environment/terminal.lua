-- cat > ~/.config/wezterm/config/environment/terminal.lua << 'EOF'
--
-- ОПИСАНИЕ: Переменные окружения терминала и shell
-- Настройки терминала, истории команд, тем и специфичных переменных для shell.
--
-- ЗАВИСИМОСТИ: нет

local M = {
  TERM = 'xterm-256color',
  COLORTERM = 'truecolor',
  HISTSIZE = '10000',
  HISTFILESIZE = '20000',
  ZSH_THEME = 'powerlevel10k/powerlevel10k',
}

return M
