pipeline {
  agent any
  stages {
    stage('Build') {
      parallel {
        stage('Get dependencies') {
          steps {
            sh '''mix deps.get
'''
          }
        }
        stage('Compile dependencies') {
          steps {
            sh 'mix deps.compile'
          }
        }
        stage('Compile app') {
          steps {
            sh 'mix compile'
          }
        }
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