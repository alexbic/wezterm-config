-- ДАННЫЕ для состояний менеджера (ТОЛЬКО ДАННЫЕ)
local M = {}

M.title_key = "state_manager_title"
M.description_key = "state_manager_description"

M.menu_items = {
  { id = "workspace_stats", icon_key = "workspace", title_key = "workspace_states_count" },
  { id = "window_stats", icon_key = "window", title_key = "window_states_count" },
  { id = "tab_stats", icon_key = "tab", title_key = "tab_states_count" }
}

return M-- cat > ~/.config/wezterm/config/dialogs/state-manager.lua << 'EOF'
--
-- ОПИСАНИЕ: Менеджер управления сохраненными состояниями (ПОЛНОСТЬЮ ФУНКЦИОНАЛЬНЫЙ)
-- Исправлена локализация и добавлено красивое форматирование с выравниванием
-- ЗАВИСИМОСТИ: config.environment, utils.environment, utils.dialog
--

