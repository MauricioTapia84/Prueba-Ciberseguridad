pipeline {
  agent any

  environment {
    REPORTS_DIR = 'reports'
    DOCKER_IMAGE = 'pruebaciberseguridad:latest'
    ZAP_IMAGE = 'ghcr.io/zaproxy/zaproxy:stable'
    DAST_NETWORK = 'dast-net'
    APP_URL = 'http://app-under-test:8080'
  }

  options {
    timeout(time: 60, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Prepare') {
      steps {
        sh 'mkdir -p ${REPORTS_DIR}/zap'
      }
    }

    stage('Build') {
      steps {
        sh '''
          set -eux
          python3 -m venv venv
          . venv/bin/activate
          pip install --upgrade pip
          pip install -r requirements.txt
          docker build -t ${DOCKER_IMAGE} .
        '''
      }
    }

    stage('Unit Tests') {
      steps {
        sh '''
          set -eux
          . venv/bin/activate
          pytest -q --junitxml=${REPORTS_DIR}/test-results.xml
        '''
        junit "${REPORTS_DIR}/test-results.xml"
      }
    }

    stage('DAST Scan') {
      steps {
        sh '''
          set -euo pipefail
          docker network inspect ${DAST_NETWORK} >/dev/null 2>&1 || docker network create -d bridge ${DAST_NETWORK}
          docker rm -f app-under-test zap-scan || true
          docker run -d --name app-under-test --network ${DAST_NETWORK} ${DOCKER_IMAGE}

          APP_READY=false
          for i in $(seq 1 30); do
            if docker exec app-under-test python3 -c "import urllib.request, sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8080/').getcode() == 200 else 1)" >/dev/null 2>&1; then
              APP_READY=true
              break
            fi
            echo "Waiting for app to start... (${i}/30)"
            sleep 2
          done

          if [ "${APP_READY}" != "true" ]; then
            echo 'ERROR: app-under-test did not become available on http://127.0.0.1:8080'
            docker logs --tail 100 app-under-test || true
            exit 1
          fi

          docker run -d --name zap-scan --network ${DAST_NETWORK} \
            -v $PWD/${REPORTS_DIR}/zap:/zap/wrk:rw \
            ${ZAP_IMAGE} zap.sh -daemon -host 0.0.0.0 -port 8090 \
            -config api.disablekey=true \
            -config api.addrs.addr.name=.* \
            -config api.addrs.addr.regex=true \
            -config proxyChain.enabled=false

          for i in $(seq 1 60); do
            if docker run --rm --network ${DAST_NETWORK} \
              curlimages/curl:latest --fail --retry 5 --retry-connrefused --retry-delay 2 -s "http://zap-scan:8090/JSON/core/view/version/" >/dev/null 2>&1; then
              break
            fi
            sleep 2
          done

          if ! docker run --rm --network ${DAST_NETWORK} \
            curlimages/curl:latest --fail --retry 5 --retry-connrefused --retry-delay 2 -s "http://zap-scan:8090/JSON/core/view/version/" >/dev/null 2>&1; then
            echo 'ERROR: ZAP daemon did not become available on zap-scan:8090'
            docker logs --tail 100 zap-scan || true
            docker network inspect ${DAST_NETWORK} || true
            exit 1
          fi

          APP_URL=${APP_URL}
          zap_curl_json() {
            local url="$1"
            docker run --rm --network ${DAST_NETWORK} \
              curlimages/curl:latest --fail --retry 5 --retry-connrefused --retry-delay 2 -sS --max-time 60 "${url}"
          }

          zap_json_field() {
            local field="$1"
            python3 - "$field" <<'PY'
import json
import sys
raw = sys.stdin.read()
try:
    data = json.loads(raw)
except (ValueError, TypeError) as exc:
    sys.stderr.write("DEBUG: invalid JSON for field={}: {}\n".format(sys.argv[1], exc))
    sys.exit(1)
if isinstance(data, dict):
    value = data.get(sys.argv[1], "")
    sys.stdout.write(str(value))
else:
    sys.stdout.write("")
PY
          }

          SPIDER_ID=""
          for i in $(seq 1 10); do
            RESPONSE=$(zap_curl_json "http://zap-scan:8090/JSON/spider/action/scan/?url=${APP_URL}" 2>/dev/null || true)
            printf 'DEBUG: Spider response=%s\n' "$RESPONSE"
            SPIDER_ID=$(printf '%s' "$RESPONSE" | zap_json_field scan | tr -d '[:space:]')
            if [ -n "${SPIDER_ID}" ]; then
              break
            fi
            echo "WARN: Spider ID empty, retrying (${i}/10)..."
            sleep 2
          done
          if [ -z "${SPIDER_ID}" ]; then
            echo 'ERROR: Spider scan did not return a scan ID'
            docker logs --tail 100 zap-scan || true
            docker run --rm --network ${DAST_NETWORK} \
              curlimages/curl:latest -sS "http://zap-scan:8090/JSON/core/view/alerts/" || true
            exit 1
          fi

          for i in $(seq 1 60); do
            SPIDER_STATUS=$(zap_curl_json "http://zap-scan:8090/JSON/spider/view/status/?scanId=${SPIDER_ID}" | zap_json_field status)
            if [ "${SPIDER_STATUS}" = "100" ]; then
              break
            fi
            echo "Spider status: ${SPIDER_STATUS}%"
            sleep 2
          done

          ASCAN_ID=""
          for i in $(seq 1 10); do
            ASCAN_ID=$(zap_curl_json "http://zap-scan:8090/JSON/ascan/action/scan/?url=${APP_URL}" | zap_json_field scan)
            if [ -n "${ASCAN_ID}" ]; then
              break
            fi
            echo "WARN: Active scan ID empty, retrying (${i}/10)..."
            sleep 2
          done
          if [ -z "${ASCAN_ID}" ]; then
            echo 'ERROR: Active scan did not return a scan ID'
            docker logs --tail 100 zap-scan || true
            exit 1
          fi

          for i in $(seq 1 120); do
            ASCAN_STATUS=$(zap_curl_json "http://zap-scan:8090/JSON/ascan/view/status/?scanId=${ASCAN_ID}" | zap_json_field status)
            if [ "${ASCAN_STATUS}" = "100" ]; then
              break
            fi
            echo "Active scan status: ${ASCAN_STATUS}%"
            sleep 5
          done

          docker run --rm --network ${DAST_NETWORK} \
            -v $PWD/${REPORTS_DIR}/zap:/zap/wrk:rw \
            curlimages/curl:latest -s http://zap-scan:8090/OTHER/core/other/htmlreport/ -o /zap/wrk/zap-full-report.html

          docker run --rm --network ${DAST_NETWORK} \
            -v $PWD/${REPORTS_DIR}/zap:/zap/wrk:rw \
            curlimages/curl:latest -s http://zap-scan:8090/OTHER/core/other/xmlreport/ -o /zap/wrk/zap-full-report.xml

          docker run --rm --network ${DAST_NETWORK} \
            -v $PWD/${REPORTS_DIR}/zap:/zap/wrk:rw \
            curlimages/curl:latest -s "http://zap-scan:8090/JSON/core/view/alerts/?baseurl=${APP_URL}" -o /zap/wrk/zap-full-report.json
        '''
      }
      post {
        always {
          sh 'docker rm -f app-under-test zap-scan || true'
        }
      }
    }

    stage('Verify Image') {
      when {
        branch 'main'
      }
      steps {
        sh '''
          set -eux
          docker image inspect ${DOCKER_IMAGE}
          echo "Docker image ${DOCKER_IMAGE} is ready."
        '''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: '${REPORTS_DIR}/**', allowEmptyArchive: true
    }
    success {
      echo 'Pipeline completed successfully.'
    }
    failure {
      echo 'Pipeline failed. Revisa los artefactos en reports/'
    }
  }
}
