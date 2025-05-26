#!/bin/bash

# Скрипт для синхронизации workspace с zoxide
WORKSPACE_DIR="$HOME/.config/wezterm/plugins/resurrect.wezterm/state/workspace"

if [ -d "$WORKSPACE_DIR" ]; then
  echo "Синхронизируем workspace с zoxide..."
  
  for file in "$WORKSPACE_DIR"/*.json; do
    if [ -f "$file" ]; then
      name=$(basename "$file" .json)
      
      # Пытаемся определить путь из JSON файла
      if command -v jq >/dev/null 2>&1; then
        # Если есть jq, извлекаем путь из первого pane
        cwd=$(jq -r '.window_states[0].tabs[0].pane_tree.cwd // empty' "$file" 2>/dev/null)
        if [ -n "$cwd" ] && [ -d "$cwd" ]; then
          /opt/homebrew/bin/zoxide add "$cwd" 2>/dev/null || true
          echo "Добавлен в zoxide: $cwd ($name)"
        else
          # Fallback: добавляем имя workspace как путь
          /opt/homebrew/bin/zoxide add "$name" 2>/dev/null || true
          echo "Добавлен в zoxide (как имя): $name"
        fi
      else
        # Если нет jq, просто добавляем имя
        /opt/homebrew/bin/zoxide add "$name" 2>/dev/null || true
        echo "Добавлен в zoxide: $name"
      fi
    fi
  done
  
  echo "Синхронизация завершена"
fi
