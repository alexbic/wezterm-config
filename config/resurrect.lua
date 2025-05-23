-- cat > ~/.config/wezterm/config/resurrect.lua << 'EOF'
--
-- ОПИСАНИЕ: Объединенный модуль для сохранения и восстановления сессий
-- Включает всю функциональность плагина resurrect.wezterm: 
-- инициализацию, настройку, обработчики событий, и вспомогательные функции.
-- Централизует всю логику сохранения и восстановления сессий.
--
-- ЗАВИСИМОСТИ: utils.session-status

local wezterm = require('wezterm')
local session_status = require('utils.session-status')
local environment = require('config.environment')
local M = {}

-- Инициализация плагина resurrect.wezterm
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
M.resurrect = resurrect

-- Настройка периодического сохранения каждые 5 минут
resurrect.state_manager.periodic_save({
  interval_seconds = 300,
  save_tabs = true,
  save_windows = true,
  save_workspaces = true,
})

-- Ограничение на количество сохраняемых строк
resurrect.state_manager.set_max_nlines(5000)

-- Переменные для отслеживания состояния
local is_periodic_save = false
local is_user_save = false
local current_save_name = ""
local current_operation = nil -- "load", "delete", "save"
local selected_session_name = nil
local list_shown_timer = nil
local pending_operation = nil -- для отслеживания ожидающих операций
local save_timeout_timer = nil
local pending_restore = nil -- для отслеживания отложенного восстановления

-- Функция для принудительного закрытия всех вкладок
local function force_close_all_tabs(window)
  local mux_window = window:mux_window()
  
  wezterm.log_info("🔄 Принудительно закрываем все вкладки")
  
  -- Получаем список всех вкладок
  local tabs = mux_window:tabs()
  wezterm.log_info("🔄 Найдено вкладок: " .. #tabs)
  
  -- Закрываем все вкладки начиная с последней
  for i = #tabs, 1, -1 do
    local tab = tabs[i]
    if tab then
      wezterm.log_info("🔄 Закрываем вкладку " .. i)
      -- Получаем все панели в вкладке
      local panes = tab:panes()
      for j, pane in ipairs(panes) do
        if pane then
          wezterm.log_info("🔄 Закрываем панель " .. j .. " в вкладке " .. i)
          -- Отправляем команду выхода
          pane:send_text("exit\r")
        end
      end
    end
  end
  
  -- Создаем новую чистую вкладку
  wezterm.time.call_after(0.5, function()
    local new_tab = mux_window:spawn_tab({})
    if new_tab then
      wezterm.log_info("🔄 Создана новая чистая вкладка")
    end
  end)
end

-- Функция для выполнения восстановления состояния
local function perform_restore(window, pane, id, session_name, type_info)
  wezterm.log_info("🎯 === НАЧИНАЕМ ВОССТАНОВЛЕНИЕ ===")
  wezterm.log_info("🎯 Состояние: " .. (session_name or "unknown"))
  wezterm.log_info("🎯 ID: " .. (id or "unknown"))
  wezterm.log_info("🎯 Тип: " .. (type_info or "unknown"))
  
  -- Показываем что начинаем восстановление
  session_status.start_loading(window)
  
  -- Регистрируем ожидающую операцию
  pending_operation = {
    type = "load",
    window = window,
    session_name = session_name
  }
  
  local type = string.match(id, "^([^/]+)")
  local clean_id = string.match(id, "([^/]+)$")
  clean_id = string.match(clean_id, "(.+)%..+$")
  
  wezterm.log_info("🎯 Обработанный тип: " .. (type or "unknown"))
  wezterm.log_info("🎯 Обработанный ID: " .. (clean_id or "unknown"))
  
  -- Принудительно закрываем все вкладки
  force_close_all_tabs(window)
  
  -- Ждем перед восстановлением
  wezterm.time.call_after(1.0, function()
    wezterm.log_info("🎯 Выполняем восстановление...")
    
    -- Настройки восстановления - ПОЛНАЯ замена
    local opts = {
      window = window:mux_window(),
      relative = false, -- ВАЖНО: НЕ относительное восстановление
      restore_text = true,
      on_pane_restore = resurrect.tab_state.default_on_pane_restore,
    }
    
    local success = false
    
    if type == "workspace" then
      wezterm.log_info("🎯 Загружаем состояние workspace: " .. clean_id)
      local state = resurrect.state_manager.load_state(clean_id, "workspace")
      if state then
        wezterm.log_info("🎯 Состояние workspace загружено, восстанавливаем...")
        resurrect.workspace_state.restore_workspace(state, opts)
        success = true
      else
        wezterm.log_info("❌ Не удалось загрузить состояние workspace")
      end
    elseif type == "window" then
      wezterm.log_info("🎯 Загружаем состояние window: " .. clean_id)
      local state = resurrect.state_manager.load_state(clean_id, "window")
      if state then
        wezterm.log_info("🎯 Состояние window загружено, восстанавливаем...")
        resurrect.window_state.restore_window(pane:window(), state, opts)
        success = true
      else
        wezterm.log_info("❌ Не удалось загрузить состояние window")
      end
    elseif type == "tab" then
      wezterm.log_info("🎯 Загружаем состояние tab: " .. clean_id)
      local state = resurrect.state_manager.load_state(clean_id, "tab")
      if state then
        wezterm.log_info("🎯 Состояние tab загружено, восстанавливаем...")
        resurrect.tab_state.restore_tab(pane:tab(), state, opts)
        success = true
      else
        wezterm.log_info("❌ Не удалось загрузить состояние tab")
      end
    else
      wezterm.log_info("❌ Неизвестный тип состояния: " .. (type or "nil"))
    end
    
    if not success then
      session_status.load_session_error(window, "Не удалось загрузить состояние")
      pending_operation = nil
    else
      wezterm.log_info("🎯 Восстановление инициировано успешно")
    end
  end)
end

-- ========================== ОБРАБОТЧИКИ СОБЫТИЙ ==========================

local function register_event_handlers()
  -- Обработка ошибок
  wezterm.on('resurrect.error', function(error)
    wezterm.log_info("Событие resurrect.error: " .. tostring(error))
    
    local window = nil
    if wezterm.mux and wezterm.mux.get_active_window then
      window = wezterm.mux.get_active_window()
    end
    
    if window then
      if current_operation == "save" then
        session_status.save_session_error(window, tostring(error))
        current_operation = nil
        is_user_save = false
        current_save_name = ""
      else
        session_status.load_session_error(window, tostring(error))
      end
    end
  end)

  -- Установка флага при начале периодического сохранения
  wezterm.on('resurrect.state_manager.periodic_save.start', function()
    is_periodic_save = true
    wezterm.log_info("🎯 Начало периодического сохранения")
  end)

  -- Обработчик завершения сохранения состояния
  wezterm.on('resurrect.state_manager.save_state.finished', function(session_path)
    wezterm.log_info("🎯 Событие save_state.finished: " .. session_path .. " (periodic: " .. tostring(is_periodic_save) .. ", user: " .. tostring(is_user_save) .. ")")
    
    -- Отменяем таймер таймаута если он есть
    if save_timeout_timer then
      save_timeout_timer:cancel()
      save_timeout_timer = nil
    end
    
    if not is_periodic_save and is_user_save then
      local path = session_path:match(".+/([^/]+)$")
      local name = path and path:match("^(.+)%.json$") or current_save_name or "неизвестно"
      
      local window = nil
      if wezterm.mux and wezterm.mux.get_active_window then
        window = wezterm.mux.get_active_window()
      end
      
      if window then
        wezterm.log_info("🎯 Вызываем save_session_success с именем: " .. name)
        session_status.save_session_success(window, name)
        
        -- Если есть отложенное восстановление - выполняем его
        if pending_restore then
          wezterm.log_info("🎯 Выполняем отложенное восстановление после сохранения")
          wezterm.time.call_after(2, function()
            perform_restore(pending_restore.window, pending_restore.pane, pending_restore.id, pending_restore.session_name, pending_restore.type_info)
            pending_restore = nil
          end)
        end
      end
      
      is_user_save = false
      current_save_name = ""
      current_operation = nil
    elseif is_periodic_save then
      is_periodic_save = false
      wezterm.log_info("🎯 Периодическое сохранение завершено")
    end
  end)

  -- Обработчик начала сохранения состояния
  wezterm.on('resurrect.state_manager.save_state.start', function(state, opt_name)
    wezterm.log_info("🎯 Событие save_state.start с именем: " .. (opt_name or "неизвестно") .. " (periodic: " .. tostring(is_periodic_save) .. ", user: " .. tostring(is_user_save) .. ")")
    
    if not is_periodic_save and is_user_save then
      wezterm.log_info("🎯 Начато пользовательское сохранение")
      current_operation = "save"
      
      -- Устанавливаем таймер таймаута на случай если finished не сработает
      save_timeout_timer = wezterm.time.call_after(10, function()
        wezterm.log_info("🎯 Таймаут сохранения - принудительно показываем успех")
        local window = nil
        if wezterm.mux and wezterm.mux.get_active_window then
          window = wezterm.mux.get_active_window()
        end
        
        if window and is_user_save then
          session_status.save_session_success(window, current_save_name or "сессия")
          is_user_save = false
          current_save_name = ""
          current_operation = nil
          
          -- Если есть отложенное восстановление - выполняем его
          if pending_restore then
            wezterm.log_info("🎯 Выполняем отложенное восстановление после таймаута")
            wezterm.time.call_after(2, function()
              perform_restore(pending_restore.window, pending_restore.pane, pending_restore.id, pending_restore.session_name, pending_restore.type_info)
              pending_restore = nil
            end)
          end
        end
        save_timeout_timer = nil
      end)
    end
  end)

  -- Обработчик завершения загрузки состояния (когда выбрана сессия)
  wezterm.on('resurrect.state_manager.load_state.finished', function(name, type)
    wezterm.log_info("🎯 Событие load_state.finished: " .. name .. ", тип: " .. type)
    
    -- Проверяем, ожидается ли эта операция
    if pending_operation and pending_operation.type == "load" then
      local window = pending_operation.window
      local session_name = pending_operation.session_name or name
      
      wezterm.log_info("🎯 Обрабатываем ожидающую операцию загрузки: " .. session_name)
      session_status.load_session_success(window, session_name)
      
      pending_operation = nil
      current_operation = nil
      selected_session_name = nil
    end
  end)

  -- Обработчик удаления сессии (когда выбрана сессия для удаления)
  wezterm.on('resurrect.state_manager.delete_state.finished', function(id)
    wezterm.log_info("🎯 Событие delete_state.finished: " .. id)
    
    -- Проверяем, ожидается ли эта операция
    if pending_operation and pending_operation.type == "delete" then
      local window = pending_operation.window
      local session_name = pending_operation.session_name
      
      if not session_name then
        local path = id:match(".+/([^/]+)$")
        session_name = path and path:match("^(.+)%.json$") or id
      end
      
      wezterm.log_info("🎯 Обрабатываем ожидающую операцию удаления: " .. session_name)
      session_status.delete_session_success(window, session_name)
      
      pending_operation = nil
      current_operation = nil
      selected_session_name = nil
    end
  end)

  -- Обработчик начала fuzzy_load
  wezterm.on('resurrect.fuzzy_loader.fuzzy_load.start', function(window, pane)
    wezterm.log_info("Событие fuzzy_load.start")
  end)
  
  -- Обработчик завершения fuzzy_load
  wezterm.on('resurrect.fuzzy_loader.fuzzy_load.finished', function(window, pane)
    wezterm.log_info("Событие fuzzy_load.finished")
    
    -- Отменяем таймер показа списка если он есть
    if list_shown_timer then
      list_shown_timer:cancel()
      list_shown_timer = nil
    end
    
    -- Если никого не выбрали в течение короткого времени - это отмена
    wezterm.time.call_after(0.3, function()
      if current_operation and not pending_operation then
        wezterm.log_info("Обнаружена отмена операции: " .. current_operation)
        if current_operation == "load" then
          session_status.load_session_cancelled(window)
        elseif current_operation == "delete" then
          session_status.delete_session_cancelled(window)
        end
        current_operation = nil
        selected_session_name = nil
      end
    end)
  end)

  -- Регистрируем основные обработчики команд resurrect
  
  -- Сохранение состояния
  wezterm.on('resurrect.save_state', function(window, pane)
    wezterm.log_info("Обработчик события resurrect.save_state")
    
    window:perform_action(
      wezterm.action.PromptInputLine({
        description = "Введите имя для сохранения сессии",
        action = wezterm.action_callback(function(inner_win, inner_pane, line)
          if line and line ~= "" then
            -- Устанавливаем флаги ДО начала сохранения
            is_user_save = true
            current_save_name = line
            current_operation = "save"
            
            wezterm.log_info("🎯 Начинаем сохранение с именем: " .. line)
            session_status.start_loading(window)
            
            -- Небольшая задержка чтобы флаги точно установились
            wezterm.time.call_after(0.1, function()
              local state = resurrect.workspace_state.get_workspace_state()
              resurrect.state_manager.save_state(state, line)
            end)
          else
            -- Если отменено, очищаем режим
            wezterm.log_info("🎯 Сохранение отменено пользователем")
            session_status.clear_saved_mode()
          end
        end),
      }),
      pane
    )
  end)

  -- Восстановление состояния
  wezterm.on('resurrect.restore_state', function(window, pane)
    wezterm.log_info("Обработчик события resurrect.restore_state")
    
    local workspace_name = ""
    if wezterm.mux and wezterm.mux.get_active_workspace then
      workspace_name = wezterm.mux.get_active_workspace()
    end
    
    session_status.start_loading(window)
    
    local state = resurrect.state_manager.load_state(workspace_name, "workspace")
    if state then
      force_close_all_tabs(window)
      wezterm.time.call_after(1.0, function()
        resurrect.workspace_state.restore_workspace(state, {
          window = window:mux_window(),
          relative = false, -- НЕ относительное восстановление - заменяем полностью
          restore_text = true,
          on_pane_restore = resurrect.tab_state.default_on_pane_restore,
        })
      end)
    else
      session_status.load_session_error(window, "Сессия не найдена")
    end
  end)

  -- Загрузка состояния
  wezterm.on('resurrect.load_state', function(window, pane)
    wezterm.log_info("Обработчик события resurrect.load_state")
    
    current_operation = "load"
    selected_session_name = nil
    pending_operation = nil
    session_status.load_session_start(window)
    
    -- Останавливаем анимацию когда список появился
    list_shown_timer = wezterm.time.call_after(1, function()
      if current_operation == "load" then
        -- Пытаемся определить количество через состояние resurrect
        local workspace_states = resurrect.state_manager.get_saved_states("workspace") or {}
        local window_states = resurrect.state_manager.get_saved_states("window") or {}
        local tab_states = resurrect.state_manager.get_saved_states("tab") or {}
        
        local total_count = 0
        for _ in pairs(workspace_states) do total_count = total_count + 1 end
        for _ in pairs(window_states) do total_count = total_count + 1 end
        for _ in pairs(tab_states) do total_count = total_count + 1 end
        
        wezterm.log_info("Список загрузки отображен, найдено " .. total_count .. " состояний")
        session_status.load_session_list_shown(window, total_count)
      end
      list_shown_timer = nil
    end)
    
    resurrect.fuzzy_loader.fuzzy_load(
      window, 
      pane, 
      function(id, label)
        wezterm.log_info("🎯 fuzzy_load callback вызван с id: " .. id .. ", label: " .. (label or "no_label"))
        
        -- Определяем тип состояния для отображения пользователю
        local type = string.match(id, "^([^/]+)")
        local type_display = "неизвестно"
        if type == "workspace" then
          type_display = "рабочая область"
        elseif type == "window" then
          type_display = "окно"
        elseif type == "tab" then
          type_display = "вкладка"
        end
        
        -- Сохраняем имя выбранной сессии из label или извлекаем из id
        if label and label ~= "" then
          selected_session_name = label
        else
          local clean_id = string.match(id, "([^/]+)$")
          selected_session_name = clean_id and string.match(clean_id, "(.+)%..+$") or clean_id
        end
        
        wezterm.log_info("🎯 Сохранено имя сессии для загрузки: " .. (selected_session_name or "unknown"))
        
        -- Спрашиваем пользователя о сохранении текущего состояния - НАЧИНАЕМ С ВОПРОСА
        local confirm_message = string.format(
          "Сохранить текущее состояние перед загрузкой? Выбрано: '%s' (%s). (y/да/Enter=нет)",
          selected_session_name or "неизвестно",
          type_display
        )
        
        window:perform_action(
          wezterm.action.PromptInputLine({
            description = confirm_message,
            action = wezterm.action_callback(function(inner_win, inner_pane, line)
              local response = (line or ""):lower()
              local should_save = response == "y" or response == "yes" or response == "да" or response == "д"
              
              wezterm.log_info("🎯 Ответ пользователя на сохранение: '" .. (line or "") .. "', должны сохранить: " .. tostring(should_save))
              
              if should_save then
                wezterm.log_info("🎯 Пользователь хочет сохранить текущее состояние")
                -- Сохраняем информацию о том, что нужно восстановить после сохранения
                pending_restore = {
                  window = window,
                  pane = pane,
                  id = id,
                  session_name = selected_session_name,
                  type_info = type_display
                }
                
                -- Запрашиваем имя для сохранения
                window:perform_action(
                  wezterm.action.PromptInputLine({
                    description = "Введите имя для сохранения текущего состояния",
                    action = wezterm.action_callback(function(save_win, save_pane, save_name)
                      if save_name and save_name ~= "" then
                        is_user_save = true
                        current_save_name = save_name
                        current_operation = "save"
                        
                        session_status.start_loading(window)
                        
                        wezterm.time.call_after(0.1, function()
                          local state = resurrect.workspace_state.get_workspace_state()
                          resurrect.state_manager.save_state(state, save_name)
                        end)
                      else
                        -- Если не ввели имя - отменяем все
                        wezterm.log_info("🎯 Имя не введено, отменяем операцию")
                        pending_restore = nil
                        session_status.clear_saved_mode()
                      end
                    end),
                  }),
                  pane
                )
              else
                wezterm.log_info("🎯 Пользователь не хочет сохранять, восстанавливаем сразу")
                -- Восстанавливаем сразу без сохранения
                perform_restore(window, pane, id, selected_session_name, type_display)
              end
            end),
          }),
          pane
        )
      end,
      {
        title = "Загрузка сессии",
        description = "Выберите сессию для загрузки и нажмите Enter = загрузить, Esc = отмена, / = фильтр",
        fuzzy_description = "Поиск сессии для загрузки: ",
        is_fuzzy = true,
      }
    )
  end)

  -- Удаление состояния
  wezterm.on('resurrect.delete_state', function(window, pane)
    wezterm.log_info("Обработчик события resurrect.delete_state")
    
    current_operation = "delete"
    selected_session_name = nil
    pending_operation = nil
    session_status.delete_session_start(window)
    
    -- Останавливаем анимацию когда список появился
    list_shown_timer = wezterm.time.call_after(1, function()
      if current_operation == "delete" then
        -- Пытаемся определить количество через состояние resurrect
        local workspace_states = resurrect.state_manager.get_saved_states("workspace") or {}
        local window_states = resurrect.state_manager.get_saved_states("window") or {}
        local tab_states = resurrect.state_manager.get_saved_states("tab") or {}
        
        local total_count = 0
        for _ in pairs(workspace_states) do total_count = total_count + 1 end
        for _ in pairs(window_states) do total_count = total_count + 1 end
        for _ in pairs(tab_states) do total_count = total_count + 1 end
        
        wezterm.log_info("Список удаления отображен, найдено " .. total_count .. " состояний")
        session_status.delete_session_list_shown(window, total_count)
      end
      list_shown_timer = nil
    end)
    
    resurrect.fuzzy_loader.fuzzy_load(
      window, 
      pane, 
      function(id)
        wezterm.log_info("🎯 fuzzy_load callback для удаления вызван с id: " .. id)
        
        -- Сохраняем имя выбранной сессии
        local clean_id = string.match(id, "([^/]+)$")
        selected_session_name = clean_id and string.match(clean_id, "(.+)%..+$") or clean_id
        
        wezterm.log_info("🎯 Сохранено имя сессии для удаления: " .. (selected_session_name or "unknown"))
        
        -- Регистрируем ожидающую операцию
        pending_operation = {
          type = "delete",
          window = window,
          session_name = selected_session_name
        }
        
        wezterm.log_info("🎯 Удаляем состояние: " .. id)
        resurrect.state_manager.delete_state(id)
      end,
      {
        title = "Удаление сессии",
        description = "Выберите сессию для удаления и нажмите Enter = удалить, Esc = отмена, / = фильтр",
        fuzzy_description = "Поиск сессии для удаления: ",
        is_fuzzy = true,
      }
    )
  end)

  -- Тестовое событие
  wezterm.on('resurrect.test_notification', function(window, pane)
    wezterm.log_info("Тестовое событие")
    
    if window then
      session_status.start_loading(window)
      
      wezterm.time.call_after(3, function()
        session_status.save_session_success(window, "тестовая_сессия")
      end)
    end
  end)
end

-- Инициализация
register_event_handlers()

return M
