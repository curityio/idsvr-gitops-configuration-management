#!/bin/bash

####################################################################################
# Get the latest environment specific data so that it can be used at deployment time
####################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Clean existing local data
#
if [ -d ./resources/ ]; then
  rm -rf resources
fi

if [ "$GIT_CONFIG_BACKUP" == 'true' ]; then

  #
  # Download from a Git repo, and a real world deployment might get the configuration for a particular Git label
  #
  if [ "$GITHUB_USER_ACCOUNT_NAME" == '' ]; then
    echo 'Please supply a GITHUB_USER_ACCOUNT_NAME environment variable that points to your online repository'
    exit 1
  fi
  git clone "https://github.com/$GITHUB_USER_ACCOUNT_NAME/idsvr-configuration-store" resources
  if [ $? -ne 0 ]; then
    echo 'Problem encountered downloading the GitOps configuration'
    exit 1
  fi
else

  #
  # Otherwise just copy over the local configuration
  #
  cp -R ./git-repo resources
fi
