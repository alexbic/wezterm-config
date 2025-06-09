-- ДАННЫЕ для единого интерфейса состояний (ТОЛЬКО ДАННЫЕ)
local M = {}

M.title_key = "states_manager_title"
M.description_key = "states_manager_description"

M.menu_items = {
  {
    id = "save_workspace",
    icon_key = "workspace",
    title_key = "save_workspace_action",
    description_key = "save_workspace_description",
    action_type = "emit_event",
    target = "resurrect.save_state"
  },
  {
    id = "load_state", 
    icon_key = "list_picker_tab",
    title_key = "load_state_action",
    description_key = "load_state_description",
    action_type = "emit_event",
    target = "resurrect.load_state"
  },
  {
    id = "delete_state",
    icon_key = "list_delete_tab", 
    title_key = "delete_state_action",
    description_key = "delete_state_description",
    action_type = "emit_event",
    target = "resurrect.delete_state"
  }
}

return M
