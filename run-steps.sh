#!/bin/bash
set -e
# Script rápido para ejecutar localmente los pasos principales de la evaluación
# Ajusta rutas y comandos según tu proyecto

# 1) Levantar Jenkins demo (opcional)
# docker compose -f docs/jenkins-training/docker-compose.yml up -d

# 2) Preparar entorno y deps
python3 -m venv venv
. venv/bin/activate
pip install --upgrade pip
# install from project requirements in current repo root
pip install -r requirements.txt

# 3) Ejecutar tests
pytest -q --junitxml=reports/test-results.xml || true

# 4) Construir imagen de la app
if command -v docker >/dev/null 2>&1; then
	docker build -t pruebaciberseguridad:latest . || true
else
	echo "docker no está disponible: se omite build/run/scan. Instala Docker para ejecutar esas etapas."
fi

# 5) Ejecutar app en background (intenta elegir un puerto libre)
docker rm -f app-under-test >/dev/null 2>&1 || true

# elegir puerto: usa APP_PORT si está definido, sino busca uno libre entre 8080..8090
if [ -n "${APP_PORT}" ]; then
	PORT=${APP_PORT}
else
	# prefer 8081 by default to avoid common Jenkins conflicts on 8080
	PORT=8081
	for p in $(seq 8080 8090); do
		if ! ss -ltn "sport = :$p" >/dev/null 2>&1 && ! lsof -i :$p >/dev/null 2>&1; then
			PORT=$p
			break
		fi
	done
fi

echo "Iniciando app en puerto host ${PORT} (container:8080)"
if command -v docker >/dev/null 2>&1; then
	docker run -d --name app-under-test -p ${PORT}:8080 pruebaciberseguridad:latest || true
else
	echo "docker no está disponible: no se puede iniciar el contenedor."
fi

# Start Jenkins container if Docker available and Jenkins not present
if command -v docker >/dev/null 2>&1; then
	if [ -z "$(docker ps -aq -f name=^/jenkins$)" ]; then
		echo "Starting Jenkins container on 0.0.0.0:8080 (and 50000)"
		docker run -d --name jenkins -p 8080:8080 -p 50000:50000 \
			-v jenkins_home:/var/jenkins_home \
			jenkins/jenkins:lts || true
	else
		echo "Jenkins container already exists; ensuring it's running"
		docker start jenkins || true
	fi
fi

# 6) Ejecutar OWASP ZAP (automático: PATH, Flatpak, Docker)
mkdir -p reports/zap
ZAP_STARTED=0
ZAP_API_URL="http://127.0.0.1:8090"
APP_URL="http://localhost:${PORT}"

# Try zap.sh in PATH
if command -v zap.sh >/dev/null 2>&1; then
	echo "Found zap.sh in PATH, starting daemon"
	zap.sh -daemon -port 8090 -host 127.0.0.1 &
	ZAP_STARTED=1
	sleep 8
fi

# Try Flatpak ZAP
if [ "$ZAP_STARTED" -eq 0 ]; then
	if command -v flatpak >/dev/null 2>&1 && flatpak info org.zaproxy.ZAP >/dev/null 2>&1; then
		echo "Found Flatpak ZAP, starting via flatpak run"
		flatpak run --command=zap.sh org.zaproxy.ZAP --daemon -port 8090 -host 127.0.0.1 &>/dev/null &
		ZAP_STARTED=1
		sleep 8
	fi
fi

# Try Docker if no local ZAP
if [ "$ZAP_STARTED" -eq 0 ] && command -v docker >/dev/null 2>&1; then
	echo "No local ZAP detected — attempting Docker image"
	ZAP_IMAGE_CANDIDATES=("zaproxy/zap2docker-stable" "zaproxy/zap2docker-weekly" "owasp/zap2docker-stable")
	for img in "${ZAP_IMAGE_CANDIDATES[@]}"; do
		echo "Trying docker pull $img"
		if docker pull "$img" >/dev/null 2>&1; then
			ZAP_IMAGE="$img"
			break
		fi
	done
	if [ -n "$ZAP_IMAGE" ]; then
		echo "Starting ZAP container from $ZAP_IMAGE"
		docker run --rm -u zap -p 8090:8090 --name zap-scan -d "$ZAP_IMAGE" zap.sh -daemon -port 8090 -host 0.0.0.0 || true
		ZAP_STARTED=1
		sleep 8
	else
		echo "Could not pull ZAP docker image; skipping ZAP scan."
	fi
fi

if [ "$ZAP_STARTED" -eq 0 ]; then
	echo "ZAP not available (PATH/Flatpak/Docker). Skipping security scan."
else
	echo "ZAP daemon running — performing spider + passive scan against $APP_URL"
	curl -s "${ZAP_API_URL}/JSON/spider/action/scan/?url=${APP_URL}" >/dev/null || true
	sleep 12

	# Optionally run active scan when RUN_ACTIVE_SCAN=1 (may take long)
	if [ "$RUN_ACTIVE_SCAN" = "1" ]; then
		echo "Starting Active Scan (this may take a while)..."
		ASCAN_ID=$(curl -s "${ZAP_API_URL}/JSON/ascan/action/scan/?url=${APP_URL}" | jq -r '.scan' 2>/dev/null || true)
		# Poll status
		if [ -n "$ASCAN_ID" ]; then
			while true; do
				STATUS=$(curl -s "${ZAP_API_URL}/JSON/ascan/view/status/?scanId=${ASCAN_ID}" | jq -r '.status' 2>/dev/null || true)
				echo "Active scan status: ${STATUS}%"
				if [ "$STATUS" = "100" ] || [ -z "$STATUS" ]; then
					break
				fi
				sleep 5
			done
		fi
	fi

	# Fetch HTML report
	curl -s "${ZAP_API_URL}/OTHER/core/other/htmlreport/" -o "reports/zap/zap-report-local.html" || true
	echo "Saved ZAP HTML report to reports/zap/zap-report-local.html"

	# Also save a machine-readable XML report for tooling if available
	if curl -s --fail "${ZAP_API_URL}/OTHER/core/other/xmlreport/" -o "reports/zap/zap-report.xml"; then
		echo "Saved ZAP XML report to reports/zap/zap-report.xml"
	fi
fi

# 7) Parar app
docker rm -f app-under-test || true

# 8) Recolectar artefactos
ls -l reports || true
