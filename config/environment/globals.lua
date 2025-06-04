-- cat > ~/.config/wezterm/config/environment/globals.lua << 'EOF'
--
-- ОПИСАНИЕ: Глобальные настройки окружения WezTerm
-- Централизованные константы и параметры для всей системы.
-- ТОЛЬКО данные, никаких функций!
--
-- ЗАВИСИМОСТИ: нет

return {
  -- === НАСТРОЙКИ ЛОКАЛИЗАЦИИ ===
  DEFAULT_LANGUAGE = "ru",
  SUPPORTED_LANGUAGES = {"ru", "en", "de", "fr", "es"},
  LOCALE_AUTO_CREATE = true,
  LOCALE_DIR = "config/locales",
  
  -- === НАСТРОЙКИ ИНТЕРФЕЙСА ===
  DEFAULT_THEME = "catppuccin-mocha",
  ICON_THEME = "nerd-fonts",
  
  -- === НАСТРОЙКИ ПРОИЗВОДИТЕЛЬНОСТИ ===
  CACHE_ENABLED = true,
  LAZY_LOADING = true,
  DEBUG_MODE = false,
  
  -- === ПУТИ И ДИРЕКТОРИИ ===
  BACKDROPS_DIR = "backdrops",
  SESSION_STATE_DIR = "session-state",
  SCRIPTS_DIR = "scripts",
  
  -- === ВЕРСИОНИРОВАНИЕ ===
  CONFIG_VERSION = "2.0.0",
  LAST_UPDATED = "2024-12-22"
}
