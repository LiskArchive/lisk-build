node('lisk-explorer-01'){
  stage ('Prepare Workspace') {
    deleteDir()
    checkout scm
  }

  stage ('Shellcheck') {
    try {
      sh '''#!/bin/bash -xe
      # shellcheck
      shopt -s globstar; shellcheck **/*.sh
      '''
      deleteDir()
    } catch (err) {
      echo "Error: ${err}"
      error('Shellcheck validation failed')
    }
  }
}
