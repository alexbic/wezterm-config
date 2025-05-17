local platform = require('utils.platform')()

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

return options
