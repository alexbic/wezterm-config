local M = {}

M.DEBUG_CONFIG = {
  session_status = false,
  appearance = false,
  resurrect = false,
  workspace = false,
  bindings = false,
  global = true,
}

M.log = function(wezterm, t_table, module, message_key, ...)
  if M.DEBUG_CONFIG[module] then
    local colors = require("config.environment.colors")
    local icons = require("config.environment.icons")
    local env_utils = require("utils.environment")
    local localized_msg = (t_table and t_table[message_key]) or message_key
    local formatted_msg = string.format(localized_msg, ...)
    local var_icon = icons.t.set_env_var or "⚡"
    local var_color = env_utils.get_ansi_color(colors, "set_env_var")
    local colored_prefix = "\27[38;5;" .. var_color .. "m[" .. module .. "] " .. var_icon .. "\27[0m"
    wezterm.log_info(colored_prefix .. " " .. formatted_msg)
  end
end

M.load_debug_settings = function(wezterm)
  local settings_file = wezterm.config_dir .. "/session-state/debug-settings.lua"
  local file = io.open(settings_file, "r")
  if file then
    local content = file:read("*a")
    file:close()
    local chunk = load("return " .. content)
    if chunk then
      local ok, data = pcall(chunk)
      if ok and data and data.debug_modules then
        for module, value in pairs(data.debug_modules) do
          if M.DEBUG_CONFIG[module] ~= nil then
            M.DEBUG_CONFIG[module] = value
          end
        end
      end
    end
  end
end

M.save_debug_settings = function(wezterm)
  if not wezterm then
    wezterm = require('wezterm')
  end
  local settings_file = wezterm.config_dir .. "/session-state/debug-settings.lua"
  local lua_content = string.format([[{
  debug_modules = {
    appearance = %s,
    global = %s,
    session_status = %s,
    workspace = %s,
    bindings = %s,
    resurrect = %s
  },
  last_updated = "%s"
}]], 
    M.DEBUG_CONFIG.appearance and "true" or "false",
    M.DEBUG_CONFIG.global and "true" or "false",
    M.DEBUG_CONFIG.session_status and "true" or "false",
    M.DEBUG_CONFIG.workspace and "true" or "false",
    M.DEBUG_CONFIG.bindings and "true" or "false",
    M.DEBUG_CONFIG.resurrect and "true" or "false",
    os.date("%Y-%m-%d %H:%M:%S"))
  
  local file = io.open(settings_file, "w")
  if file then
    file:write(lua_content)
    file:close()
  end
end

return M
