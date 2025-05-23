-- cat > ~/.config/wezterm/config/environment/apps.lua << 'EOF'
--
-- ОПИСАНИЕ: Переменные окружения для приложений и языков
-- Настройки для Docker, Kubernetes, Rust, Go, Java и других приложений.
--
-- ЗАВИСИМОСТИ: нет

local M = {
  DOCKER_BUILDKIT = '1',
  COMPOSE_DOCKER_CLI_BUILD = '1',
  KUBE_EDITOR = 'nvim',
  RUST_BACKTRACE = '1',
  CARGO_INCREMENTAL = '1',
  GOPROXY = 'https://proxy.golang.org,direct',
  GOSUMDB = 'sum.golang.org',
  -- JAVA_HOME = '/usr/lib/jvm/java-11-openjdk',
}

return M
