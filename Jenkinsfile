pipeline {
  agent any

  environment {
    REPORTS_DIR = 'reports'
    DOCKER_IMAGE = 'pruebaciberseguridad:latest'
    ZAP_IMAGE = 'ghcr.io/zaproxy/zaproxy:stable'
    NETWORK = 'prueba-ciberseguridad_devsecops_net'
    APP_URL = 'http://app-under-test:8080'
  }

  options {
    ansiColor('xterm')
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
        junit '${REPORTS_DIR}/test-results.xml'
      }
    }

    stage('DAST Scan') {
      steps {
        sh '''
          set -eux
          docker rm -f app-under-test || true
          docker run -d --name app-under-test --network ${NETWORK} -p 8081:8080 ${DOCKER_IMAGE}

          for i in $(seq 1 30); do
            if curl -sSf http://app-under-test:8080/ >/dev/null 2>&1; then
              break
            fi
            sleep 2
          done

          docker run --rm --network ${NETWORK} -v $PWD/${REPORTS_DIR}/zap:/zap/wrk:rw ${ZAP_IMAGE} zap-full-scan.py \
            -t ${APP_URL} \
            -r /zap/wrk/zap-full-report.html \
            -J /zap/wrk/zap-full-report.json \
            -x /zap/wrk/zap-full-report.xml
        '''
      }
      post {
        always {
          sh 'docker rm -f app-under-test || true'
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
      echo 'Pipeline failed. Revisa los artefactos en reports/'.
    }
  }
}
