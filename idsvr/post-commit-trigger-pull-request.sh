#!/bin/bash

###########################################################################################
# Runs on the Admin node of the Curity Identity Server when there is a configuration change
# This invokes a utility API with the latest configuration, transaction ID and comment
# The utility API then uses Git APIs to add a pull request
###########################################################################################

#
# Ensure that we are running from the /opt/idsvr/usr/bin/post-commit-scripts folder
#
cd "$(dirname "${BASH_SOURCE[0]}")"

#
# First read status details, to avoid GIT configuration updates when the node is initializing configuration
#
STATUS=$(/opt/idsvr/bin/status)
IS_READY=$(echo "$STATUS" | grep 'isReady' | awk -F':' '/isReady/ {print $2}')
IS_SERVING=$(echo "$STATUS" | grep 'isServing' | awk -F':' '/isServing/ {print $2}')
CONFIGURATION_STATE=$(echo "$STATUS" | grep 'configurationState' | awk -F':' '/configurationState/ {print $2}')
NODE_STATE=$(echo "$STATUS" | grep 'nodeState' | awk -F':' '/nodeState/ {print $2}')

#
# If these conditions are true then there has been a configuration change
#
if [ "$IS_READY" == 'true' -a "$IS_SERVING" == 'true' -a "$NODE_STATE" == 'RUNNING' -a "$CONFIGURATION_STATE" == 'CONFIGURED' ]; then
  
  #
  # Get details of the last commit
  #
  TRANSACTION_ID=$(echo "$STATUS" | grep 'transactionId' | awk -F':' '/transactionId/ {print $2}')
  COMMIT_MESSAGE='my commit'

  #
  # Get the configuration as base64 and form a JSON payload
  #
  CONFIG_BACKUP_XML=$(idsvr -d | sed  '/<cluster>/,/<\/cluster>/d' | base64 -w 0)
  REQUEST_CONTENT="[{\"id\": \"$TRANSACTION_ID\", \"message\": \"$COMMIT_MESSAGE\", \"data\": \"$CONFIG_BACKUP_XML\"}]"
  echo "$REQUEST_CONTENT" > /tmp/pull-request-content.txt

  #
  # Details for connecting to the utility API that will create the Git pull request
  #
  BASIC_USER_NAME='idsvr'
  BASIC_PASSWORD='idsvr-secret-1'
  API_BASE_URL='http://api-internal:3000'

  #
  # Use the curl tool to call the utility API to initiate the update to the Git repository
  #
  curl -i -X POST "$API_BASE_URL/configuration/pull-requests" \
  -u "$BASIC_USER_NAME:$BASIC_PASSWORD" \
  -H "accept: application/json" \
  -H "content-type: application/json" \
  -d "$REQUEST_CONTENT"

  #
  # In a production setup, use the openssl tool to send the request over an SSL connection
  #
#  openssl 2>&1 s_client -CAfile $CA_CERT -quiet -connect api-internal:7443 <<EOF
#POST /configuration/pull-requests HTTP/1.1
#Host: api-internal
#Authorization: Basic "$BASIC_USER_NAME:BASIC_PASSWORD"
#Connection: close
#Content-Type: application/json
#Content-length: ${#REQUEST_CONTENT}
#Accept: application/json
#
#$REQUEST_CONTENT
#EOF
fi
