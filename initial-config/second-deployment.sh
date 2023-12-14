#!/bin/bash

###########################################################################
# Run a deployment using saved configuration, and without autoconfiguration
###########################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Check that there is a configuration backup file
#
if [ ! -f './initial-config-backup.xml' ]; then
  echo 'The initial-config-backup.xml file does not exist'
  exit
fi

#
# Load the config encryption key
#
CONFIG_ENCRYPTION_KEY_PATH='../vault/dev/configencryption.key'
if [ ! -f "$CONFIG_ENCRYPTION_KEY_PATH" ]; then
  echo 'The config encryption key does not exist'
  exit
fi
KEY=$(cat "$CONFIG_ENCRYPTION_KEY_PATH")

#
# Re-run the deployment, which can decrypt secure values from its configuration
#
docker run -it -p 6749:6749 -p 8443:8443 \
-e CONFIG_ENCRYPTION_KEY="$KEY" \
-e ADMIN='true' \
-v "$(pwd)/initial-config-backup.xml":/opt/idsvr/etc/init/config.xml \
curity.azurecr.io/curity/idsvr:latest
