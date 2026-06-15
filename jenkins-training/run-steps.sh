#!/bin/bash
set -e
# Script rápido para ejecutar localmente los pasos principales de la evaluación
# Ajusta rutas y comandos según tu proyecto

# 1) Levantar Jenkins demo (opcional)
# docker compose -f jenkins-training/docker-compose.yml up -d

# 2) Preparar entorno y deps
python3 -m venv venv
. venv/bin/activate
pip install --upgrade pip
# instalar desde requirements en la raíz del proyecto
pip install -r requirements.txt

# 3) Ejecutar tests
pytest -q --junitxml=reports/test-results.xml || true

# 4) Construir imagen de la app
docker build -t pruebaciberseguridad:latest . || true

# 5) Ejecutar app en background
docker rm -f app-under-test || true
docker run -d --name app-under-test -p 8080:8080 pruebaciberseguridad:latest || true

# 6) Ejecutar OWASP ZAP baseline
mkdir -p reports/zap
# usa host.docker.internal en Docker Desktop; en Linux usa la IP del contenedor
docker run --rm -v $(pwd)/reports/zap:/zap/wrk:rw owasp/zap2docker-stable zap-baseline.py -t http://localhost:8080 -r /zap/wrk/zap-report.html || true

# 7) Parar app
docker rm -f app-under-test || true

# 8) Recolectar artefactos
ls -l reports || true
