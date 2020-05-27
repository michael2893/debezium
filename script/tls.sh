#!/bin/bash
set -eu

ca_pem_file="/kafka/ca.pem"
ca_tmp_file="/tmp/ca.pem"

IFS=','
read -ra SERVERS <<< "${BOOTSTRAP_SERVERS}"

echo "Generating certs from ${SERVERS[0]}"

openssl s_client -showcerts -connect ${SERVERS[0]} \
    2>/dev/null | sed -n -e '/BEGIN\ CERTIFICATE/,/END\ CERTIFICATE/ p' > ${ca_tmp_file}

sed -n -e "$(echo $(grep -n CERT ${ca_tmp_file} | cut -d: -f1 | tail -2) | xargs | sed 's/ /,/')p" ${ca_tmp_file} > ${ca_pem_file}

openssl pkcs12 -export -password pass:${CONNECT_SSL_KEYSTORE_PASSWORD} -out ${KEYSTORE_LOCATION} \
    -inkey /ssl/kafka-client/tls.key -certfile ${ca_pem_file} -in /ssl/kafka-client/tls.crt \
      -caname 'CA Root' -name client

keytool -importkeystore -noprompt -srckeystore ${KEYSTORE_LOCATION} -destkeystore ${CONNECT_SSL_KEYSTORE_LOCATION} \
    -srcstoretype pkcs12 -srcstorepass ${CONNECT_SSL_KEYSTORE_PASSWORD} -srckeypass ${CONNECT_SSL_KEYSTORE_PASSWORD} \
      -destkeypass ${CONNECT_SSL_KEYSTORE_PASSWORD} -deststorepass ${CONNECT_SSL_KEYSTORE_PASSWORD} -alias client

keytool -noprompt -keystore ${CONNECT_SSL_TRUSTSTORE_LOCATION} -alias CARoot -import \
    -file ${ca_pem_file} -storepass ${CONNECT_SSL_TRUSTSTORE_PASSWORD}
