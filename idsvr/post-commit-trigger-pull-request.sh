#!/bin/bash

###########################################################################################
# Runs on the Admin node of the Curity Identity Server when there is a configuration change
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
  # Export the configuration in two formats, where -D contains parameters and -d returns values
  #
  PARAMS_XML="$(idsvr -D)"
  VALUES_XML="$(idsvr -d)"

  #
  # Copy data to the backup volume
  #
  echo "$COMMIT_MESSAGE" > /mnt/configbackup/commit_message.txt
  echo "$PARAMS_XML" > /mnt/configbackup/config_params.xml
  echo "$VALUES_XML" > /mnt/configbackup/config_values.xml

  #
  # If configured, also initiate a pull request to Git
  #
  if [ "$GIT_CONFIG_BACKUP" == 'true' ]; then

    #
    # Form a JSON payload with the stage of the deployment pipeline, the commit message, and the data
    #
    PARAMS_BASE64="$(echo "$PARAMS_XML" | base64 -w 0)"
    VALUES_BASE64="$(echo "$VALUES_XML" | base64 -w 0)"
    REQUEST_CONTENT="{\"stage\": \"$STAGE\", \"message\": \"$COMMIT_MESSAGE\", \"params\": \"$PARAMS_BASE64\", \"values\": \"$VALUES_BASE64\"}"
  
    #
    # Store a copy of the request payload, for development debugging
    #
    echo "$REQUEST_CONTENT" > /mnt/configbackup/example-request-content.json

    #
    # Get details for connecting to the utility API that will create the Git pull request
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
  fi
fi
