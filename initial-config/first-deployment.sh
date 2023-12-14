#!/bin/bash

######################################################
# Run the initial configuration with an encryption key
######################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Generate a config encryption key and simulate storing it in a secure location
#
VAULT_FOLDER='../vault/dev'
if [ ! -d "$VAULT_FOLDER" ]; then
  mkdir -p "$VAULT_FOLDER"
fi
KEY="$(openssl rand 32 | xxd -p -c 64)"
echo "$KEY" > "$VAULT_FOLDER/configencryption.key"

#
# Do the deployment, including the PASSWORD environment variable, so that there is an auto-configuration
# This will ensure that the system is in an initial working state
# You can then login to the Admin UI at https://localhost:6749/admin and complete the initial setup, then export the configuration
#
docker run -it -p 6749:6749 -p 8443:8443 \
-e PASSWORD='Password1' \
-e CONFIG_ENCRYPTION_KEY="$KEY" \
curity.azurecr.io/curity/idsvr:latest
