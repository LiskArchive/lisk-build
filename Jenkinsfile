def fail(reason) {
  def pr_branch = ''
  if (env.CHANGE_BRANCH != null) {
    pr_branch = " (${env.CHANGE_BRANCH})"
  }
  error("${reason}")
}

node('lisk-explorer-01'){
  try {
    stage ('Prepare Workspace') {
      deleteDir()
      checkout scm
    }

    stage ('Shellcheck') {
      try {
        sh '''#!/bin/bash
        # shellcheck
        shopt -s globstar; /opt/shellcheck/shellcheck **/*.sh
        '''
      } catch (err) {
        echo "Error: ${err}"
        fail('Stopping build, installation failed')
      }
    }
  } catch(err) {
    echo "Error: ${err}"
  } finally {
    def pr_branch = ''
    if (env.CHANGE_BRANCH != null) {
      pr_branch = " (${env.CHANGE_BRANCH})"
    }
    if (currentBuild.result == 'SUCCESS') {
      /* delete all files on success */
      deleteDir()
      /* notify of success if previous build failed */
      previous_build = currentBuild.getPreviousBuild()
    }
  }
}
