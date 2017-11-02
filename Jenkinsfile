pipeline {
  agent { node { label 'shellcheck' } }
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
