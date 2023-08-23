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
ENV CDC_STATSD_METER_REGISTRY_VERSION=4ae705a \
    CDC_LARGE_RECORD_VERSION=4ae705a \
    CDC_REWRITE_NAMESPACE_VERSION=4ae705a \
    CDC_QUERY_MINIFIER_VERSION=4ae705a \
    CDC_REDACT_BEFORE=4ae705a \
    CDC_SOURCE_METADATA=4ae705a \
    CDC_SLOW_DOWN=4ae705a \
    CDC_DOMAIN_EVENTS=4ae705a \
    DEBEZIUM_CORE_VERSION="2.2.1.Final" \
    GRPC_VERSION="1.47.0"

# NB: use md5 of cdc-large-record-shaded and cdc-slow-down-shaded below!
RUN --mount=type=secret,id=maven_read,dst=/root/.m2/settings.xml \
    --mount=type=cache,target=/root/.m2/repository       \
    docker-maven-download cdc-jar com/shopify cdc-statsd-meter-registry "$CDC_STATSD_METER_REGISTRY_VERSION" 3d63d20d022399dff2f23ad659031853 && \
    docker-maven-download shaded-cdc-jar com/shopify cdc-large-record "$CDC_LARGE_RECORD_VERSION" 781318f6de4ee81904fcdb4b1c56ba2c && \
    docker-maven-download cdc-jar com/shopify cdc-rewrite-namespace "$CDC_REWRITE_NAMESPACE_VERSION" c12aa1435c1e95f0cf1068b93fa85754 && \
    docker-maven-download cdc-jar com/shopify cdc-query-minifier "$CDC_QUERY_MINIFIER_VERSION" cbb69e658f01e33d34cda2c7a8d53e7e && \
    docker-maven-download cdc-jar com/shopify cdc-redact-before "$CDC_REDACT_BEFORE" 9c26ea21a1af61ac54f165b3d2ebbf76 && \
    docker-maven-download cdc-jar com/shopify cdc-source-metadata "$CDC_SOURCE_METADATA" 658081d49d881c29ce934c82eac16d03 && \
    docker-maven-download shaded-cdc-jar com/shopify cdc-slow-down "$CDC_SLOW_DOWN" fee2fd3a957877f712d3e856a0b9e97d && \
    docker-maven-download cdc-jar com/shopify cdc-domain-events "$CDC_DOMAIN_EVENTS" ccb93c3aee3e236c7cbb7e35b9cd969b && \
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
