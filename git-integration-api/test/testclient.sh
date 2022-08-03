#!/bin/bash

#############################################################################################
# A local test client to call the API with API request data created by the post commit script
#############################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Parameters for local development
#
API_BASE_URL='http://localhost:3000'
BASIC_USER_NAME='idsvr'
BASIC_PASSWORD='idsvr-secret-1'

#
# Send the request content that the post commit script has copied to the configbackup folder
#
REQUEST_CONTENT_PATH='../../configbackup/example-request-content.json'
if [ ! -f "$REQUEST_CONTENT_PATH" ]; then
  echo 'No request content file exists for the HTTP request'
  exit
fi

#
# Send the request data to the API
#
REQUEST_CONTENT=$(cat $REQUEST_CONTENT_PATH)
curl -i -X POST http://localhost:3000/configuration/pull-requests \
-u "$BASIC_USER_NAME:$BASIC_PASSWORD" \
-H "accept: application/json" \
-H "content-type: application/json" \
-d "$REQUEST_CONTENT"
