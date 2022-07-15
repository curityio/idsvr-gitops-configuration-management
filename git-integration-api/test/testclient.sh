#!/bin/bash

##########################################################################################
# A local test client to call the API with the configuration data from the Identity Server
##########################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Parameters for local development
#
API_BASE_URL='http://localhost:3000'
BASIC_USER_NAME='idsvr'
BASIC_PASSWORD='idsvr-secret-1'

#
# Send the request content
#
REQUEST_CONTENT=$(cat ./request_content.json)
curl -i -X POST http://localhost:3000/configuration/pull-requests \
-u "$BASIC_USER_NAME:$BASIC_PASSWORD" \
-H "accept: application/json" \
-H "content-type: application/json" \
-d "$REQUEST_CONTENT"
