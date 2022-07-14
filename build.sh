#!/bin/bash

################################################
# Build custom Docker containers ready to deploy
################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# For demo purposes, deploy the Identity Server using the curl tool
#
docker build -f idsvr/Dockerfile -t custom_idsvr:7.2.0 .
if [ $? -ne 0 ]; then
  echo 'Problem encountered building the Identity Server docker image'
  exit
fi

#
# Deploy the utility API used to create a GitHub pull request
#
docker build -f git-integration-api/Dockerfile -t git-integration-api:1.0.0 .
if [ $? -ne 0 ]; then
  echo 'Problem encountered building the Git Integration API docker image'
  exit
fi
