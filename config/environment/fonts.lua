-- cat > ~/.config/wezterm/config/environment/fonts.lua << 'EOF'
--
-- ОПИСАНИЕ: Настройки шрифтов для WezTerm (ТОЛЬКО ДАННЫЕ)
-- Определяет платформо-зависимые шрифты, размеры и параметры рендеринга.
-- Соответствует архитектуре: config/ = только данные, функции в utils/
--
-- ЗАВИСИМОСТИ: НЕТ

-- === ПЛАТФОРМО-ЗАВИСИМЫЕ ШРИФТЫ ===
local PLATFORM_FONTS = {
  macos = {
    primary = 'JetBrainsMono Nerd Font Mono',
    fallback = {'SF Mono', 'Monaco', 'Menlo'},
    size = 14,
    weight = "Light"
  },
  windows = {
    primary = 'JetBrainsMono Nerd Font Mono', 
    fallback = {'Consolas', 'Courier New'},
    size = 12,
    weight = "Light"
  },
  linux = {
    primary = 'JetBrainsMono Nerd Font Mono',
    fallback = {'DejaVu Sans Mono', 'Liberation Mono', 'monospace'},
    size = 14,
    weight = "Light"
  }
}

-- === НАСТРОЙКИ РЕНДЕРИНГА ===
local RENDER_SETTINGS = {
  warn_about_missing_glyphs = false,
  freetype_load_target = 'Normal',
  freetype_render_target = 'Normal',
  font_antialias = 'Subpixel',
  font_hinting = 'Full'
}

-- === ПРАВИЛА ШРИФТОВ ===
local FONT_RULES = {
  bold = { intensity = "Bold", weight = "Bold" },
  italic = { italic = true, style = "Italic" },
  bold_italic = { intensity = "Bold", italic = true, weight = "Bold", style = "Italic" }
}

return {
  PLATFORM_FONTS = PLATFORM_FONTS,
  RENDER_SETTINGS = RENDER_SETTINGS,
  FONT_RULES = FONT_RULES
}
