-- cat > ~/.config/wezterm/config/bindings.lua << 'EOF'
--
-- ОПИСАНИЕ: Объединенные настройки привязок клавиш и мыши
-- Этот модуль импортирует настройки клавиатуры и мыши из отдельных файлов
-- и объединяет их в один удобный пакет для использования в основной конфигурации.
--
-- ЗАВИСИМОСТИ: config.keyboard.bindings, config.mouse.bindings

local keyboard = require('config.bindings.keyboard')
local mouse = require('config.bindings.mouse')

-- Объединяем все настройки и экспортируем
return {
   -- Настройки клавиатуры
   disable_default_key_bindings = keyboard.disable_default_key_bindings,
   leader = keyboard.leader,
   keys = keyboard.keys,
   key_tables = keyboard.key_tables,
   
   -- Настройки мыши
   disable_default_mouse_bindings = true,
   mouse_bindings = mouse,
}
