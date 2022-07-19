#!/bin/bash

####################################################################################################
# Run an example deployment and demonstrate an automated way to manage Identity Server configuration
####################################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Check for a license file
#
LICENSE_KEY_FILE_PATH=~/.curity/license.json
if [ "$LICENSE_KEY_FILE_PATH" == '' ]; then
  echo 'Please provide a license.json file in the idsvr folder in order to deploy the system'
  exit
fi
LICENSE_KEY=$(cat "$LICENSE_KEY_FILE_PATH" | jq -r .License)
if [ "$LICENSE_KEY" == 'null' ]; then
  echo 'An invalid license JSON file was provided'
  exit
fi

#
# Point to the GitHub account containing the repo used to store configuration
#
if [ "$GITHUB_USER_ACCOUNT_NAME" == '' ]; then
  echo 'Please supply a GITHUB_USER_ACCOUNT_NAME environment variable that points to your online repository'
  exit
fi

#
# This example accepts a stage of the deployment pipeline as a parameter
#
if [ "$STAGE" != 'DEV' -a "$STAGE" != 'STAGING' -a "$STAGE" != 'PRODUCTION' ]; then
  echo 'Please supply a STAGE environment variable equal to DEV, STAGING or PRODUCTION'
  exit
fi
STAGE_LOWER=$(echo "$STAGE" | tr '[:upper:]' '[:lower:]')

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
# Make some sanity checks
#
ENVIRONMENT_FILE="./resources/$STAGE_LOWER.json"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
  echo 'Environment JSON file was not found in the downloaded data'
  exit
fi
if [ ! -f "./resources/parameterized-config-backup.xml" ]; then
  echo 'Identity Server configuration was not found in the downloaded data'
  exit
fi

#
# Read environment specific values
#
JSON=$(cat "$ENVIRONMENT_FILE")
IDSVR_BASE_URL=$(echo "$JSON" | jq -r .IDSVR_BASE_URL)
WEB_BASE_URL=$(echo "$JSON" | jq -r .WEB_BASE_URL)

#
# Export the variables to Docker Compose and deploy the system
#
export STAGE
export LICENSE_KEY
export IDSVR_BASE_URL
export WEB_BASE_URL
cd idsvr
docker compose --project-name curityconfig up
