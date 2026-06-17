#!/usr/bin/env bash
set -euo pipefail

# Limpia el stack de Docker Compose y los volúmenes asociados.

docker compose down -v --remove-orphans

echo "Stack detenido y eliminado."