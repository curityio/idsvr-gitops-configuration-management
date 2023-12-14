#!/bin/bash

################################################
# Build custom Docker containers ready to deploy
################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Download the latest parameterized configuration, which will be used to build the custom Docker image
#
./downloadconfiguration.sh
if [ $? -ne 0 ]; then
  echo 'Problem encountered downloading configuration'
  exit
fi

#
# Build the Curity Identity Server's custom Docker image
#
docker build -f idsvr/Dockerfile -t custom_idsvr:latest .
if [ $? -ne 0 ]; then
  echo 'Problem encountered building the Identity Server docker image'
  exit
fi

#
# In the advanced configuration, also build the utility API used to create an automated pull request when configuration changes
#
if [ "$GIT_CONFIG_BACKUP" == 'true' ]; then

  cd git-integration-api
  ./gradlew bootJar
  if [ $? -ne 0 ]; then
    echo 'Problem encountered building the Git Integration API code'
    exit
  fi

  docker build -t git-integration-api:1.0.0 .
  if [ $? -ne 0 ]; then
    echo 'Problem encountered building the Git Integration API docker image'
    exit
  fi
fi