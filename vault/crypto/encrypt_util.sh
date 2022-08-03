#!/bin/bash

####################################################################################################
# Implements xalan encryption to get a protected environment variable for the Curity Identity Server
####################################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Usage of this helper module
#
function usage_message() {
  echo "Usage: './encrypt_util.sh type plaintextdata encryptionkey', where type is 'plain', 'p12' or 'pem'"
}

#
# Uses an encryptor that takes plaintext and produces data:text/plain encrypted output
#
function encrypt_plaintext() {

	CLASSPATH="$IDSVR_HOME/lib/*"
	XML_FILE=$(mktemp)
	XSLT_FILE=$(mktemp)
	trap 'rm -f "$XML_FILE $XSLT_FILE"' EXIT

	cat <<'EOF' > $XSLT_FILE
<stylesheet version="1.0" xmlns="http://www.w3.org/1999/XSL/Transform"
            xmlns:b="https://curity.se/ns/conf/base"
            xmlns:jdbc="https://curity.se/ns/ext-conf/jdbc"
            xmlns:xalan="http://xml.apache.org/xalan"
            xmlns:sec="xalan://se.curity.identityserver.crypto.SecretConverter"
            exclude-result-prefixes="xalan">
    <output indent="no" omit-xml-declaration="yes"/>

    <param name="encryptionKey" select="initialValue"/>
    <param name="decryptionKeys"/>

    <template match="b:facilities/b:data-sources/b:data-source/jdbc:jdbc/jdbc:connection-string">
      <variable name="data">
        <value-of select="." />
      </variable>
      <value-of select="sec:reencryptSecret($data, $encryptionKey, $decryptionKeys)"/>
    </template>
    <template match="text()"/>
</stylesheet>
EOF

	cat <<EOF > $XML_FILE
<config xmlns="http://tail-f.com/ns/config/1.0">
	<facilities xmlns="https://curity.se/ns/conf/base">
	  <data-sources>
		  <data-source>
		    <jdbc xmlns="https://curity.se/ns/ext-conf/jdbc">
			    <connection-string>$PLAINTEXT</connection-string>
		    </jdbc>
		  </data-source>
	  </data-sources>
	</facilities>
</config>
EOF

    java -cp "$CLASSPATH" org.apache.xalan.xslt.Process \
        -xsl "$XSLT_FILE" \
        -in "$XML_FILE" \
        -param encryptionKey "$ENCRYPTIONKEY"
}

#
# Uses an encryptor that takes base64 plaintext and produces data:application/p12 or data:application/pem encrypted output
#
function encrypt_base64keystore() {

	CLASSPATH="$IDSVR_HOME/lib/*"
	XML_FILE=$(mktemp)
	XSLT_FILE=$(mktemp)
	trap 'rm -f "$XML_FILE $XSLT_FILE"' EXIT

	cat <<'EOF' > $XSLT_FILE
<stylesheet version="1.0" xmlns="http://www.w3.org/1999/XSL/Transform"
            xmlns:b="https://curity.se/ns/conf/base"
            xmlns:xalan="http://xml.apache.org/xalan"
            xmlns:sec="xalan://se.curity.identityserver.crypto.ConvertKeyStore"
            exclude-result-prefixes="xalan">
    <output indent="no" omit-xml-declaration="yes"/>

    <param name="encryptionKey" select="initialValue"/>
    <param name="decryptionKeys"/>

    <template match="b:facilities/b:crypto/b:ssl/b:server-keystore/b:keystore">
      <variable name="data">
        <value-of select="." />
      </variable>
      <value-of select="sec:reencryptKeyStores($data, $encryptionKey, $decryptionKeys)"/>
    </template>
    <template match="text()"/>
</stylesheet>
EOF

	cat <<EOF > $XML_FILE
<config xmlns="http://tail-f.com/ns/config/1.0">
	<facilities xmlns="https://curity.se/ns/conf/base">
	  <crypto>
      <ssl>
        <server-keystore>
          <id>default-admin-ssl-key</id>
          <keystore>$PLAINTEXT</keystore>
        </server-keystore>
      </ssl>
    </crypto>
	</facilities>
</config>
EOF

    java -cp "$CLASSPATH" org.apache.xalan.xslt.Process \
        -xsl "$XSLT_FILE" \
        -in "$XML_FILE" \
        -param encryptionKey "$ENCRYPTIONKEY"
}

#
# Check input parameters
#
if [ "$TYPE" != 'plaintext' -a "$TYPE" != 'base64keystore' ]; then
  usage_message
  exit 1
fi
if [ "$ENCRYPTIONKEY" == '' ]; then
  usage_message
  exit 1
fi

#
# Check we have a path to the identity server
#
if [ "$IDSVR_HOME" == '' ]; then
  echo "The IDSVR_HOME environment variable has not been configured"
  exit 1
fi

#
# Do the encryption work
#
if [ "$TYPE" == 'plaintext' ]; then

  encrypt_plaintext "$PLAINTEXT" "$ENCRYPTIONKEY"

elif [ "$TYPE" == 'base64keystore' ]; then

  encrypt_base64keystore "$PLAINTEXT" "$ENCRYPTIONKEY"

fi
