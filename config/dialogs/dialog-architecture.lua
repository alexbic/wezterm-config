local M = {}

M.DIALOG_TYPES = {
  main_list = "главный список с статистикой",
  detail_view = "детальный просмотр элемента", 
  actions = "действия с элементом",
  mass_operations = "массовые операции"
}

M.INTERFACE_STANDARDS = {
  title_location = "tab_only",
  numbering = false,
  color_separators = true,
  multi_level = true
}

M.TEMPLATE_STRUCTURE = {
  instruction = "краткая инструкция",
  separator = "цветная разделительная строка",
  items = "список без нумерации",
  actions = "кнопки действий"
}

return M
