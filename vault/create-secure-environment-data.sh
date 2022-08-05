#!/bin/bash

##############################################################################################################
# Demonstrates how to set secure environment variables in a deployment system, starting with the secret values
##############################################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Set variables depending on the stage of the pipeline
#
if [ "$STAGE" == 'DEV' ]; then

  STAGE_LOWER='dev'

elif [ "$STAGE" == 'STAGING' ]; then

  STAGE_LOWER='staging'

elif [ "$STAGE" == 'STAGING' ]; then

  STAGE_LOWER='production'

else

  echo 'Please supply a STAGE environment variable equal to DEV, STAGING or PRODUCTION'
  exit
fi

#
# Check we have a path to the identity server
#
if [ "$IDSVR_HOME" == '' ]; then
  echo "The IDSVR_HOME environment variable has not been configured"
  exit
fi

#
# Check that we have generated secrets previously
#
if [ ! -f "./$STAGE_LOWER/ssl.p12" ]; then
  echo "Please run './create-development-keys.sh $STAGE' before running this script"
  exit
fi

#
# Get the config encryption key for this stage of the pipeline
#
CONFIG_ENCRYPTION_KEY_PATH="./$STAGE_LOWER/configencryption.key"
if [ ! -f "$CONFIG_ENCRYPTION_KEY_PATH" ]; then
  echo 'The config encryption key does not exist'
  exit
fi
CONFIG_ENCRYPTION_KEY=$(cat "$CONFIG_ENCRYPTION_KEY_PATH")

#
# Ensure that a path to the identity server exists
#
if [ ! -d "$IDSVR_HOME" ]; then
  echo 'Please provide the IDSVR_HOME environment variable'
  exit
fi

#
# Read keys and convert P12 files to the configuration XML format using the convertks tool
#
cd "./$STAGE_LOWER"
SSL_BASE64="$(openssl base64 -in ssl.p12 | tr -d '\n')"
SSL_KEY=$("$IDSVR_HOME/bin/convertks" --in-password Password1 --in-alias curity.ssl --in-entry-password Password1 --in-keystore "$SSL_BASE64")
SIGNING_BASE64="$(openssl base64 -in signing.p12 | tr -d '\n')"
SIGNING_KEY=$("$IDSVR_HOME/bin/convertks" --in-password Password1 --in-alias curity.signing --in-entry-password Password1 --in-keystore "$SIGNING_BASE64")
VERIFICATION_KEY=$(openssl base64 -in signing.crt | tr -d '\n')
SYMMETRIC_KEY=$(cat symmetric.key)
cd ..

#
# Use openssl to get secure hashes for these values
#
ADMIN_PASSWORD='Password1'
ADMIN_PASSWORD_ENCRYPTED=$(openssl passwd -5 "$ADMIN_PASSWORD")

WEB_CLIENT_SECRET='Password1'
WEB_CLIENT_SECRET_ENCRYPTED=$(openssl passwd -5 "$WEB_CLIENT_SECRET")

#
# Protect each secure value using the utility script
#
DB_CONNECTION='jdbc:hsqldb:file:${se.curity:identity-server:db};ifexists=true;hsqldb.lock_file=false'
export TYPE='plaintext'
export PLAINTEXT="$DB_CONNECTION"
export ENCRYPTIONKEY="$CONFIG_ENCRYPTION_KEY"
DB_CONNECTION_ENCRYPTED=$(./crypto/encrypt_util.sh)
if [ $? -ne 0 ]; then
  echo "Encryption problem encountered for DB_CONNECTION: $DB_CONNECTION_ENCRYPTED"
  exit
fi

DB_PASSWORD=''
export TYPE='plaintext'
export PLAINTEXT="$DB_PASSWORD"
export ENCRYPTIONKEY="$CONFIG_ENCRYPTION_KEY"
DB_PASSWORD_ENCRYPTED=$(./crypto/encrypt_util.sh)
if [ $? -ne 0 ]; then
  echo "Encryption problem encountered for DB_PASSWORD: $DB_PASSWORD_ENCRYPTED"
  exit
fi

export TYPE='plaintext'
export PLAINTEXT="$SYMMETRIC_KEY"
export ENCRYPTIONKEY="$CONFIG_ENCRYPTION_KEY"
SYMMETRIC_KEY_ENCRYPTED=$(./crypto/encrypt_util.sh)
if [ $? -ne 0 ]; then
  echo "Encryption problem encountered for SYMMETRIC_KEY: $SYMMETRIC_KEY_ENCRYPTED"
  exit
fi

export TYPE='base64keystore'
export PLAINTEXT="$SSL_KEY"
export ENCRYPTIONKEY="$CONFIG_ENCRYPTION_KEY"
SSL_KEY_ENCRYPTED=$(./crypto/encrypt_util.sh)
if [ $? -ne 0 ]; then
  echo "Encryption problem encountered for SSL_KEY: $SSL_KEY_ENCRYPTED"
  exit
fi

export TYPE='base64keystore'
export PLAINTEXT="$SIGNING_KEY"
export ENCRYPTIONKEY="$CONFIG_ENCRYPTION_KEY"
SIGNING_KEY_ENCRYPTED=$(./crypto/encrypt_util.sh)
if [ $? -ne 0 ]; then
  echo "Encryption problem encountered for SIGNING_KEY: $SIGNING_KEY_ENCRYPTED"
  exit
fi

export TYPE='base64keystore'
export PLAINTEXT="$VERIFICATION_KEY"
export ENCRYPTIONKEY="$CONFIG_ENCRYPTION_KEY"
VERIFICATION_KEY_ENCRYPTED=$(./crypto/encrypt_util.sh)
if [ $? -ne 0 ]; then
  echo "Encryption problem encountered for VERIFICATION_KEY: $VERIFICATION_KEY_ENCRYPTED"
  exit
fi

#
# Update the stage specific environment file with secure environment specific values
#
cd "../vault/$STAGE_LOWER"
> secure.env
echo "ADMIN_PASSWORD='$ADMIN_PASSWORD_ENCRYPTED'"       >> secure.env
echo "DB_CONNECTION='$DB_CONNECTION_ENCRYPTED'"         >> secure.env
echo "DB_PASSWORD='$DB_PASSWORD_ENCRYPTED'"             >> secure.env
echo "WEB_CLIENT_SECRET='$WEB_CLIENT_SECRET_ENCRYPTED'" >> secure.env
echo "SYMMETRIC_KEY='$SYMMETRIC_KEY_ENCRYPTED'"         >> secure.env
echo "SSL_KEY='$SSL_KEY_ENCRYPTED'"                     >> secure.env
echo "SIGNING_KEY='$SIGNING_KEY_ENCRYPTED'"             >> secure.env
echo "VERIFICATION_KEY='$VERIFICATION_KEY_ENCRYPTED'"   >> secure.env
