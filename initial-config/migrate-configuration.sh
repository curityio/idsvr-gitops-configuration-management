#!/bin/bash

###############################################################################################
# Migrate the backed up XML configuration to plaintext environment variables and a secure vault
###############################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Point to files
#
SOURCE_FILE=./initial-config-backup.xml
TARGET_FILE_PLAINTEXT=../git-repo/dev.env
TARGET_FILE_SECURE=../vault/dev/secure.env

#
# Check that there is a configuration backup file
#
if [ ! -f "$SOURCE_FILE" ]; then
  echo 'The initial configuration backup does not exist'
  exit
fi

#
# Check that tools are installed
#
xml --version 1>/dev/null
if [ $? -ne 0 ]; then
  echo 'Problem encountered, please ensure that the xmlstarlet tool is installed'
  exit 1
fi

#
# Read plaintext fields to parameterize from the initial backed up configuration using an XML tool
#
RUNTIME_BASE_URL=$(xml sel -N x='http://tail-f.com/ns/config/1.0' -N b='https://curity.se/ns/conf/base' \
  -t -v "/x:config/b:environments/b:environment/b:base-url" "$SOURCE_FILE")
if [ "$RUNTIME_BASE_URL" == '' ]; then
  RUNTIME_BASE_URL='http://localhost:8443'
fi

DB_USERNAME=$(xml sel -N x='http://tail-f.com/ns/config/1.0' -N b='https://curity.se/ns/conf/base' -N 'j=https://curity.se/ns/ext-conf/jdbc' \
  -t -v "/x:config/b:facilities/b:data-sources/b:data-source[b:id='default-datasource']/j:jdbc/j:username" "$SOURCE_FILE")

WEB_BASE_URL=$(xml sel -N x='http://tail-f.com/ns/config/1.0' -N b='https://curity.se/ns/conf/base' -N o='https://curity.se/ns/conf/profile/oauth' \
  -t -v "/x:config/b:profiles/b:profile[b:id='token-service']/b:settings/o:authorization-server/o:client-store/o:config-backed/o:client[o:id='web-client']/o:redirect-uris" "$SOURCE_FILE")

#
# Save them to plaintext environment data
#
> "$TARGET_FILE_PLAINTEXT"
echo "RUNTIME_BASE_URL='$RUNTIME_BASE_URL'" >> "$TARGET_FILE_PLAINTEXT"
echo "DB_USERNAME='$DB_USERNAME'"           >> "$TARGET_FILE_PLAINTEXT"
echo "WEB_BASE_URL='$WEB_BASE_URL'"         >> "$TARGET_FILE_PLAINTEXT"

#
# Read encrypted fields
#
ADMIN_PASSWORD=$(xml sel -N x='http://tail-f.com/ns/config/1.0' -N b='http://tail-f.com/ns/aaa/1.1' \
  -t -v "/x:config/b:aaa/b:authentication/b:users/b:user[b:name='admin']/b:password" "$SOURCE_FILE")

DB_CONNECTION=$(xml sel -N x='http://tail-f.com/ns/config/1.0' -N b='https://curity.se/ns/conf/base' -N 'j=https://curity.se/ns/ext-conf/jdbc' \
  -t -v "/x:config/b:facilities/b:data-sources/b:data-source[b:id='default-datasource']/j:jdbc/j:connection-string" "$SOURCE_FILE")

DB_PASSWORD=$(xml sel -N x='http://tail-f.com/ns/config/1.0' -N b='https://curity.se/ns/conf/base' -N 'j=https://curity.se/ns/ext-conf/jdbc' \
  -t -v "/x:config/b:facilities/b:data-sources/b:data-source[b:id='default-datasource']/j:jdbc/j:password" "$SOURCE_FILE")

WEB_CLIENT_SECRET=$(xml sel -N x='http://tail-f.com/ns/config/1.0' -N b='https://curity.se/ns/conf/base' -N o='https://curity.se/ns/conf/profile/oauth' \
  -t -v "/x:config/b:profiles/b:profile[b:id='token-service']/b:settings/o:authorization-server/o:client-store/o:config-backed/o:client[o:id='web-client']/o:secret" "$SOURCE_FILE")

SYMMETRIC_KEY=$(xml sel -N x='http://tail-f.com/ns/config/1.0' -N b='https://curity.se/ns/conf/base' \
  -t -v "/x:config/b:environments/b:environment/b:services/b:zones/b:default-zone/b:symmetric-key" "$SOURCE_FILE")

SSL_KEY=$(xml sel -N x='http://tail-f.com/ns/config/1.0' -N b='https://curity.se/ns/conf/base' \
  -t -v "/x:config/b:facilities/b:crypto/b:ssl/b:server-keystore[b:id='default-admin-ssl-key']/b:keystore" "$SOURCE_FILE")

SIGNING_KEY=$(xml sel -N x='http://tail-f.com/ns/config/1.0' -N b='https://curity.se/ns/conf/base' \
  -t -v "/x:config/b:facilities/b:crypto/b:signing-keys/b:signing-key[b:id='default-signing-key']/b:keystore" "$SOURCE_FILE")

VERIFICATION_KEY=$(xml sel -N x='http://tail-f.com/ns/config/1.0' -N b='https://curity.se/ns/conf/base' \
  -t -v "/x:config/b:facilities/b:crypto/b:signature-verification-keys/b:signature-verification-key[b:id='default-signature-verification-key']/b:keystore" "$SOURCE_FILE")

#
# Save them to encrypted environment data
#
> "$TARGET_FILE_SECURE"
echo "ADMIN_PASSWORD='$ADMIN_PASSWORD'"       >> "$TARGET_FILE_SECURE"
echo "DB_CONNECTION='$DB_CONNECTION'"         >> "$TARGET_FILE_SECURE"
echo "DB_PASSWORD='$DB_PASSWORD'"             >> "$TARGET_FILE_SECURE"
echo "WEB_CLIENT_SECRET='$WEB_CLIENT_SECRET'" >> "$TARGET_FILE_SECURE"
echo "SYMMETRIC_KEY='$SYMMETRIC_KEY'"         >> "$TARGET_FILE_SECURE"
echo "SSL_KEY='$SSL_KEY'"                     >> "$TARGET_FILE_SECURE"
echo "SIGNING_KEY='$SIGNING_KEY'"             >> "$TARGET_FILE_SECURE"
echo "VERIFICATION_KEY='$VERIFICATION_KEY'"   >> "$TARGET_FILE_SECURE"
