#!/bin/bash
set -eu

ca_pem_file="/kafka/ca.pem"
ca_tmp_file="/tmp/ca.pem"
kafka_secrets_location="/kafka/secrets/*"

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

KATESQL_CA_CERT_PATH="${KATESQL_CA_CERT_PATH:-/app/config/katesql-cert.pem}"
if test -f "$KATESQL_CA_CERT_PATH"; then
  keytool -import -noprompt -alias katesqlcert \
      -storepass ${CONNECT_SSL_TRUSTSTORE_PASSWORD} \
      -keystore ${CONNECT_SSL_TRUSTSTORE_LOCATION} \
      -trustcacerts -file ${KATESQL_CA_CERT_PATH}
fi

# Import JDK default truststore as well since we override it at runtime with -Djavax.net.ssl.trustStore and
# that makes third party API clients such as Google Storage in a Kafka Connect runtime not trust remote certs
# JDK defaults imported to our custom store means no cat and mouse to keep up with the JDK
keytool -importkeystore -noprompt -srckeystore ${JAVA_HOME}/lib/security/cacerts -srcstorepass ${CONNECT_SSL_KEYSTORE_PASSWORD} \
    -destkeystore ${CONNECT_SSL_TRUSTSTORE_LOCATION} -deststorepass ${CONNECT_SSL_KEYSTORE_PASSWORD}

# Support trust and keystore setup for connectors with client cert authentication support
for directory in ${kafka_secrets_location}; do
  if [ -d "${directory}" ]; then
    connector=${directory##*/}
    openssl pkcs12 -export -password pass:changeit -out /tmp/${connector}_ks.p12 \
  -inkey /kafka/secrets/${connector}/tls.key -certfile /kafka/secrets/${connector}/ca.crt -in /kafka/secrets/${connector}/tls.crt -caname 'CA Root' -name client

    keytool -importkeystore -noprompt -srckeystore /tmp/${connector}_ks.p12 -destkeystore /tmp/${connector}_keystore.jks \
  -srcstoretype pkcs12 -srcstorepass changeit -srckeypass changeit \
  -destkeypass changeit -deststorepass changeit -alias client

    keytool -noprompt -keystore /tmp/${connector}_truststore.jks -alias CARoot -import \
  -file /kafka/secrets/${connector}/ca.crt -storepass changeit
  fi
done
