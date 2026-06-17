#!/usr/bin/env bash
set -euo pipefail

# Ejecuta OWASP ZAP contra la app disponible en la red de Docker Compose.
# Requiere que el stack esté levantado con run-all.sh.

mkdir -p reports/zap

COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-prueba-ciberseguridad}
NETWORK="${COMPOSE_PROJECT_NAME}_devsecops_net"
APP_TARGET="http://app-under-test:8080"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker no está disponible. Instala Docker para ejecutar el escaneo ZAP."
  exit 1
fi

echo "Iniciando DAST con OWASP ZAP en la red ${NETWORK}..."
docker run --rm --network "${NETWORK}" -v "$PWD/reports/zap:/zap/wrk:rw" ghcr.io/zaproxy/zaproxy:stable \
  zap-full-scan.py \
  -t "$APP_TARGET" \
  -r /zap/wrk/zap-full-report.html \
  -J /zap/wrk/zap-full-report.json \
  -x /zap/wrk/zap-full-report.xml

echo "Reporte ZAP generado en reports/zap/"
