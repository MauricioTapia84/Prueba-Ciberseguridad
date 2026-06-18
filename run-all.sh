#!/usr/bin/env bash
set -euo pipefail

# Script para ejecutar el stack completo con Docker Compose.
# Incluye Jenkins, Grafana, Prometheus, ZAP y la aplicación de prueba.

echo "Limpiando stack anterior (si existe)..."
docker compose down -v --remove-orphans || true

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker no está instalado o no está en PATH. Instala Docker antes de continuar."
  exit 1
fi

do_group_info=$(getent group docker || true)
if [ -z "$do_group_info" ]; then
  echo "ERROR: el grupo 'docker' no existe en el host. Verifica la instalación de Docker."
  exit 1
fi
DOCKER_GID=$(printf '%s' "$do_group_info" | cut -d: -f3)
if [ -z "$DOCKER_GID" ]; then
  echo "ERROR: no se pudo determinar el GID del grupo docker."
  exit 1
fi

echo "Construyendo servicios..."
echo "  - usando DOCKER_GID=${DOCKER_GID} para Jenkins"
docker compose build --build-arg DOCKER_GID="${DOCKER_GID}"

echo "Levantando servicios en segundo plano..."
docker compose up -d --force-recreate

echo "Esperando a que los servicios estén disponibles..."
wait_for_url() {
  local url="$1"
  local name="$2"
  local retries=${3:-30}
  local delay=${4:-2}

  for i in $(seq 1 "$retries"); do
    if curl -sSf "$url" >/dev/null 2>&1; then
      echo "OK: $name disponible en $url"
      return 0
    fi
    if [ "$i" -eq "$retries" ]; then
      echo "ERROR: $name no respondió en $url después de $((retries * delay)) segundos"
      return 1
    fi
    sleep "$delay"
  done
}

ports=(8080 3000 8081 9090)
for port in "${ports[@]}"; do
  wait_for_url "http://127.0.0.1:${port}" "Servicio puerto ${port}" 30 2
 done

echo "Esperando a que ZAP esté completamente listo..."
wait_for_url "http://127.0.0.1:8090/JSON/core/view/version/" "ZAP API" 120 2 || true

echo "Servicios levantados:"
docker compose ps

echo "Accesos disponibles:"
echo " - Jenkins: http://localhost:8080"
echo " - Grafana: http://localhost:3000"
echo " - Prometheus: http://localhost:9090"
echo " - ZAP: http://localhost:8090"
echo " - App: http://localhost:8081"
