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
        // Crear entorno virtual e instalar dependencias
        sh 'python3 -m venv $PYTHON_ENV'
        sh '. $PYTHON_ENV/bin/activate && pip install --upgrade pip && pip install -r Prueba-Ciberseguridad/requirements.txt'
      }
    }
    stage('Test') {
      steps {
        // Ejecutar tests y generar reporte JUnit en la carpeta reports
        sh '. $PYTHON_ENV/bin/activate && pytest -q --junitxml=Prueba-Ciberseguridad/reports/test-results.xml'
        junit 'Prueba-Ciberseguridad/reports/test-results.xml'
      }
      post {
        always {
          archiveArtifacts artifacts: 'reports/**', allowEmptyArchive: true
        }
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
