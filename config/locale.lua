-- cat > ~/.config/wezterm/config/locale.lua << 'EOF'
--
-- ОПИСАНИЕ: Настройки локали и языка для WezTerm
-- Централизованное управление языковыми настройками интерфейса.
-- Позволяет переопределить системную локаль для отображения даты/времени.
--
-- ЗАВИСИМОСТИ: Используется в utils.platform и events.right-status

return {
  -- Принудительная установка языка интерфейса
  -- Доступные значения: "ru", "en", "de", "fr", "es", "it", "pt", "zh", "ja", "ko"
  force_language = "ru",
  
  -- Принудительная установка локали
  -- Используется для переменных окружения
  force_locale = "ru_RU.UTF-8",
  
  -- Доступные языки и их локали
  available_languages = {
    ru = { locale = "ru_RU.UTF-8", name = "Русский" },
    en = { locale = "en_US.UTF-8", name = "English" },
    de = { locale = "de_DE.UTF-8", name = "Deutsch" },
    fr = { locale = "fr_FR.UTF-8", name = "Français" },
    es = { locale = "es_ES.UTF-8", name = "Español" },
    it = { locale = "it_IT.UTF-8", name = "Italiano" },
    pt = { locale = "pt_BR.UTF-8", name = "Português" },
    zh = { locale = "zh_CN.UTF-8", name = "中文" },
    ja = { locale = "ja_JP.UTF-8", name = "日本語" },
    ko = { locale = "ko_KR.UTF-8", name = "한국어" },
  }
}
