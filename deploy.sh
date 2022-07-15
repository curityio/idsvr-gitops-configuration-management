#!/bin/bash

####################################################################################################
# Run an example deployment and demonstrate an automated way to manage Identity Server configuration
####################################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Point to the GitHub account containing the repo used to store configuration
#
GITHUB_USER_ACCOUNT_NAME='gary-archer'

#
# This example accepts a stage of the deployment pipeline as a parameter
#
STAGE="$1"
if [ "$STAGE" != 'DEV' -a "$STAGE" != 'STAGING' -a "$STAGE" != 'PRODUCTION' ]; then
  echo 'Please supply a valid stage name (DEV or STAGING or PRODUCTION) as a script argument'
  exit 1
fi
STAGE_LOWER=$(echo "$STAGE" | tr '[:upper:]' '[:lower:]')

#
# Check for a license file
#
if [ ! -f './idsvr/license.json' ]; then
  echo "Please provide a license.json file in the idsvr folder in order to deploy the system"
  exit 1
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
export IDSVR_BASE_URL
export WEB_BASE_URL
cd idsvr
docker compose --project-name curityconfig up
