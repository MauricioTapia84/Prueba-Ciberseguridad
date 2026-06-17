pipeline {
  agent any

  environment {
    REPORTS_DIR = 'Prueba-Ciberseguridad/reports'
    DOCKER_IMAGE = 'pruebaciberseguridad:latest'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Setup') {
      steps { sh 'mkdir -p ${REPORTS_DIR}/zap' }
    }

    stage('Build') {
      steps {
        sh 'python3 -m venv venv || true'
        sh '. venv/bin/activate && pip install --upgrade pip || true'
        sh '. venv/bin/activate && pip install -r Prueba-Ciberseguridad/requirements.txt || true'
        sh 'docker build -t ${DOCKER_IMAGE} Prueba-Ciberseguridad || true'
      }
    }

    stage('Test') {
      steps {
        sh '. venv/bin/activate && pytest -q --junitxml=${REPORTS_DIR}/test-results.xml || true'
        junit '${REPORTS_DIR}/test-results.xml'
      }
      post { always { archiveArtifacts artifacts: '${REPORTS_DIR}/**', allowEmptyArchive: true } }
    }

    stage('Security Scan (OWASP ZAP)') {
      steps {
        script {
          sh 'docker rm -f app-under-test || true'
          sh 'docker run -d --name app-under-test -p 8080:8080 ${DOCKER_IMAGE} || true'
          sh 'echo "Esperando a que la aplicación responda en http://localhost:8080..."'
          sh 'for i in 1 2 3 4 5 6 7 8 9 10; do if curl -sSf http://localhost:8080 >/dev/null 2>&1; then echo "app disponible" && break; else echo "esperando... ($i)"; sleep 1; fi; done'
          sh 'ZAP_REPORT="zap-report-$(date +%Y%m%d-%H%M%S).html"'
          sh 'docker run --rm -v $PWD/${REPORTS_DIR}/zap:/zap/wrk:rw owasp/zap2docker-stable zap-baseline.py -t http://localhost:8080 -r /zap/wrk/${ZAP_REPORT} || true'
          sh 'ZAP_FILE=$(ls -t ${REPORTS_DIR}/zap/*.html 2>/dev/null | head -n1 || true)'
          sh 'if [ -n "$ZAP_FILE" ]; then cp "$ZAP_FILE" ${REPORTS_DIR}/zap-report.html || true; fi'
          sh 'docker rm -f app-under-test || true'
        }
      }
      post {
        always {
          archiveArtifacts artifacts: '${REPORTS_DIR}/**', allowEmptyArchive: true
          publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: '${REPORTS_DIR}/zap', reportFiles: 'zap-report.html,zap-report-local.html', reportName: 'OWASP ZAP Report'])
        }
      }
    }

    stage('Deploy') {
      when { branch 'main' }
      steps {
        echo 'Deploying to staging...'
        sh 'docker build -t ${DOCKER_IMAGE} Prueba-Ciberseguridad || true'
        sh 'docker rm -f pruebaciberseguridad || true'
        sh 'docker run -d --name pruebaciberseguridad -p 8000:8000 ${DOCKER_IMAGE} || true'
      }
    }
  }

  post {
    success { echo 'Pipeline succeeded' }
    failure { echo 'Pipeline failed' }
    always { archiveArtifacts artifacts: '${REPORTS_DIR}/**', allowEmptyArchive: true }
  }
}
              sh 'docker build -t ${DOCKER_IMAGE} Prueba-Ciberseguridad || true'
