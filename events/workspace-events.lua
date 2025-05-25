local wezterm = require('wezterm')

local function register_workspace_events()
  wezterm.on('workspace.switch', function(window, pane)
    wezterm.log_info("🏠 Событие workspace.switch получено")
    local workspace_switcher = require('config.workspace-switcher')
    window:perform_action(workspace_switcher.workspace_switcher.switch_workspace(), pane)
  end)
end

return register_workspace_events
