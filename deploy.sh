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
# This example accepts a stage of the deployment pipeline as a parameter
#
if [ "$STAGE" != 'DEV' -a "$STAGE" != 'STAGING' -a "$STAGE" != 'PRODUCTION' ]; then
  echo 'Please supply a STAGE environment variable equal to DEV, STAGING or PRODUCTION'
  exit
fi
STAGE_LOWER=$(echo "$STAGE" | tr '[:upper:]' '[:lower:]')

#
# Make some sanity checks
#
ENVIRONMENT_FILE="./resources/environments/$STAGE_LOWER.json"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
  echo "The environment file at $ENVIRONMENT_FILE was not found"
  exit
fi

#
# Get environment specific values
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
docker compose --project-name curityconfig up
