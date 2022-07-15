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
# First read status details, to avoid sending GIT pull requests when the node is starting up
#
STATUS=$(/opt/idsvr/bin/status)
IS_READY=$(echo "$STATUS" | grep 'isReady' | awk -F':' '/isReady/ {print $2}')
IS_SERVING=$(echo "$STATUS" | grep 'isServing' | awk -F':' '/isServing/ {print $2}')

#
# If these conditions are true then there has been a configuration change
#
if [ "$IS_READY" == 'true' -a "$IS_SERVING" == 'true' ]; then
  
  #
  # Get details of the last commit, which will be a value of the form # Comment: my commit message"
  # USe regex groups to get the message part
  #
  COMMENT_LINE=$(idsh <<< "show commit changes" | grep "# Comment: ")
  COMMIT_MESSAGE=$(echo "$COMMENT_LINE" | sed -r "s/^# Comment: (.*)$/\1/i")
  echo $COMMIT_MESSAGE

  #
  # Get the configuration with the -D parameter to preserve environment variables
  #
  CONFIG_BACKUP_XML=$(idsvr -D | sed  '/<cluster>/,/<\/cluster>/d' | base64 -w 0)

  #
  # Form a JSON payload
  #
  REQUEST_CONTENT="{\"id\": \"$TRANSACTION_ID\", \"message\": \"$COMMIT_MESSAGE\", \"data\": \"$CONFIG_BACKUP_XML\"}"
  
  #
  # TODO - save this to API folder then remove the code
  #
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
  # In a production setup, openssl can send the request over an SSL connection, and Mutual TLS can be used
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
