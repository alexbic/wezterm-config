-- cat > ~/.config/wezterm/utils/resurrect.lua << 'EOF'
--
-- ОПИСАНИЕ: Утилиты для работы с плагином resurrect.wezterm
-- Централизованные функции для сохранения и восстановления сессий.
-- САМОДОСТАТОЧНЫЙ МОДУЛЬ - все зависимости передаются как параметры.
--
-- ЗАВИСИМОСТИ: НЕТ

local M = {}

-- Безопасная функция для получения состояния workspace
M.safe_get_workspace_state = function(resurrect)
  local ok, state = pcall(function()
    return resurrect.workspace_state.get_workspace_state()
  end)
  
  if ok then
    return state
  else
    return nil
  end
end

-- Функция для принудительного закрытия всех вкладок
M.safe_clear_tabs = function(wezterm, window)
  local mux_window = window:mux_window()
  local tabs = mux_window:tabs()
  
  -- Оставляем только первую вкладку, остальные закрываем
  for i = #tabs, 2, -1 do
    local tab = tabs[i]
    if tab then
      tab:activate()
      window:perform_action(wezterm.action.CloseCurrentTab({confirm = false}), tab:active_pane())
    end
  end
end

-- Функция для выполнения восстановления состояния
M.perform_restore = function(wezterm, resurrect, session_status, environment, window, pane, id, session_name, type_info, pending_operation_ref)
  session_status.start_loading(window)
  
  pending_operation_ref.current = {
    type = "load",
    window = window,
    session_name = session_name
  }
  
  local type = string.match(id, "^([^/]+)")
  local clean_id = string.match(id, "([^/]+)$")
  clean_id = string.match(clean_id, "(.+)%..+$")
  
  M.safe_clear_tabs(wezterm, window)
  
  wezterm.time.call_after(1.0, function()
    local opts = {
      window = window:mux_window(),
      relative = false,
      restore_text = true,
      on_pane_restore = resurrect.tab_state.default_on_pane_restore,
    }
    
    local success = false
    
    if type == "workspace" then
      local state = resurrect.state_manager.load_state(clean_id, "workspace")
      if state then
        resurrect.workspace_state.restore_workspace(state, opts)
        success = true
      end
    elseif type == "window" then
      local state = resurrect.state_manager.load_state(clean_id, "window")
      if state then
        resurrect.window_state.restore_window(pane:window(), state, opts)
        success = true
      end
    elseif type == "tab" then
      local state = resurrect.state_manager.load_state(clean_id, "tab")
      if state then
        resurrect.tab_state.restore_tab(pane:tab(), state, opts)
        success = true
      end
    end
    
    if not success then
      session_status.load_session_error(window, environment.locale.t("cannot_get_state"))
      pending_operation_ref.current = nil
    else
      session_status.load_session_success(window, session_name or environment.locale.t("session_saved_as", ""))
    end
  end)
end

-- Функция для создания обработчика сохранения workspace
M.create_save_workspace_handler = function(wezterm, resurrect, session_status, environment, env_utils, icons, state_refs)
  return function(window, pane)
    -- Устанавливаем название вкладки для правильного определения
    local tab = window:active_tab()
    
    tab:set_title(environment.locale.t("save_workspace_tab_title"))    window:perform_action(
      wezterm.action.PromptInputLine({
        description = env_utils.get_icon(icons, "save_workspace_tab") .. " " .. environment.locale.t("enter_save_session_name") .. "\n" .. environment.locale.t("current_workspace", window:active_workspace()) .. "\n\n" .. environment.locale.t("enter_save_default"),
        action = wezterm.action_callback(function(inner_win, inner_pane, line)
          local save_name
          
          if line == nil then
            session_status.end_dialog()            session_status.clear_saved_mode()
            inner_win:active_tab():set_title("")
            return
          elseif line == "" then
            save_name = window:active_workspace()
          else
            save_name = line
          end
          
          if save_name and save_name ~= "" then
            state_refs.is_user_save = true
            state_refs.current_save_name = save_name
            state_refs.current_operation = "save"
            
            session_status.start_loading(window)
            
            -- ПРИНУДИТЕЛЬНЫЙ ТАЙМЕР НА 2 СЕКУНДЫ для ошибок плагина
            state_refs.save_timeout_timer = wezterm.time.call_after(1, function()
              if window then
                session_status.save_session_error(window, environment.locale.t("plugin_error"))
              end
              state_refs.is_user_save = false
              state_refs.current_save_name = ""
              state_refs.current_operation = nil
              state_refs.save_timeout_timer = nil
            end)
            
            wezterm.time.call_after(0.1, function()
              local state = resurrect.workspace_state.get_workspace_state()
              if state then
                resurrect.state_manager.save_state(state, save_name)
              else
                -- Отменяем таймер и сразу очищаем иконку
                if state_refs.save_timeout_timer then
                  state_refs.save_timeout_timer:cancel()
                  state_refs.save_timeout_timer = nil
                end
                session_status.save_session_error(window, environment.locale.t("cannot_get_state"))
                state_refs.is_user_save = false
                state_refs.current_save_name = ""
                state_refs.current_operation = nil
              end
            end)
          else
            session_status.clear_saved_mode()
            session_status.end_dialog()          end
          -- Возвращаем обычное название вкладки
          inner_win:active_tab():set_title("")
        end),
      }),
      pane
    )
  end
end

-- Функция для создания обработчика сохранения window
M.create_save_window_handler = function(wezterm, resurrect, session_status, environment, env_utils, icons)
  return function(window, pane)
    local current_workspace = window:active_workspace()
    local default_name = current_workspace .. "_window_" .. os.date("%H%M%S")
    
    -- Устанавливаем название вкладки для правильного определения
    local tab = window:active_tab()
    
    tab:set_title(environment.locale.t("save_window_tab_title"))    window:perform_action(
      wezterm.action.PromptInputLine({
        description = env_utils.get_icon(icons, "save_window_tab") .. " " .. environment.locale.t("save_window_as") .. "\n" .. environment.locale.t("save_window_default", default_name) .. "\n\n" .. environment.locale.t("save_window_instructions"),
        action = wezterm.action_callback(function(inner_win, inner_pane, line)
          local save_name = (line == "" or line == nil) and default_name or line
          if save_name then
            local window_state = resurrect.window_state.get_window_state(inner_win:mux_window())
            resurrect.state_manager.save_state(window_state, save_name, "window")
            session_status.clear_saved_mode()
            session_status.end_dialog()          end
          -- Возвращаем обычное название вкладки
          inner_win:active_tab():set_title("")
        end),
      }),
      pane
    )
  end
end

-- Функция для создания обработчика сохранения tab
M.create_save_tab_handler = function(wezterm, resurrect, session_status, environment, env_utils, icons)
  return function(window, pane)
    local workspace = window:active_workspace()
    local default_name = workspace .. "_tab_" .. os.date("%H%M%S")
    
    -- Устанавливаем название вкладки для правильного определения
    local tab = window:active_tab()
    tab:set_title(environment.locale.t("save_tab_tab_title"))
    window:perform_action(
      wezterm.action.PromptInputLine({
        description = env_utils.get_icon(icons, "save_tab_tab") .. " " .. environment.locale.t("save_tab_as") .. "\n" .. environment.locale.t("save_tab_default", default_name) .. "\n\n" .. environment.locale.t("save_tab_instructions"),
        action = wezterm.action_callback(function(inner_win, inner_pane, line)
          local save_name = (line == "" or line == nil) and default_name or line
          if save_name then
            local tab = inner_pane:tab() or inner_win:active_tab()
            if not tab then
              wezterm.log_error("Cannot get tab from pane or window")
              session_status.save_session_error(inner_win, environment.locale.t("cannot_get_tab_error"))
              return
            end
            local tab_state = resurrect.tab_state.get_tab_state(tab)
            resurrect.state_manager.save_state(tab_state, save_name, "tab")
            session_status.clear_saved_mode()
            session_status.end_dialog()          end
          -- Возвращаем обычное название вкладки
          inner_win:active_tab():set_title("")
        end),
      }),
      pane
    )
  end
end

-- Функция для создания обработчика загрузки состояния
M.create_load_state_handler = function(wezterm, resurrect, session_status, environment, state_refs, pending_operation_ref)
  return function(window, pane)
    state_refs.current_operation = "load"
    state_refs.selected_session_name = nil
    pending_operation_ref.current = nil
    session_status.load_session_start(window)
    local tab = window:active_tab()
    tab:set_title(environment.locale.t("load_session_tab_title"))
    
    resurrect.fuzzy_loader.fuzzy_load(
      window, 
      pane, 
      function(id, label)
        state_refs.current_operation = nil
        local type = string.match(id, "^([^/]+)")
        local type_display = environment.locale.t("unknown_type")
        if type == "workspace" then
          type_display = environment.locale.t("workspace_type")
        elseif type == "window" then
          type_display = environment.locale.t("window_type")
        elseif type == "tab" then
          type_display = environment.locale.t("tab_type")
        end
        
        if label and label ~= "" then
          state_refs.selected_session_name = label
        else
          local clean_id = string.match(id, "([^/]+)$")
          state_refs.selected_session_name = clean_id and string.match(clean_id, "(.+)%..+$") or clean_id
        end
        
        session_status.end_dialog()        M.perform_restore(wezterm, resurrect, session_status, environment, window, pane, id, state_refs.selected_session_name, type_display, pending_operation_ref)
        -- Возвращаем обычное название вкладки
        window:active_tab():set_title("")
      end,
      {
        title = environment.locale.t("loading_sessions_title"),
        description = environment.locale.t("loading_sessions_description"),
        fuzzy_description = environment.locale.t("loading_sessions_fuzzy"),
        is_fuzzy = true,
      }
    )
  end
end

return M
