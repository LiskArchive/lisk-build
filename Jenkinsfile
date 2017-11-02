node('shellcheck'){
  agent { node { label 'lisk-build' } }
  stages {
    stage ('checkout') {
      steps {
        checkout scm
      }
    }
    stage ('shellcheck') {
      steps {
        sh '''#!/bin/bash -xe
        shopt -s globstar; shellcheck **/*.sh
        '''
      }
    }
  }
}
