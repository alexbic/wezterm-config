-- cat > ~/.config/wezterm/config/launch.lua << 'EOF'
--
-- ОПИСАНИЕ: Настройки запускаемых программ и доменов
-- Определяет программы по умолчанию для запуска в терминале и пункты меню
-- для выбора альтернативных программ. Выбор зависит от ОС.
--
-- ЗАВИСИМОСТИ: utils.platform

local platform = require('utils.platform')()
local environment = require('config.environment')

local options = {
   default_prog = {'/bin/zsh', '-l'},
   launch_menu = {
      { label = 'Bash', args = { 'bash' } },
      { label = 'Zsh', args = { '/bin/zsh', '-l' } },
   },
}

if platform.is_win then
   options.default_prog = { 'pwsh' }
   options.launch_menu = {
      { label = 'PowerShell', args = { 'powershell' } },
      {
         label = 'Git Bash',
         args = { 'D:\\software\\GIT\\Git\\bin\\bash.exe' },
      },
      {
         label = 'virtual machine',
         args = { 'ssh', 'root@192.168.33.10', '-p', '22' },
      },
      { label = 'Cmd', args = { 'cmd' } },
      { label = 'Nushell', args = { 'nu' } },
   }
elseif platform.is_mac then
   -- Убедимся, что используется zsh вместо fish
   options.default_prog = { '/bin/zsh', '-l' }  
   options.launch_menu = {
      { label = 'Bash', args = { 'bash' } },
      { label = 'Zsh', args = { '/bin/zsh', '-l' } },
   }
end

options.description = environment.locale.t("some_key")

return options
