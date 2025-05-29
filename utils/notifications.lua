-- cat > ~/.config/wezterm/utils/notifications.lua << 'EOF'
--
-- ОПИСАНИЕ: Модуль для работы с уведомлениями
-- Централизованная логика для отображения уведомлений в строке состояния,
-- во всплывающих сообщениях и в панели. Избегает дублирования кода.
-- ПОЛНОСТЬЮ САМОДОСТАТОЧНЫЙ МОДУЛЬ - все зависимости передаются как параметры.
--
-- ЗАВИСИМОСТИ: НЕТ

local M = {}

-- Инициализируем глобальные переменные для уведомлений
if not _G.WEZTERM_NOTIFICATIONS then
  _G.WEZTERM_NOTIFICATIONS = {
    notification_message = nil,
    notification_time = 0,
    notification_timeout = 0
  }
end

-- Функция для отображения уведомления в строке состояния
M.show_status_notification = function(wezterm, window, message, timeout_ms)
  if not window then
    wezterm.log_info("Нет окна для отображения уведомления")
    return
  end
  
  wezterm.log_info("Создание уведомления в строке состояния: " .. message)
  
  -- Устанавливаем глобальную переменную с сообщением
  _G.WEZTERM_NOTIFICATIONS.notification_message = message
  _G.WEZTERM_NOTIFICATIONS.notification_time = os.time()
  _G.WEZTERM_NOTIFICATIONS.notification_timeout = timeout_ms or 5000
  
  -- Вызываем событие обновления статуса для отображения сообщения
  window:set_right_status(wezterm.format({
    { Foreground = { Color = "orange" } },
    { Text = "[УВЕДОМЛЕНИЕ] " },
    { Foreground = { Color = "white" } },
    { Text = message },
  }))
  
  -- Запускаем таймер для очистки сообщения
  if timeout_ms and timeout_ms > 0 then
    -- Создаем таймер для очистки сообщения
    wezterm.time.call_after(timeout_ms / 1000, function()
      if _G.WEZTERM_NOTIFICATIONS.notification_message == message then
        window:set_right_status("")
        _G.WEZTERM_NOTIFICATIONS.notification_message = nil
      end
    end)
  end
end

-- Функция для отображения уведомления в панели
M.show_pane_notification = function(pane, message)
  if not pane then
    return
  end
  
  -- Просто выводим текст без ANSI-кодов цвета
  pane:send_text("\n[УВЕДОМЛЕНИЕ] " .. message .. "\n")
end

-- Функция для отображения всплывающего уведомления
M.show_toast_notification = function(window, title, message, timeout_ms)
  if not window then
    return
  end
  
  -- Безопасный вызов gui_window с проверкой доступности
  if window.gui_window then
    local gui_win = window:gui_window()
    if gui_win then
      gui_win:toast_notification(
        title,
        message,
        nil,
        timeout_ms or 3000
      )
    end
  end
end

-- Комбинированная функция для отображения уведомления во всех доступных местах
M.notify = function(wezterm, window, pane, message, title, timeout_ms)
  title = title or "WezTerm"
  
  -- Показываем в строке состояния
  if window then
    M.show_status_notification(wezterm, window, message, timeout_ms)
  end
  
  -- Показываем всплывающее уведомление вместо вывода в панель
  if window then
    M.show_toast_notification(window, title, message, timeout_ms)
  end
end

-- Установка обработчика для обновления строки состояния
M.setup_status_updater = function(wezterm)
  wezterm.on('update-right-status', function(window, pane)
    -- Проверяем, есть ли активное уведомление
    if _G.WEZTERM_NOTIFICATIONS.notification_message then
      -- Проверяем, не истекло ли время показа
      local elapsed = os.time() - _G.WEZTERM_NOTIFICATIONS.notification_time
      local elapsed_ms = elapsed * 1000
      
      if elapsed_ms < _G.WEZTERM_NOTIFICATIONS.notification_timeout then
        -- Показываем сообщение
        window:set_right_status(wezterm.format({
          { Foreground = { Color = "orange" } },
          { Text = "[УВЕДОМЛЕНИЕ] " },
          { Foreground = { Color = "white" } },
          { Text = _G.WEZTERM_NOTIFICATIONS.notification_message },
        }))
      else
        -- Очищаем сообщение, если истекло время
        window:set_right_status("")
        _G.WEZTERM_NOTIFICATIONS.notification_message = nil
      end
    end
  end)
end

return M
