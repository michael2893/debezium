#!/bin/bash
set -eu

ca_pem_file="/kafka/ca.pem"

openssl s_client -showcerts -connect kafka-cdc-0.kafka-cdc-change-data-capture-us-east1-1.shopifycloud.com:9093 \
    2>/dev/null | sed -n -e '/BEGIN\ CERTIFICATE/,/END\ CERTIFICATE/ p' > ${ca_pem_file}

openssl pkcs12 -export -password pass:${CONNECT_SSL_KEYSTORE_PASSWORD} -out ${KEYSTORE_LOCATION} \
    -inkey /ssl/kafka-client/tls.key -certfile ${ca_pem_file} -in /ssl/kafka-client/tls.crt \
      -caname 'CA Root' -name client

keytool -importkeystore -noprompt -srckeystore ${KEYSTORE_LOCATION} -destkeystore ${CONNECT_SSL_KEYSTORE_LOCATION} \
    -srcstoretype pkcs12 -srcstorepass ${CONNECT_SSL_KEYSTORE_PASSWORD} -srckeypass ${CONNECT_SSL_KEYSTORE_PASSWORD} \
      -destkeypass ${CONNECT_SSL_KEYSTORE_PASSWORD} -deststorepass ${CONNECT_SSL_KEYSTORE_PASSWORD} -alias client

keytool -noprompt -keystore ${CONNECT_SSL_TRUSTSTORE_LOCATION} -alias CARoot -import \
    -file ${ca_pem_file} -storepass ${CONNECT_SSL_TRUSTSTORE_PASSWORD}
