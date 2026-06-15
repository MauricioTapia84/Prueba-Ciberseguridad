pipeline {
  agent any
  environment {
    PYTHON_ENV = 'venv'
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }
    stage('Build & Test (in Docker)') {
      steps {
        // Ejecutar todo dentro de un contenedor python:3.12-slim para no necesitar el plugin Docker Pipeline
        sh '''
        docker run --rm -u $(id -u):$(id -g) -v "$PWD":/workspace -w /workspace python:3.12-slim bash -lc "\
          python3 -m venv $PYTHON_ENV && \
          . $PYTHON_ENV/bin/activate && \
          pip install --upgrade pip && \
          pip install -r Prueba-Ciberseguridad/requirements.txt && \
          mkdir -p Prueba-Ciberseguridad/reports && \
          pytest -q --junitxml=Prueba-Ciberseguridad/reports/test-results.xml
        "
        '''
        // Publicar resultados JUnit y artefactos
        junit 'Prueba-Ciberseguridad/reports/test-results.xml'
        archiveArtifacts artifacts: 'Prueba-Ciberseguridad/reports/**', allowEmptyArchive: true
      }
    }
    stage('Deploy') {
      when {
        branch 'main'
      }
      steps {
        echo 'Deploying to staging...'
        // add deployment commands here (scp, docker, kubectl, etc.)
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
