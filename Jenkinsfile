pipeline {
  agent any
  stages {
    stage('Build') {
      steps {
        sh '''mix deps.get
mix compile
'''
      }
    }
    stage('Test') {
      steps {
        sh './tests/smoke_test.sh'
      }
    }
  }
}