#!/bin/bash

####################################################################################################
# Run an example deployment and demonstrate an automated way to manage Identity Server configuration
####################################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# This example accepts a stage of the deployment pipeline as a parametr
#
STAGE="$1"
if [ "$STAGE" != 'DEV' -a "$STAGE" != 'STAGING' -a "$STAGE" != 'PRODUCTION' ]; then
  echo 'Please supply a valid stage name (DEV or STAGING or PRODUCTION) as a parameter, eg "deploy.sh STAGING"'
  exit 1
fi

#
# Set environment variables for this stage
#
if [ "$STAGE" == 'DEV' ]; then
  
  # The development environment
  IDSVR_BASE_URL='https://login.example-dev.com'
  WEB_BASE_URL='https://www.example-dev.com'

elif [ "$STAGE" == 'STAGING' ]; then
  
  # The staging environment
  IDSVR_BASE_URL='https://login.example-staging.com'
  WEB_BASE_URL='https://www.example-staging.com'

elif [ "$STAGE" == 'PRODUCTION' ]; then

  # The production environment
  STAGE='PRODUCTION'
  IDSVR_BASE_URL='https://login.example.com'
  WEB_BASE_URL='https://www.example.com'

fi

#
# Download the configuration for the environment
#
STAGE_LOWER=$(echo "$STAGE" | tr '[:upper:]' '[:lower:]')
STAGE_CONFIG_DOWNLOAD_URL="file:///$(pwd)/resources/stored-configuration/$STAGE_LOWER/parameterized-config-backup.xml"
curl -s "$STAGE_CONFIG_DOWNLOAD_URL" > ./idsvr/stage-configuration.xml

#
# Export the variables to Docker Compose and deploy the system
#
export STAGE
export IDSVR_BASE_URL
export WEB_BASE_URL
cd idsvr
docker compose --project-name curityconfig up
