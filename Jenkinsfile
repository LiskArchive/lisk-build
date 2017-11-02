pipeline {
  agent { node { label 'lisk-build' } }
  stages {
    stage ('shellcheck') {
      steps {
        sh '''#!/bin/bash -xe
        shopt -s globstar; shellcheck **/*.sh
        '''
      }
    }
  }
}
