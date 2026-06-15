pipeline {
  agent any
  environment {
    REPORTS_DIR = 'reports'
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Unit Tests') {
      steps {
        sh 'python3 -m venv venv || true'
        sh '. venv/bin/activate && pip install -r requirements.txt'
        sh '. venv/bin/activate && pytest -q --junitxml=${REPORTS_DIR}/test-results.xml || true'
        junit '${REPORTS_DIR}/test-results.xml'
      }
    }

    stage('Build & Security Scan') {
      steps {
        withEnv(['DOCKER_HOST=tcp://dind:2375']) {
          sh 'docker build -t pruebaciberseguridad:latest .'
          sh 'docker rm -f app-under-test || true'
          sh 'docker run -d --name app-under-test -p 8080:8080 pruebaciberseguridad:latest'
          sh 'mkdir -p ${REPORTS_DIR}/zap'
          sh "docker run --rm -v ${WORKSPACE}/${REPORTS_DIR}/zap:/zap/wrk:rw owasp/zap2docker-stable zap-baseline.py -t http://localhost:8080 -r /zap/wrk/zap-report.html || true"
          archiveArtifacts artifacts: '${REPORTS_DIR}/**', fingerprint: true
          publishHTML (target: [reportName: 'ZAP', reportDir: '${REPORTS_DIR}/zap', reportFiles: 'zap-report.html', keepAll: true])
          sh 'docker rm -f app-under-test || true'
        }
      }
    }
  }
  post {
    always {
      archiveArtifacts artifacts: '${REPORTS_DIR}/**', allowEmptyArchive: true
    }
  }
}
pipeline {
  agent {
    docker {
      image 'python:3.12-slim'
      args '-u root:root'
    }
  }
  environment {
    PYTHON_ENV = 'venv'
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }
    stage('Build') {
      steps {
        sh 'python3 -m venv $PYTHON_ENV'
        sh '. $PYTHON_ENV/bin/activate && pip install --upgrade pip && pip install -r Prueba-Ciberseguridad/requirements.txt'
      }
    }
    stage('Test') {
      steps {
        sh '. $PYTHON_ENV/bin/activate && pytest -q --junitxml=Prueba-Ciberseguridad/reports/test-results.xml'
        junit 'Prueba-Ciberseguridad/reports/test-results.xml'
      }
      post {
        always {
          archiveArtifacts artifacts: 'Prueba-Ciberseguridad/reports/**', allowEmptyArchive: true
        }
      }
    }
    stage('Security Scan (OWASP ZAP)') {
      steps {
        script {
          // ensure reports folder
          sh 'mkdir -p Prueba-Ciberseguridad/reports/zap'
          // start app in background (example: run app with docker-compose or python -m http.server)
          // start app in background using the project image built in Deploy stage
          sh "docker run -d --name app-under-test -p 8080:8080 pruebaciberseguridad:latest || true"
          // run ZAP baseline scan against localhost:8080 and produce HTML report
          sh "docker run --rm -v $PWD/Prueba-Ciberseguridad/reports/zap:/zap/wrk:rw owasp/zap2docker-stable zap-baseline.py -t http://localhost:8080 -r /zap/wrk/zap-report.html || true"
          // fallback for linux host without host.docker.internal: use host networking or container IP
          sh "docker ps -qf name=app-under-test | xargs -r docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' > /tmp/app_ip || true"
          sh "cp Prueba-Ciberseguridad/reports/zap/zap-report.html Prueba-Ciberseguridad/reports/zap-report.html || true"
        }
      }
      post {
        always {
          archiveArtifacts artifacts: 'Prueba-Ciberseguridad/reports/zap/**, Prueba-Ciberseguridad/reports/zap-report.html', allowEmptyArchive: true
          publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'Prueba-Ciberseguridad/reports/zap', reportFiles: 'zap-report.html', reportName: 'OWASP ZAP Report'])
        }
      }
    }
    stage('Deploy') {
      when {
        branch 'main'
      }
      steps {
        echo 'Deploying to staging...'
        // Example deploy: build image and run (customize as needed)
        sh 'docker build -t pruebaciberseguridad:latest Prueba-Ciberseguridad || true'
        sh 'docker rm -f pruebaciberseguridad || true || true'
        sh 'docker run -d --name pruebaciberseguridad -p 8000:8000 pruebaciberseguridad:latest || true'
      }
    }
  }
  post {
    success {
      echo 'Pipeline succeeded'
    }
    failure {
      echo 'Pipeline failed'
    }
  }
}
