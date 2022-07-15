#!/bin/bash

##################################
# Run the API with the latest code
##################################

cd "$(dirname "${BASH_SOURCE[0]}")"
./gradlew build
java -jar build/libs/api-0.0.1-SNAPSHOT-all.jar
