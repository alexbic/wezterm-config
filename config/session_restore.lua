-- session_restore.lua
-- Конфигурация для сохранения и восстановления сессий в WezTerm

return {
    -- Включаем возможность сохранять сессии
    unix_domains = {
        {
            name = 'unix',
        },
    },
    
    -- Используем unix-домен по умолчанию
    default_gui_startup_args = { 'connect', 'unix' },
    
    -- Сохранение настроек мультиплексора
    -- mux_output_parser_buffer_size = 10 * 1024 * 1024,
    -- mux_env_remove = {},
    -- mux_output_parser_coalesce_delay_ms = 10,
}
