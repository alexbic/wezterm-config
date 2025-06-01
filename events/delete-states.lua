-- cat > ~/.config/wezterm/events/delete-states.lua << 'EOF'
--
-- ОПИСАНИЕ: Локализованный модуль удаления состояний
-- Использует централизованную систему иконок, цветов и локализации
--
-- ЗАВИСИМОСТИ: config.environment, utils.debug

local debug = require("utils.debug")
local environment = require("config.environment")
local icons = require("config.environment.icons")
local env_utils = require("utils.environment")local env_utils = require("utils.environment")
local wezterm = require('wezterm')

local M = {}

M.setup = function()
  wezterm.on('resurrect.delete_state', function(window, pane)
    local session_status = require("events.session-status")
    session_status.delete_session_start(window)
    
    local choices = {}

    -- Получаем все сохранённые состояния с нашими иконками и цветами
    local paths = require('config.environment.paths')
    local state_types = {
      {type = "workspace", icon = "󱂬", color = "workspace"},
      {type = "window", icon = nil, color = "window"},
      {type = "tab", icon = "󰓩", color = "debug"}
    }

    for _, state_info in ipairs(state_types) do
      local state_dir = paths.resurrect_state_dir .. state_info.type
      local cmd = "ls " .. state_dir .. "/*.json 2>/dev/null || true"
      local handle = io.popen(cmd)
      if handle then
        for line in handle:lines() do
          local name = line:match("([^/]+)%.json$")
          if name then
            local type_label = environment.locale.t(state_info.type .. "_type")
            
            table.insert(choices, {
              id = state_info.type .. "/" .. name .. ".json",
              label = wezterm.format({
                { Foreground = { Color = env_utils.get_color(icons, state_info.color) } },
                { Text = (state_info.icon or env_utils.get_icon(icons, state_info.type)) .. " : " .. name .. " (" .. type_label .. ")" }
              })
            })
          end
        end
        handle:close()
      end
    end

    if #choices == 0 then
      table.insert(choices, {
        id = "none",
        label = wezterm.format({
          { Foreground = { Color = env_utils.get_color(icons, "error") } },
          { Text = "❌ " .. environment.locale.t("no_workspaces_available") }
        })
      })
    end

    -- Используем наш локализованный InputSelector
    window:perform_action(
      wezterm.action.InputSelector({
        action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
          session_status.clear_saved_mode()

          if not id or id == "none" then
            debug.log(wezterm, environment.locale.t, "workspace", "debug_workspace_cancelled")
            return
          end

          -- Обработка удаления
          local type = string.match(id, "^([^/]+)")
          local clean_id = string.match(id, "([^/]+)$")
          clean_id = string.match(clean_id, "(.+)%..+$")
          
          debug.log(wezterm, environment.locale.t, "workspace", "debug_workspace_action_type", type)

          -- Удаляем состояние
          local resurrect = require('config.resurrect').resurrect
          resurrect.state_manager.delete_state(id)
          
          -- Уведомляем об успехе
          wezterm.time.call_after(0.5, function()
            session_status.delete_session_success(inner_window, clean_id)
          end)
        end),
        title = env_utils.get_icon(icons, "list_delete_tab") .. " " .. environment.locale.t("deleting_sessions_title"),
        description = environment.locale.t("deleting_sessions_description"),
        fuzzy_description = environment.locale.t("deleting_sessions_fuzzy"),
        fuzzy = true,
        choices = choices,
      }),
      pane
    )
  end)
end

return M
