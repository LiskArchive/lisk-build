node('shellcheck'){
  stage ("Checkout lisk-build") {
    steps {
      checkout scm
    }
  }

  stage ('Shellcheck') {
    steps {
      sh '''#!/bin/bash -xe
      shopt -s globstar; shellcheck **/*.sh
      '''
    }
  }
}
