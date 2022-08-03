#!/bin/bash

################################################################################
# Creates development crypto keys, used with the convertks and reenc tools later
################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"
set -e

#
# Check that environment variables are set
#
if [ "$STAGE" != 'DEV' -a "$STAGE" != 'STAGING' -a "$STAGE" != 'PRODUCTION' ]; then
  echo 'Please supply a STAGE environment variable equal to DEV, STAGING or PRODUCTION'
  exit
fi
STAGE_LOWER=$(echo "$STAGE" | tr '[:upper:]' '[:lower:]')

#
# Move to the folder that will contain keys, and create it if required
#
VAULT_FOLDER="./$STAGE_LOWER"
if [ ! -d "$VAULT_FOLDER" ]; then
  mkdir -p "$VAULT_FOLDER"
fi
cd "$VAULT_FOLDER"

#
# Generate a config encryption key if one does not exist already
#
if [ ! -f './configencryption.key' ]; then
  openssl rand 32 | xxd -p -c 64 > configencryption.key
fi

#
# Generate a symmetric key, for purposes such as signing SSO cookies
#
openssl rand 32 | xxd -p -c 64 > symmetric.key

#
# For development, create self signed PKCS#12 files to simulate those provided from a trusted issuer
#
openssl genrsa -out ssl.key 2048
openssl req -new -nodes -key ssl.key -out ssl.csr -subj "/CN=localhost"
openssl x509 -req -in ssl.csr -signkey ssl.key -out ssl.crt -sha256 -days 365 -extfile ../ssl.ext 
openssl pkcs12 -export -inkey ssl.key -in ssl.crt -name curity.ssl -out ssl.p12 -passout pass:Password1
rm ssl.csr

openssl genrsa -out signing.key 2048
openssl req -new -nodes -key signing.key -out signing.csr -subj "/CN=curity.signing"
openssl x509 -req -in signing.csr -signkey signing.key -out signing.crt -sha256 -days 365
openssl pkcs12 -export -inkey signing.key -in signing.crt -name curity.signing -out signing.p12 -passout pass:Password1
rm signing.csr