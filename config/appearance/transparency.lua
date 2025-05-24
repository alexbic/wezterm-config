-- cat > ~/.config/wezterm/config/appearance/transparency.lua << 'EOF'
--
-- ОПИСАНИЕ: Управление прозрачностью окна WezTerm
-- Описывает доступные уровни прозрачности и их параметры.
-- Используется для циклического изменения прозрачности окна.
--
-- ЗАВИСИМОСТИ: нет (только экспорт настроек)

local M = {}

M.opacity_settings = {
  { opacity = 0.1, title = "Opacity: 10%" },
  { opacity = 0.2, title = "Opacity: 20%" },
  { opacity = 0.35, title = "Opacity: 35%" },
  { opacity = 0.5, title = "Opacity: 50%" },
  { opacity = 0.65, title = "Opacity: 65%" },
  { opacity = 0.8, title = "Opacity: 80%" },
  { opacity = 1.0, title = "Opacity: 100%" }
}

return M
