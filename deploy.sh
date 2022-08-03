#!/bin/bash

#############################################################################################
# Run an example deployment that uses split parameterized configuration with environment data
# The deployment also runs post commit script when configuration changes in the Admin UI
#############################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Get the stage of the pipeline
#
if [ "$STAGE" != 'DEV' -a "$STAGE" != 'STAGING' -a "$STAGE" != 'PRODUCTION' ]; then
  echo 'Please supply a STAGE environment variable equal to DEV, STAGING or PRODUCTION'
  exit
fi
STAGE_LOWER=$(echo "$STAGE" | tr '[:upper:]' '[:lower:]')

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
# Read plaintext environment data
#
JSON=$(cat "./resources/$STAGE_LOWER/environment.json")
RUNTIME_BASE_URL=$(echo "$JSON" | jq -r .RUNTIME_BASE_URL)
DB_USERNAME=$(echo "$JSON" | jq -r .DB_USERNAME)
WEB_BASE_URL=$(echo "$JSON" | jq -r .WEB_BASE_URL)

#
# Read secure environment data, and escape $ characters in encrypted passwords as $$
#
JSON=$(cat "./vault/$STAGE_LOWER/secure.json")
ADMIN_PASSWORD=$(echo "$JSON" | jq -r .ADMIN_PASSWORD)
DB_CONNECTION=$(echo "$JSON" | jq -r .DB_CONNECTION)
DB_PASSWORD=$(echo "$JSON" | jq -r .DB_PASSWORD)
WEB_CLIENT_SECRET=$(echo "$JSON" | jq -r .WEB_CLIENT_SECRET)
SSL_KEY=$(echo "$JSON" | jq -r .SSL_KEY)
SIGNING_KEY=$(echo "$JSON" | jq -r .SIGNING_KEY)
VERIFICATION_KEY=$(echo "$JSON" | jq -r .VERIFICATION_KEY)
SYMMETRIC_KEY=$(echo "$JSON" | jq -r .SYMMETRIC_KEY)

#
# Create base environment variables
#
if [ -f .env ]; then
  rm .env
fi
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
# Add plaintext environment specific values
#
echo "RUNTIME_BASE_URL='$RUNTIME_BASE_URL'" >> .env
echo "DB_USERNAME='$DB_USERNAME'"           >> .env
echo "WEB_BASE_URL='$WEB_BASE_URL'"         >> .env

#
# Add secure environment variables
#
echo "ADMIN_PASSWORD='$ADMIN_PASSWORD'"       >> .env
echo "DB_CONNECTION='$DB_CONNECTION'"         >> .env
echo "DB_PASSWORD='$DB_PASSWORD'"             >> .env
echo "WEB_CLIENT_SECRET='$WEB_CLIENT_SECRET'" >> .env
echo "SSL_KEY='$SSL_KEY'"                     >> .env
echo "SIGNING_KEY='$SIGNING_KEY'"             >> .env
echo "VERIFICATION_KEY='$VERIFICATION_KEY'"   >> .env
echo "SYMMETRIC_KEY='$SYMMETRIC_KEY'"         >> .env

#
# Make a sanity check to ensure that secure environments data has been populated
#
if [ "$SSL_KEY" == '' ]; then
  echo 'Environment data must be populated before deploying the system'
fi

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
