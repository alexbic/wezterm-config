local wezterm = require('wezterm')
local M = {}

-- Инициализация плагина Smart Workspace Switcher
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
M.workspace_switcher = workspace_switcher

-- Настройка пути к zoxide для macOS
workspace_switcher.zoxide_path = "/opt/homebrew/bin/zoxide"

-- Функция для получения сохранённых workspace с resurrect
local function get_resurrect_workspaces()
 local saved = {}
 local paths = require("config.environment.paths")
 local workspace_dir = paths.resurrect_state_dir .. "workspace"

 -- Проверяем существование директории
 local platform = require('utils.platform')()
 if not platform.directory_exists(workspace_dir) then
   wezterm.log_info("Директория workspace не найдена: " .. workspace_dir)
   return saved
 end

 -- Получаем список файлов
 local files = platform.get_files_in_directory(workspace_dir, "*.json")

 for _, file_path in ipairs(files) do
   local name = file_path:match("([^/\\]+)%.json$")
   if name then
     -- Проверяем, существует ли файл и можем ли его прочитать
     if platform.file_exists(file_path) then
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

-- Кастомная функция получения choices с интеграцией resurrect
workspace_switcher.get_choices = function(opts)
 opts = opts or {}

 -- Получаем стандартные workspace и zoxide элементы
 local workspace_elements = workspace_switcher.choices.get_workspace_elements({})
 local zoxide_elements = workspace_switcher.choices.get_zoxide_elements({}, opts)

 -- Получаем сохранённые workspace из resurrect
 local saved_workspaces = get_resurrect_workspaces()

 -- Объединяем все элементы
 local all_choices = {}

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

-- Обработчик для восстановления workspace при выборе сохранённого
wezterm.on("smart_workspace_switcher.workspace_switcher.chosen", function(window, workspace, label)
 wezterm.log_info("Выбран workspace: " .. workspace .. ", label: " .. (label or "нет"))

 -- Проверяем, это сохранённый workspace (по префиксу 💾)
 if label and label:match("^💾 ") then
   local name = label:match("^💾 (.+)$")
   wezterm.log_info("Восстанавливаем сохранённый workspace: " .. name)

   -- Восстанавливаем состояние
   local resurrect = require("config.resurrect").resurrect
   local state = resurrect.state_manager.load_state(name, "workspace")

   if state then
     -- Переключаемся в workspace перед восстановлением
     window:perform_action(wezterm.action.SwitchToWorkspace({ name = name }), window:active_pane())

     -- Небольшая задержка для переключения workspace
     wezterm.time.call_after(0.2, function()
       resurrect.workspace_state.restore_workspace(state, {
         window = window:mux_window(),
         relative = true,
         restore_text = true,
         on_pane_restore = resurrect.tab_state.default_on_pane_restore,
       })
       wezterm.log_info("Workspace " .. name .. " восстановлен")
     end)
   else
     wezterm.log_warn("Не удалось загрузить состояние для workspace: " .. name)
   end
 end
end)

return M
