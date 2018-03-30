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
        sh './test/smoke_test.sh'
      }
    }
    stage('Test On Projects') {
      steps {
        sh './test/test_on_projects.sh'
      }
    }
  }
}