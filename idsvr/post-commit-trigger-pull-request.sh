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
  # Use the identity server CLI to get the last commit details, in the form "# Comment: my commit message"
  # Then use regex groups to get the actual commit message
  #
  COMMENT_LINE=$(idsh <<< "show commit changes" | grep "# Comment: ")
  COMMIT_MESSAGE=$(echo "$COMMENT_LINE" | sed -r "s/^# Comment: (.*)$/\1/i")

  #
  # Export the configuration as XML, with the -D parameter to preserve environment variables
  #
  CONFIG_ENVIRONMENTS_XML=$(idsvr -D environments)
  CONFIG_FACILITIES_XML=$(idsvr -D facilities)
  CONFIG_PROFILES_XML=$(idsvr -D profiles)
  CONFIG_NACM_XML=$(idsvr -D nacm)
  CONFIG_AAA_XML=$(idsvr -D aaa)

  #
  # Translate to base 64 for including in a JSON payload
  #
  CONFIG_ENVIRONMENTS_BASE64=$(echo "$CONFIG_ENVIRONMENTS_XML" | base64 -w 0)
  CONFIG_FACILITIES_BASE64=$(echo "$CONFIG_FACILITIES_XML" | base64 -w 0)
  CONFIG_PROFILES_BASE64=$(echo "$CONFIG_PROFILES_XML" | base64 -w 0)
  CONFIG_NACM_BASE64=$(echo "$CONFIG_NACM_XML" | base64 -w 0)
  CONFIG_AAA_BASE64=$(echo "$CONFIG_AAA_XML" | base64 -w 0)

  #
  # Form a JSON payload with the stage of the deployment pipeline, the commit message, and the data in parts
  #
  REQUEST_CONTENT="{\"stage\": \"$STAGE\", \"message\": \"$COMMIT_MESSAGE\", \"environments\": \"$CONFIG_ENVIRONMENTS_BASE64\", \"facilities\": \"$CONFIG_FACILITIES_BASE64\", \"profiles\": \"$CONFIG_PROFILES_BASE64\", \"nacm\": \"$CONFIG_NACM_BASE64\", \"aaa\": \"$CONFIG_AAA_BASE64\"}"
  
  #
  # Store a copy of the request payload for development debugging
  #
  echo "$REQUEST_CONTENT" > /tmp/example-request-content.json

  #
  # Define details for connecting to the utility API that will create the Git pull request
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
