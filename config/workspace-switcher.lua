-- cat > ~/.config/wezterm/config/workspace-switcher.lua << 'EOF'
--
-- ОПИСАНИЕ: Интеграция с плагином Smart Workspace Switcher
-- Настройка workspace switcher с поддержкой resurrect и zoxide
--
-- ЗАВИСИМОСТИ: wezterm, utils.debug

local debug = require("utils.debug")
local wezterm = require('wezterm')
local environment = require('config.environment')
local M = {}

-- Функция для получения сохранённых workspace с безопасной обработкой ошибок
local function get_resurrect_workspaces()
  local saved = {}
  
  -- Безопасная загрузка модулей с проверкой на ошибки
  local success_paths, paths = pcall(require, "config.environment.paths")
  if not success_paths then
    debug.log("workspace", "error_config_environment_paths", tostring(paths))
    return saved
  end
  
  -- Создаем platform_info используя utils.platform
  local success_platform, create_platform_info = pcall(require, 'utils.platform')
  if not success_platform then
    debug.log("workspace", "error_utils_platform", tostring(create_platform_info))
    return saved
  end
  
  local platform_instance = create_platform_info(wezterm.target_triple)
  if not platform_instance then
    debug.log("workspace", "error_platform_initialization")
    return saved
  end
  
  local workspace_dir = paths.resurrect_state_dir .. "workspace"

  -- Проверяем существование директории
  if not platform_instance.directory_exists(workspace_dir) then
    debug.log("workspace", "debug_workspace_directory_not_found", workspace_dir)
    return saved
  end

  -- Безопасное получение списка файлов
  local success_files, files = pcall(platform_instance.get_files_in_directory, workspace_dir, "*.json")
  if not success_files then
    debug.log("workspace", "error_get_files_in_directory", tostring(files))
    return saved
  end

  for _, file_path in ipairs(files or {}) do
    local name = file_path:match("([^/\\]+)%.json$")
    if name then
      -- Проверяем, существует ли файл и можем ли его прочитать
      if platform_instance.file_exists(file_path) then
        table.insert(saved, {
          id = name,
          label = "💾 " .. name,
          path = workspace_dir  -- Для совместимости с zoxide
        })
      end
    end
  end

  debug.log("workspace", "debug_workspace_found_saved", #saved)
  return saved
end

M.init = function(workspace_switcher)
  -- Инициализация плагина Smart Workspace Switcher
  M.workspace_switcher = workspace_switcher

  -- Настройка пути к zoxide для macOS
  workspace_switcher.zoxide_path = "/opt/homebrew/bin/zoxide"

  -- Кастомная функция получения choices с интеграцией resurrect и безопасной обработкой
  workspace_switcher.get_choices = function(opts)
    opts = opts or {}

    local all_choices = {}

    -- Безопасное получение стандартных workspace элементов
    local workspace_elements = {}
    local success_workspace, ws_elements = pcall(workspace_switcher.choices.get_workspace_elements, {})
    if success_workspace and ws_elements then
      workspace_elements = ws_elements
    else
      debug.log("workspace", "error_get_workspace_elements", tostring(ws_elements))
    end

    -- Безопасное получение zoxide элементов
    local zoxide_elements = {}
    local success_zoxide, z_elements = pcall(workspace_switcher.choices.get_zoxide_elements, {}, opts)
    if success_zoxide and z_elements then
      zoxide_elements = z_elements
    else
      debug.log("workspace", "error_get_zoxide_elements", tostring(z_elements))
    end

    -- Получаем сохранённые workspace из resurrect
    local saved_workspaces = get_resurrect_workspaces()

    -- Добавляем текущие workspace (приоритет)
    for _, element in ipairs(workspace_elements) do
      table.insert(all_choices, element)
    end

    -- Добавляем сохранённые workspace
    for _, element in ipairs(saved_workspaces) do
      table.insert(all_choices, element)
    end

    -- Добавляем zoxide элементы
    for _, element in ipairs(zoxide_elements) do
      table.insert(all_choices, element)
    end

    return all_choices
  end

  -- Обработчик для восстановления workspace при выборе сохранённого с полной безопасностью
  wezterm.on("smart_workspace_switcher.workspace_switcher.chosen", function(window, workspace, label)
    -- Проверяем валидность параметров
    if not window then
      debug.log("workspace", "error_window_parameter_nil")
      return
    end
    
    if not workspace then
      debug.log("workspace", "error_workspace_parameter_nil")
      return
    end

    debug.log("workspace", "debug_workspace_plugin_chosen", tostring(workspace), tostring(label or "нет"))

    -- Проверяем, это сохранённый workspace (по префиксу 💾)
    if label and label:match("^💾 ") then
      local name = label:match("^💾 (.+)$")
      if not name then
        debug.log("workspace", "error_extract_workspace_name", tostring(label))
        return
      end
      
      debug.log("workspace", "debug_workspace_restoring_saved", name)

      -- Безопасная загрузка модуля resurrect
      local success_resurrect, resurrect = pcall(require, "config.resurrect")
      if not success_resurrect then
        debug.log("workspace", "error_config_resurrect", tostring(resurrect))
        return
      end
      
      if not resurrect.resurrect then
        debug.log("workspace", "error_resurrect_not_found")
        return
      end

      -- Безопасная загрузка состояния
      local success_state, state = pcall(resurrect.resurrect.state_manager.load_state, name, "workspace")
      if not success_state then
        debug.log("workspace", "error_load_state", tostring(state))
        return
      end

      if state then
        -- Безопасное переключение workspace
        local success_switch = pcall(function()
          local active_pane = window:active_pane()
          if not active_pane then
            debug.log("workspace", "error_active_pane_nil")
            return
          end
          
          window:perform_action(wezterm.action.SwitchToWorkspace({ name = name }), active_pane)
        end)
        
        if not success_switch then
          debug.log("workspace", "error_workspace_switch_failed")
          return
        end

        -- Небольшая задержка для переключения workspace
        wezterm.time.call_after(0.2, function()
          local success_restore = pcall(function()
            local mux_window = window:mux_window()
            if not mux_window then
              debug.log("workspace", "error_mux_window_nil")
              return
            end
            
            resurrect.resurrect.workspace_state.restore_workspace(state, {
              window = mux_window,
              relative = true,
              restore_text = true,
              on_pane_restore = resurrect.resurrect.tab_state.default_on_pane_restore,
            })
            debug.log("workspace", "debug_workspace_restored_successfully", name)
          end)
          
          if not success_restore then
            debug.log("workspace", "error_workspace_restore_failed")
          end
        end)
      else
        debug.log("workspace", "error_load_state_failed", name)
      end
    else
      -- Обработка активных workspace
      local current_workspace = window:active_workspace()
      
      if workspace == current_workspace then
        debug.log("workspace", "debug_workspace_already_active", workspace)
        return
      end
      
      -- Ищем окно с нужным workspace
      local mux = wezterm.mux
      local found_window = nil
      
      for _, win in ipairs(mux.all_windows()) do
        if win:get_workspace() == workspace then
          found_window = win
          break
        end
      end
      
      if found_window then
        local gui_win = found_window:gui_window()
        if gui_win then
          gui_win:focus()
          gui_win:raise()
          debug.log("workspace", "debug_workspace_window_activated", workspace)
        end
      else
        window:perform_action(wezterm.action.SwitchToWorkspace({ name = workspace }), window:active_pane())
      end
    end
  end)
end

return M
