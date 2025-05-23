-- cat > ~/.config/wezterm/utils/session-status.lua << 'EOF'
--
-- ОПИСАНИЕ: Модуль для отображения статуса операций с сессиями
-- Управляет отображением иконок режимов, анимации загрузки и уведомлений
-- о результатах операций с сессиями в строке состояния.
--
-- ЗАВИСИМОСТИ: Используется в events.right-status и config.resurrect

local wezterm = require('wezterm')
local locale = require('config.locale')
local M = {}

-- Инициализируем глобальные переменные для управления статусом
if not wezterm.GLOBALS then wezterm.GLOBALS = {} end
if not wezterm.GLOBALS.session_status then
  wezterm.GLOBALS.session_status = {
    -- Текущий активный режим таблицы клавиш
    current_mode = nil,
    
    -- Сохраненный режим для операций (остается во время операций)
    saved_mode = nil,
    saved_mode_timer = nil,
    
    -- Анимация загрузки
    loading = {
      active = false,
      frames = {"⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"},
      current_frame = 1,
      timer_id = nil,
      start_time = 0,
      max_duration = 15,
      force_stop_timer = nil
    },
    
    -- Уведомления о результатах операций
    notification = {
      active = false,
      message = "",
      icon = "",
      color = "#FFFFFF",
      duration = 0,
      start_time = 0,
      timer_id = nil,
      hide_mode = false -- флаг для скрытия режима во время уведомления
    },
    
    -- Состояние операций
    operation_state = {
      active = false,
      type = nil, -- "load", "delete", "save"
      list_shown = false
    }
  }
end

-- Иконки для различных режимов таблиц клавиш
local mode_icons = {
  session_control = {
    icon = "💾",
    name = "СЕССИИ",
    color = "#FF6B6B"
  },
  pane_control = {
    icon = "🔲",
    name = "ПАНЕЛИ", 
    color = "#4ECDC4"
  },
  font_control = {
    icon = "🔤",
    name = "ШРИФТ",
    color = "#45B7D1"
  }
}

-- Функция для установки текущего режима
M.set_mode = function(mode_name)
  wezterm.GLOBALS.session_status.current_mode = mode_name
  -- При входе в режим также сохраняем его для операций
  wezterm.GLOBALS.session_status.saved_mode = mode_name
  
  -- Отменяем таймер очистки сохраненного режима если он был
  if wezterm.GLOBALS.session_status.saved_mode_timer then
    wezterm.GLOBALS.session_status.saved_mode_timer:cancel()
    wezterm.GLOBALS.session_status.saved_mode_timer = nil
  end
  
  wezterm.log_info("🔥 Установлен режим: " .. (mode_name or "none"))
end

-- Функция для очистки текущего режима (при выходе из таблицы клавиш)
M.clear_mode = function()
  local old_mode = wezterm.GLOBALS.session_status.current_mode
  wezterm.GLOBALS.session_status.current_mode = nil
  
  -- НЕ очищаем saved_mode - он остается для операций
  wezterm.log_info("🔥 Текущий режим очищен, сохраненный остается: " .. (wezterm.GLOBALS.session_status.saved_mode or "none"))
end

-- Функция для очистки сохраненного режима
M.clear_saved_mode = function()
  wezterm.GLOBALS.session_status.saved_mode = nil
  wezterm.GLOBALS.session_status.operation_state.active = false
  wezterm.GLOBALS.session_status.operation_state.type = nil
  wezterm.GLOBALS.session_status.operation_state.list_shown = false
  
  if wezterm.GLOBALS.session_status.saved_mode_timer then
    wezterm.GLOBALS.session_status.saved_mode_timer:cancel()
    wezterm.GLOBALS.session_status.saved_mode_timer = nil
  end
  
  wezterm.log_info("🔥 Сохраненный режим очищен")
end

-- Функция для полной очистки режима
M.clear_all_modes = function()
  wezterm.GLOBALS.session_status.current_mode = nil
  wezterm.GLOBALS.session_status.saved_mode = nil
  wezterm.GLOBALS.session_status.operation_state.active = false
  wezterm.GLOBALS.session_status.operation_state.type = nil
  wezterm.GLOBALS.session_status.operation_state.list_shown = false
  
  if wezterm.GLOBALS.session_status.saved_mode_timer then
    wezterm.GLOBALS.session_status.saved_mode_timer:cancel()
    wezterm.GLOBALS.session_status.saved_mode_timer = nil
  end
  
  wezterm.log_info("🔥 Все режимы полностью очищены")
end

-- Функция для начала операции
M.start_operation = function(operation_type)
  wezterm.GLOBALS.session_status.operation_state.active = true
  wezterm.GLOBALS.session_status.operation_state.type = operation_type
  wezterm.GLOBALS.session_status.operation_state.list_shown = false
  wezterm.log_info("🚀 Начата операция: " .. operation_type)
end

-- Функция для отметки что список показан
M.mark_list_shown = function()
  wezterm.GLOBALS.session_status.operation_state.list_shown = true
  wezterm.log_info("📋 Список отображен на экране")
end

-- Функция для завершения операции
M.finish_operation = function()
  wezterm.GLOBALS.session_status.operation_state.active = false
  wezterm.GLOBALS.session_status.operation_state.type = nil
  wezterm.GLOBALS.session_status.operation_state.list_shown = false
  wezterm.log_info("🏁 Операция завершена")
end

-- Функция для запуска анимации загрузки
M.start_loading = function(window)
  local status = wezterm.GLOBALS.session_status
  
  wezterm.log_info("🔄 Запуск анимации загрузки")
  
  M.stop_loading(window)
  
  status.loading.active = true
  status.loading.current_frame = 1
  status.loading.start_time = os.time()
  
  local function update_animation()
    if not status.loading.active then 
      wezterm.log_info("🔄 Анимация деактивирована")
      return 
    end
    
    local elapsed = os.time() - status.loading.start_time
    if elapsed > status.loading.max_duration then
      wezterm.log_info("🔄 Таймаут анимации")
      M.stop_loading(window)
      M.show_notification(window, "Операция превысила лимит времени", "⏰", "#FF9800", 10000, true)
      return
    end
    
    status.loading.current_frame = (status.loading.current_frame % #status.loading.frames) + 1
    status.loading.timer_id = wezterm.time.call_after(0.12, update_animation)
  end
  
  update_animation()
end

-- Функция для остановки анимации загрузки
M.stop_loading = function(window)
  local status = wezterm.GLOBALS.session_status
  
  if not status.loading.active then 
    return 
  end
  
  wezterm.log_info("🔄 ОСТАНАВЛИВАЕМ анимацию загрузки")
  
  status.loading.active = false
  
  if status.loading.timer_id then
    status.loading.timer_id:cancel()
    status.loading.timer_id = nil
  end
  
  if status.loading.force_stop_timer then
    status.loading.force_stop_timer:cancel()
    status.loading.force_stop_timer = nil
  end
end

-- Функция для показа уведомления
M.show_notification = function(window, message, icon, color, duration, hide_mode)
  local status = wezterm.GLOBALS.session_status
  
  M.clear_notification(window)
  
  status.notification.active = true
  status.notification.message = message
  status.notification.icon = icon or "ℹ️"
  status.notification.color = color or "#FFFFFF"
  status.notification.duration = duration or 10000
  status.notification.start_time = os.time() * 1000
  status.notification.hide_mode = hide_mode or false -- скрывать ли режим
  
  wezterm.log_info("📢 Показ уведомления на " .. duration .. "мс: " .. message .. " (скрыть режим: " .. tostring(hide_mode) .. ")")
  
  status.notification.timer_id = wezterm.time.call_after(duration / 1000, function()
    wezterm.log_info("📢 Таймер уведомления истек, очищаем уведомление и режим")
    M.clear_notification(window)
    -- ВАЖНО: очищаем режим только ПОСЛЕ показа уведомления о результате
    if hide_mode then
      wezterm.time.call_after(0.1, function()
        M.clear_saved_mode()
      end)
    end
  end)
end

-- Функция для очистки уведомления
M.clear_notification = function(window)
  local status = wezterm.GLOBALS.session_status
  
  if not status.notification.active then return end
  
  status.notification.active = false
  status.notification.hide_mode = false
  
  if status.notification.timer_id then
    status.notification.timer_id:cancel()
    status.notification.timer_id = nil
  end
  
  wezterm.log_info("📢 Уведомление очищено")
end

-- Функция для получения текущего статуса для отображения
M.get_status_elements = function()
  local status = wezterm.GLOBALS.session_status
  local elements = {}
  
  -- 1. Анимация загрузки (если активна)
  if status.loading.active then
    local frame = status.loading.frames[status.loading.current_frame]
    table.insert(elements, {
      type = "loading",
      icon = frame,
      text = "",
      color = "#8BE9FD"
    })
  end
  
  -- 2. Режим - показываем ТОЛЬКО если уведомление не скрывает его
  if not status.notification.hide_mode then
    local mode_to_show = status.current_mode or status.saved_mode
    if mode_to_show and mode_icons[mode_to_show] then
      local mode = mode_icons[mode_to_show]
      table.insert(elements, {
        type = "mode",
        icon = mode.icon,
        text = mode.name,
        color = mode.color
      })
    end
  end
  
  -- 3. Уведомления о результатах
  if status.notification.active then
    table.insert(elements, {
      type = "notification",
      icon = status.notification.icon,
      text = status.notification.message,
      color = status.notification.color
    })
  end
  
  return elements
end

-- Функции для конкретных операций

-- Сохранение сессии
M.save_session_success = function(window, session_name)
  wezterm.log_info("💾 Успешное сохранение: " .. session_name)
  M.stop_loading(window)
  M.finish_operation()
  M.show_notification(window, "Сохранено: " .. session_name, "✅", "#4CAF50", 10000, true)
end

M.save_session_error = function(window, error_msg)
  wezterm.log_info("💾 Ошибка сохранения: " .. error_msg)
  M.stop_loading(window)
  M.finish_operation()
  M.show_notification(window, "Ошибка сохранения", "❌", "#F44336", 10000, true)
end

-- Загрузка сессий
M.load_session_start = function(window)
  wezterm.log_info("📂 Начало загрузки списка сессий")
  M.start_operation("load")
  M.start_loading(window)
end

M.load_session_list_shown = function(window, count)
  wezterm.log_info("📂 Список показан: " .. count .. " состояний")
  M.stop_loading(window)
  M.mark_list_shown()
  
  if count == 0 then
    M.show_notification(window, "Список пуст", "❌", "#FF9800", 10000, true)
  else
    -- Краткое уведомление о количестве, НЕ скрывающее режим
    M.show_notification(window, "Найдено " .. count .. " состояний", "✅", "#2196F3", 2000, false)
    
    -- Отменяем автоочистку режима для этого уведомления
    local status = wezterm.GLOBALS.session_status
    if status.notification.timer_id then
      status.notification.timer_id:cancel()
      status.notification.timer_id = wezterm.time.call_after(2, function()
        M.clear_notification(window)
        -- НЕ очищаем режим здесь
      end)
    end
  end
end

M.load_session_success = function(window, session_name)
  wezterm.log_info("📂 Успешная загрузка сессии: " .. session_name)
  M.stop_loading(window)
  M.finish_operation()
  M.show_notification(window, "Состояние восстановлено: " .. session_name, "✅", "#4CAF50", 10000, true)
end

M.load_session_cancelled = function(window)
  wezterm.log_info("📂 Загрузка отменена")
  M.stop_loading(window)
  M.finish_operation()
  M.clear_saved_mode()
end

-- Удаление сессий
M.delete_session_start = function(window)
  wezterm.log_info("🗑️ Начало загрузки списка для удаления")
  M.start_operation("delete")
  M.start_loading(window)
end

M.delete_session_list_shown = function(window, count)
  wezterm.log_info("🗑️ Список для удаления показан: " .. count .. " состояний")
  M.stop_loading(window)
  M.mark_list_shown()
  
  if count == 0 then
    M.show_notification(window, "Список пуст", "❌", "#FF9800", 10000, true)
  else
    -- Краткое уведомление о количестве, НЕ скрывающее режим
    M.show_notification(window, "Найдено " .. count .. " состояний", "✅", "#2196F3", 2000, false)
    
    -- Отменяем автоочистку режима для этого уведомления
    local status = wezterm.GLOBALS.session_status
    if status.notification.timer_id then
      status.notification.timer_id:cancel()
      status.notification.timer_id = wezterm.time.call_after(2, function()
        M.clear_notification(window)
        -- НЕ очищаем режим здесь
      end)
    end
  end
end

M.delete_session_success = function(window, session_name)
  wezterm.log_info("🗑️ Успешное удаление сессии: " .. session_name)
  M.stop_loading(window)
  M.finish_operation()
  M.show_notification(window, "Состояние удалено: " .. session_name, "✅", "#9C27B0", 10000, true)
end

M.delete_session_cancelled = function(window)
  wezterm.log_info("🗑️ Удаление отменено")
  M.stop_loading(window)
  M.finish_operation()
  M.clear_saved_mode()
end

-- Общие функции
M.load_session_error = function(window, error_msg)
  wezterm.log_info("📂 Ошибка загрузки: " .. error_msg)
  M.stop_loading(window)
  M.finish_operation()
  M.show_notification(window, "Ошибка загрузки", "❌", "#F44336", 10000, true)
end

M.delete_session_error = function(window, error_msg)
  wezterm.log_info("🗑️ Ошибка удаления: " .. error_msg)
  M.stop_loading(window)
  M.finish_operation()
  M.show_notification(window, "Ошибка удаления", "❌", "#F44336", 10000, true)
end

-- Функция для отладки
M.force_stop_loading = function(window)
  wezterm.log_info("🚨 ПРИНУДИТЕЛЬНАЯ остановка анимации")
  M.stop_loading(window)
end

return M
