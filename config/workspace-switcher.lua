local wezterm = require("wezterm")

local M = {}

M.init = function(workspace_switcher)local debug = require("utils.debug")
local wezterm = require('wezterm')
local M = {}

-- Инициализация плагина Smart Workspace Switcher
M.workspace_switcher = workspace_switcher

-- Настройка пути к zoxide для macOS
workspace_switcher.zoxide_path = "/opt/homebrew/bin/zoxide"

-- Функция для получения сохранённых workspace с безопасной обработкой ошибок
local function get_resurrect_workspaces()
  local saved = {}
  
  -- Безопасная загрузка модулей с проверкой на ошибки
  local success_paths, paths = pcall(require, "config.environment.paths")
  if not success_paths then
    wezterm.log_warn("Не удалось загрузить config.environment.paths: " .. tostring(paths))
    return saved
  end
  
  local success_platform, platform = pcall(require, 'utils.platform')
  if not success_platform then
    wezterm.log_warn("Не удалось загрузить utils.platform: " .. tostring(platform))
    return saved
  end
  
  local platform_instance = platform()
  if not platform_instance then
    wezterm.log_warn("Не удалось инициализировать platform")
    return saved
  end
  
  local workspace_dir = paths.resurrect_state_dir .. "workspace"

  -- Проверяем существование директории
  if not platform_instance.directory_exists(workspace_dir) then
    wezterm.log_info("Директория workspace не найдена: " .. workspace_dir)
    return saved
  end

  -- Безопасное получение списка файлов
  local success_files, files = pcall(platform_instance.get_files_in_directory, workspace_dir, "*.json")
  if not success_files then
    wezterm.log_warn("Ошибка при получении файлов из директории: " .. tostring(files))
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

  wezterm.log_info("Найдено сохранённых workspace: " .. #saved)
  return saved
end

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
    wezterm.log_warn("Ошибка при получении workspace elements: " .. tostring(ws_elements))
  end

  -- Безопасное получение zoxide элементов
  local zoxide_elements = {}
  local success_zoxide, z_elements = pcall(workspace_switcher.choices.get_zoxide_elements, {}, opts)
  if success_zoxide and z_elements then
    zoxide_elements = z_elements
  else
    wezterm.log_warn("Ошибка при получении zoxide elements: " .. tostring(z_elements))
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
    wezterm.log_error("Window parameter is nil")
    return
  end
  
  if not workspace then
    wezterm.log_error("Workspace parameter is nil")
    return
  end

  debug.log("workspace", "debug_workspace_plugin_chosen", tostring(workspace), tostring(label or "нет"))

  -- Проверяем, это сохранённый workspace (по префиксу 💾)
  if label and label:match("^💾 ") then
    local name = label:match("^💾 (.+)$")
    if not name then
      wezterm.log_error("Не удалось извлечь имя workspace из label: " .. tostring(label))
      return
    end
    
    wezterm.log_info("Восстанавливаем сохранённый workspace: " .. name)

    -- Безопасная загрузка модуля resurrect
    local success_resurrect, resurrect = pcall(require, "config.resurrect")
    if not success_resurrect then
      wezterm.log_error("Не удалось загрузить config.resurrect: " .. tostring(resurrect))
      return
    end
    
    if not resurrect.resurrect then
      wezterm.log_error("resurrect.resurrect не найден в модуле")
      return
    end

    -- Безопасная загрузка состояния
    local success_state, state = pcall(resurrect.resurrect.state_manager.load_state, name, "workspace")
    if not success_state then
      wezterm.log_error("Ошибка при загрузке состояния: " .. tostring(state))
      return
    end

    if state then
      -- Безопасное переключение workspace
      local success_switch = pcall(function()
        local active_pane = window:active_pane()
        if not active_pane then
          wezterm.log_error("Не удалось получить active_pane")
          return
        end
        
        window:perform_action(wezterm.action.SwitchToWorkspace({ name = name }), active_pane)
      end)
      
      if not success_switch then
        wezterm.log_error("Ошибка при переключении workspace")
        return
      end

      -- Небольшая задержка для переключения workspace
      wezterm.time.call_after(0.2, function()
        local success_restore = pcall(function()
          local mux_window = window:mux_window()
          if not mux_window then
            wezterm.log_error("Не удалось получить mux_window")
            return
          end
          
          resurrect.resurrect.workspace_state.restore_workspace(state, {
            window = mux_window,
            relative = true,
            restore_text = true,
            on_pane_restore = resurrect.resurrect.tab_state.default_on_pane_restore,
          })
          wezterm.log_info("Workspace " .. name .. " восстановлен успешно")
        end)
        
        if not success_restore then
          wezterm.log_error("Ошибка при восстановлении workspace")
        end
      end)
    else
      wezterm.log_warn("Не удалось загрузить состояние для workspace: " .. name)
    end
  else
    -- Обработка активных workspace
    local current_workspace = window:active_workspace()
    
    if workspace == current_workspace then
      wezterm.log_info("Уже в workspace: " .. workspace .. ", игнорируем")
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
        wezterm.log_info("Активировано окно с workspace: " .. workspace)
      end
    else
      window:perform_action(wezterm.action.SwitchToWorkspace({ name = workspace }), window:active_pane())
    end
  end
end)

return M
-- EOF
end

return M
