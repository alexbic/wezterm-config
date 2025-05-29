-- cat > ~/.config/wezterm/config/environment/fonts.lua << 'EOF'
--
-- ОПИСАНИЕ: Настройки шрифтов для WezTerm
-- Определяет используемый шрифт, его размер и другие связанные параметры.
-- Размер шрифта зависит от платформы (больше на macOS/Linux, меньше на Windows).
--
-- ЗАВИСИМОСТИ: wezterm, config.environment.locale

local wezterm = require('wezterm')
local locale = require('config.environment.locale')

-- Создаем platform_info используя utils.platform
local create_platform_info = require('utils.platform')
local platform = create_platform_info(wezterm.target_triple)

local font = 'JetBrainsMono Nerd Font Mono' -- JetBrains Mono
local font_size = platform.is_win and 12 or 14

local M = {
    font = wezterm.font(font, { weight = "Light" }),
    font_size = font_size,
    warn_about_missing_glyphs = false,
    --ref: https://wezfurlong.org/wezterm/config/lua/config/freetype_pcf_long_family_names.html\#why-doesnt-wezterm-use-the-distro-freetype-or-match-its-configuration
    freetype_load_target = 'Normal', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
    freetype_render_target = 'Normal', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
}

return M
