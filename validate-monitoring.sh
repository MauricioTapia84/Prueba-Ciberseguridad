#!/usr/bin/env bash
set -euo pipefail

# Valida que Prometheus y la app estén disponibles.
# Requiere que el stack esté levantado con run-all.sh.

function check_url() {
  local url="$1"
  local name="$2"
  if curl -sSf "$url" >/dev/null; then
    echo "OK: $name ($url)"
  else
    echo "ERROR: $name no responde en $url"
    exit 1
  fi
}

check_url "http://127.0.0.1:8081" "App"
check_url "http://127.0.0.1:9090" "Prometheus"
check_url "http://127.0.0.1:3000" "Grafana"

# Verificar configuración de Prometheus scrapeando la página de targets.
if curl -sSf http://127.0.0.1:9090/api/v1/targets | grep -q 'app'; then
  echo "OK: Prometheus scrapea la app"
else
  echo "ERROR: Prometheus no muestra el target de la app"
  exit 1
fi

echo "Validación de monitoreo completada"
