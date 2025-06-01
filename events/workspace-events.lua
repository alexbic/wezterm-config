-- cat > ~/.config/wezterm/events/workspace-events.lua << 'EOF'
--
-- ОПИСАНИЕ: Обработчики событий для workspace переключения
-- Использует централизованную систему иконок и цветов
--
-- ЗАВИСИМОСТИ: config.environment, utils.debug

local debug = require("utils.debug")
local environment = require("config.environment")
local icons = require("config.environment.icons")
local env_utils = require("utils.environment")
local wezterm = require('wezterm')

local M = {}

M.setup = function()
  wezterm.on('workspace.switch', function(window, pane)
    local choices = {}

    -- 1. Активные workspace с централизованными иконками и цветами
    local mux = wezterm.mux
    local active_workspaces = mux.get_workspace_names()

    for _, workspace_name in ipairs(active_workspaces) do
      table.insert(choices, {
        id = "active|" .. workspace_name,
        label = wezterm.format({
          { Foreground = { Color = env_utils.get_color(icons, "workspace") } },
          { Text = env_utils.get_icon(icons, "workspace") .. " : " .. workspace_name .. " (" .. environment.locale.t("workspace_type") .. ")" }
        })
      })
    end

    -- 2. Сохранённые workspace
    local paths = require('config.environment.paths')
    local workspace_dir = paths.resurrect_state_dir .. "workspace"
    local cmd = "ls " .. workspace_dir .. "/*.json 2>/dev/null || true"
    local handle = io.popen(cmd)
    if handle then
      for line in handle:lines() do
        local name = line:match("([^/]+)%.json$")
        if name then
          table.insert(choices, {
            id = "saved|workspace|" .. name,
            label = wezterm.format({
              { Foreground = { Color = env_utils.get_color(icons, "workspace") } },
              { Text = env_utils.get_icon(icons, "workspace") .. " : " .. name .. " (" .. environment.locale.t("workspace_type") .. ")" }
            })
          })
        end
      end
      handle:close()
    end

    -- 3. Сохранённые window и tab
    local other_types = {"window", "tab"}
    for _, state_type in ipairs(other_types) do
      local state_dir = paths.resurrect_state_dir .. state_type
      local cmd = "ls " .. state_dir .. "/*.json 2>/dev/null || true"
      local handle = io.popen(cmd)
      if handle then
        for line in handle:lines() do
          local name = line:match("([^/]+)%.json$")
          if name then
            local type_label = environment.locale.t(state_type .. "_type")
            
            table.insert(choices, {
              id = "saved|" .. state_type .. "|" .. name,
              label = wezterm.format({
                { Foreground = { Color = env_utils.get_color(icons, state_type) } },
                { Text = env_utils.get_icon(icons, state_type) .. " : " .. name .. " (" .. type_label .. ")" }
              })
            })
          end
        end
        handle:close()
      end
    end

    -- 4. Пути из zoxide
    local workspace_switcher_plugin = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
    local zoxide_choices = workspace_switcher_plugin.choices.get_zoxide_elements({})

    for _, choice in ipairs(zoxide_choices) do
      table.insert(choices, {
        id = "zoxide|" .. choice.id,
        label = wezterm.format({
          { Foreground = { Color = env_utils.get_color(icons, "input") } },
          { Text = "󰉋 : " .. choice.label .. " (путь)" }
        })
      })
    end

    if #choices == 0 then
      table.insert(choices, {
        id = "none",
        label = "❌ " .. environment.locale.t("no_workspaces_available")
      })
    end

    -- InputSelector с цветным форматированием
    window:perform_action(
      wezterm.action.InputSelector({
        action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
          wezterm.emit('clear-saved-mode', inner_window, inner_pane)

          if not id or id == "none" then
            debug.log(wezterm, environment.locale.t, "workspace", "debug_workspace_cancelled")
            return
          end

          local parts = {}
          for part in string.gmatch(id, "[^|]+") do
            table.insert(parts, part)
          end

          local action_type = parts[1]
          debug.log(wezterm, environment.locale.t, "workspace", "debug_workspace_action_type", action_type)

          if action_type == "active" then
            local workspace_name = parts[2]
            inner_window:perform_action(
              wezterm.action.SwitchToWorkspace({ name = workspace_name }),
              inner_window:active_pane()
            )
          elseif action_type == "zoxide" then
            local path = parts[2]
            debug.log(wezterm, environment.locale.t, "workspace", "debug_workspace_path_switch", path)
            inner_window:perform_action(
              wezterm.action.SwitchToWorkspace({
                name = path,
                spawn = { cwd = path },
              }),
              inner_window:active_pane()
            )
          elseif action_type == "saved" then
            local state_type = parts[2]
            local state_name = parts[3]

            local resurrect = require('config.resurrect').resurrect
            local state = resurrect.state_manager.load_state(state_name, state_type)

            if state then
              if state_type == "workspace" then
                local mux_window = inner_window:mux_window()
                local tabs = mux_window:tabs()

                for i = #tabs, 2, -1 do
                  local tab = tabs[i]
                  if tab then
                    tab:activate()
                    inner_window:perform_action(wezterm.action.CloseCurrentTab({confirm = false}), tab:active_pane())
                  end
                end

                wezterm.time.call_after(0.5, function()
                  resurrect.workspace_state.restore_workspace(state, {
                    window = inner_window:mux_window(),
                    relative = false,
                    restore_text = true,
                    on_pane_restore = resurrect.tab_state.default_on_pane_restore,
                  })
                end)
              elseif state_type == "window" then
                resurrect.window_state.restore_window(inner_pane:window(), state, {
                  window = inner_window:mux_window(),
                  relative = true,
                  restore_text = true,
                  on_pane_restore = resurrect.tab_state.default_on_pane_restore,
                })
              elseif state_type == "tab" then
                resurrect.tab_state.restore_tab(inner_pane:tab(), state, {
                  relative = true,
                  restore_text = true,
                  on_pane_restore = resurrect.tab_state.default_on_pane_restore,
                })
              end
            else
              wezterm.log_error(environment.locale.t("failed_to_load_state", state_name))
            end
          end
        end),
        title = env_utils.get_icon(icons, "list_picker_tab") .. " " .. environment.locale.t("workspace_switch_title"),
        description = environment.locale.t("workspace_switch_description"),
        fuzzy_description = "Поиск workspace/состояния: ",
        fuzzy = true,
        choices = choices,
      }),
      pane
    )
  end)
end

return M
