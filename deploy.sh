#!/bin/bash

####################################################################################################
# Run an example deployment and demonstrate an automated way to manage Identity Server configuration
####################################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Supply environment variables during deployment
#
STAGE='$1'
if [ "$STAGE" == 'DEV' ]; then
  
  # The development environment
  IDSVR_BASE_URL='https://login.example-dev.com'
  WEB_BASE_URL='https://www.example-dev.com'

elif [ "$STAGE" == 'STAGING' ]; then
  
  # The staging environment
  IDSVR_BASE_URL='https://login.example-staging.com'
  WEB_BASE_URL='https://www.example-staging.com'

else

  # The production environment
  STAGE = 'PRODUCTION'
  IDSVR_BASE_URL='https://login.example.com'
  WEB_BASE_URL='https://www.example.com'
fi

#
# Download the configuration for the environment
# This example uses a single configuration file with parameterized values
# An alternative option is to use a different configuration file per stage
#
STAGE_CONFIG_DOWNLOAD_URL="file:///$(pwd)/git-config-repo/parameterized-config-backup.xml"
curl -s "$STAGE_CONFIG_DOWNLOAD_URL" > ./idsvr/stage-configuration.xml

#
# Export the variables to Docker Compose and deploy the system
#
export STAGE
export IDSVR_BASE_URL
export WEB_BASE_URL
docker compose --file idsvr/docker-compose.yml --project-name curityconfig up
