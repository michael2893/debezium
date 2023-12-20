FROM gcr.io/shopify-docker-images/cloud/kafka-connect:3.4.0-2

USER root

COPY script/ /app/script/
COPY config /app/resources

WORKDIR /app/src
COPY . /app/src/

ARG DEBEZIUM_VERSION
ARG IS_LATEST
RUN \
  --mount=type=secret,id=gitconfig,target=/etc/gitconfig \
  --mount=type=secret,id=git-credential-helper \
  --mount=type=secret,id=gitcredentials \
  /app/script/checkout_dbz_version $DEBEZIUM_VERSION $IS_LATEST

ARG BUILD_CONNECTOR_MYSQL
RUN --mount=type=secret,id=maven_read,dst=/root/.m2/settings.xml \
    --mount=type=cache,target=/root/.m2/repository       \
    $BUILD_CONNECTOR_MYSQL

# DEBEZIUM_CORE_VERSION is used to import debezium-core for all versions of DBZ released with this pipeline.
ENV CDC_STATSD_METER_REGISTRY_VERSION=4ab8354 \
    CDC_LARGE_RECORD_VERSION=4ab8354 \
    CDC_REWRITE_NAMESPACE_VERSION=4ab8354 \
    CDC_QUERY_MINIFIER_VERSION=4ab8354 \
    CDC_REDACT_BEFORE=4ab8354 \
    CDC_SOURCE_METADATA=4ab8354 \
    CDC_SLOW_DOWN=4ab8354 \
    CDC_DOMAIN_EVENTS=4ab8354 \
    DEBEZIUM_CORE_VERSION="2.2.1.Final" \
    GRPC_VERSION="1.47.0"

# NB: use md5 of cdc-large-record-shaded and cdc-slow-down-shaded below!
RUN --mount=type=secret,id=maven_read,dst=/root/.m2/settings.xml \
    --mount=type=cache,target=/root/.m2/repository       \
    docker-maven-download confluent kafka-protobuf-serializer "$CONFLUENT_VERSION" 8f03ec2a7c770e5bec26762be481a08c && \
    docker-maven-download confluent kafka-connect-protobuf-converter "$CONFLUENT_VERSION" a947c76e80d4d711e951bb7ff466d3f4 && \
    docker-maven-download cdc-jar com/shopify cdc-statsd-meter-registry "$CDC_STATSD_METER_REGISTRY_VERSION" 9ac3921091440b369d3e1aa758238cb5 && \
    docker-maven-download shaded-cdc-jar com/shopify cdc-large-record "$CDC_LARGE_RECORD_VERSION" 4d57bed681107e6acabc4518a4edef8e && \
    docker-maven-download cdc-jar com/shopify cdc-rewrite-namespace "$CDC_REWRITE_NAMESPACE_VERSION" 23b26c99d5ebb3bcb341510011a5991d && \
    docker-maven-download cdc-jar com/shopify cdc-query-minifier "$CDC_QUERY_MINIFIER_VERSION" e977bf6f392de8004f5d7b9dd1c2633d && \
    docker-maven-download cdc-jar com/shopify cdc-redact-before "$CDC_REDACT_BEFORE" a52bed619aeba8df966c7c499c8c429e && \
    docker-maven-download cdc-jar com/shopify cdc-source-metadata "$CDC_SOURCE_METADATA" 1b9939a44353e14de0061d8b08c9ef06 && \
    docker-maven-download shaded-cdc-jar com/shopify cdc-slow-down "$CDC_SLOW_DOWN" 95367141afd1736357735b42a61036c8 && \
    docker-maven-download cdc-jar com/shopify cdc-domain-events "$CDC_DOMAIN_EVENTS" c163d9e988174729f63ddf44d7d102a0 && \
    docker-maven-download central io/debezium debezium-core "$DEBEZIUM_CORE_VERSION" 9543b1b766acefe56ff88a59fad228d1 && \
    docker-maven-download central io/debezium debezium-api "$DEBEZIUM_CORE_VERSION" 6810b562eb342067d301a9d3c9c29097 && \
    docker-maven-download central io/debezium debezium-connector-vitess "$DEBEZIUM_CORE_VERSION" 37587c505cb3214abb27c4371c8992b1 && \
    docker-maven-download central io/grpc grpc-api "$GRPC_VERSION" 58cb4f05581a5cadf82449b41e3aa50d

RUN \
  --mount=type=secret,id=gitconfig,target=/etc/gitconfig,required=true \
  --mount=type=secret,id=git-credential-helper \
  --mount=type=secret,id=gitcredentials \
  cd /tmp && \
  git clone https://github.com/Shopify/cdc.git && \
  cp /tmp/cdc/scripts/cert_check.sh /tmp/cdc/scripts/health_check.sh /usr/local/ && \
  rm -rf /tmp/cdc

ENTRYPOINT ["/app/script/entrypoint.sh"]
