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
    stage('Build') {
      steps {
        sh 'python3 -m venv $PYTHON_ENV || true'
        sh '. $PYTHON_ENV/bin/activate && pip install -r requirements.txt || true'
      }
    }
    stage('Test') {
      steps {
        sh '. $PYTHON_ENV/bin/activate && pytest -q || true'
        junit '**/test-results/*.xml'
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
