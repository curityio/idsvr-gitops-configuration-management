#!/bin/bash

################################################
# Build custom Docker containers ready to deploy
################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Point to the GitHub account containing the repo used to store configuration
#
if [ "$GITHUB_USER_ACCOUNT_NAME" == '' ]; then
  echo 'Please supply a GITHUB_USER_ACCOUNT_NAME environment variable that points to your online repository'
  exit
fi

#
# Download configuration at deployment time from the GitOps configuration repository
#
if [ -d ./resources/ ]; then
  rm -rf resources
fi
git clone "https://github.com/$GITHUB_USER_ACCOUNT_NAME/idsvr-configuration-store" resources
if [ $? -ne 0 ]; then
  echo 'Problem encountered downloading the GitOps configuration'
  exit
fi

#
# TODO: delete after merge
#
cd resources
git checkout dev
cd ..

#
# Build the Curity Identity Server's custom Docker image
#
docker build -f idsvr/Dockerfile -t custom_idsvr:7.2.0 .
if [ $? -ne 0 ]; then
  echo 'Problem encountered building the Identity Server docker image'
  exit
fi

#
# Build the utility API
#
cd git-integration-api
./gradlew bootJar
if [ $? -ne 0 ]; then
  echo 'Problem encountered building the Git Integration API code'
  exit
fi
cd ..

#
# Deploy the utility API used to create a GitHub pull request
#
docker build -f git-integration-api/Dockerfile -t git-integration-api:1.0.0 .
if [ $? -ne 0 ]; then
  echo 'Problem encountered building the Git Integration API docker image'
  exit
fi
