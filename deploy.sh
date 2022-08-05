#!/bin/bash

#############################################################################################
# Run an example deployment that uses split parameterized configuration with environment data
# The deployment also runs post commit script when configuration changes in the Admin UI
#############################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Set variables depending on the stage of the pipeline
#
if [ "$STAGE" == 'DEV' ]; then

  STAGE_LOWER='dev'

elif [ "$STAGE" == 'STAGING' ]; then

  STAGE_LOWER='staging'

elif [ "$STAGE" == 'STAGING' ]; then

  STAGE_LOWER='production'

else

  echo 'Please supply a STAGE environment variable equal to DEV, STAGING or PRODUCTION'
  exit
fi

#
# Check for a license file
#
if [ ! -f "$LICENSE_FILE_PATH" ]; then
  echo 'Please supply a LICENSE_FILE_PATH environment variable pointing to a license.json file for the Curity Identity Server'
  exit
fi
LICENSE_KEY="$(cat $LICENSE_FILE_PATH | jq -r .License)"

#
# Download configuration to get the latest environment data
#
./downloadconfiguration.sh
if [ $? -ne 0 ]; then
  echo 'Problem encountered downloading environment data'
  exit
fi

#
# Get the config encryption key
#
ENCRYPTION_KEY_PATH="./vault/$STAGE_LOWER/configencryption.key"
if [ ! -f "$ENCRYPTION_KEY_PATH" ]; then
  echo "The $STAGE config encryption key was not found"
  exit
fi
CONFIG_ENCRYPTION_KEY=$(cat "$ENCRYPTION_KEY_PATH")

#
# Make a sanity check to ensure that secure environment data has been populated
#
SSL_KEY=$(cat "./vault/$STAGE_LOWER/secure.env" | grep SSL_KEY)
if [ "$SSL_KEY" == '' ]; then
  echo 'Environment data must be populated before deploying the system'
  exit
fi

#
# Get all environment specific variables into a file that Docker Compose will use
#
cat "./resources/$STAGE_LOWER.env" "./vault/$STAGE_LOWER/secure.env" > .env

#
# Add base environment variables
#
echo "ADMIN='true'"                                   >> .env
echo "LOGGING_LEVEL='INFO'"                           >> .env
echo "LICENSE_KEY='$LICENSE_KEY'"                     >> .env
echo "CONFIG_ENCRYPTION_KEY='$CONFIG_ENCRYPTION_KEY'" >> .env

#
# Add those specific to this example
#
echo "STAGE='$STAGE'"                         >> .env
echo "GIT_CONFIG_BACKUP='$GIT_CONFIG_BACKUP'" >> .env

#
# Make sure we have a configbackup folder, which the post commit script references
#
if [ ! -d ./configbackup ]; then
  mkdir configbackup
fi

#
# Avoid deploying the Git Integration API unless it is being used
#
if [ "$GIT_CONFIG_BACKUP" == 'true' ]; then
  PROFILE='GIT_CONFIG_BACKUP'
else
  PROFILE='BASIC_CONFIG_BACKUP'
fi

#
# Deploy the system
#
docker compose --project-name curityconfig --profile "$PROFILE" up
