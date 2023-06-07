# syntax=docker/dockerfile:1.0-experimental

FROM gcr.io/shopify-docker-images/cloud/kafka-connect:3.2.0-4

USER root
RUN apt-get update && \
    apt-get install -y git

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
ENV CDC_STATSD_METER_REGISTRY_VERSION=103f347 \
    CDC_LARGE_RECORD_VERSION=103f347 \
    CDC_REWRITE_NAMESPACE_VERSION=103f347 \
    CDC_QUERY_MINIFIER_VERSION=103f347 \
    CDC_REDACT_BEFORE=103f347 \
    CDC_SOURCE_METADATA=103f347 \
    CDC_SLOW_DOWN=103f347 \
    CDC_DOMAIN_EVENTS=103f347 \
    DEBEZIUM_CORE_VERSION="2.2.1.Final" \
    GRPC_VERSION="1.47.0"

# NB: use md5 of cdc-large-record-shaded and cdc-slow-down-shaded below!
RUN --mount=type=secret,id=maven_read,dst=/root/.m2/settings.xml \
    --mount=type=cache,target=/root/.m2/repository       \
    docker-maven-download cdc-jar com/shopify cdc-statsd-meter-registry "$CDC_STATSD_METER_REGISTRY_VERSION" ae8ef347c1596a4a5b176ef493b3ba84 && \
    docker-maven-download shaded-cdc-jar com/shopify cdc-large-record "$CDC_LARGE_RECORD_VERSION" 1282e08df748a3b7e031b06d38f3a16c && \
    docker-maven-download cdc-jar com/shopify cdc-rewrite-namespace "$CDC_REWRITE_NAMESPACE_VERSION" 6995b6b771002ba4113c28b43bf80d3c && \
    docker-maven-download cdc-jar com/shopify cdc-query-minifier "$CDC_QUERY_MINIFIER_VERSION" c26ab259b0cd8b8a52ba99045d6083bc && \
    docker-maven-download cdc-jar com/shopify cdc-redact-before "$CDC_REDACT_BEFORE" c523214db283c43dcbf4b5d71bc375ae && \
    docker-maven-download cdc-jar com/shopify cdc-source-metadata "$CDC_SOURCE_METADATA" 2f44b7ee5ee2cec83c2428614c5f01d5 && \
    docker-maven-download shaded-cdc-jar com/shopify cdc-slow-down "$CDC_SLOW_DOWN" 47c525a0fb76b0543c7e088932748264 && \
    docker-maven-download cdc-jar com/shopify cdc-domain-events "$CDC_DOMAIN_EVENTS" 3677d16411d4c070f4dc7792ef6ebf7d && \
    docker-maven-download central io/debezium debezium-core "$DEBEZIUM_CORE_VERSION" 9543b1b766acefe56ff88a59fad228d1 && \
    docker-maven-download central io/debezium debezium-api "$DEBEZIUM_CORE_VERSION" 6810b562eb342067d301a9d3c9c29097 && \
    docker-maven-download central io/debezium debezium-connector-vitess "$DEBEZIUM_CORE_VERSION" 37587c505cb3214abb27c4371c8992b1 && \
    docker-maven-download central io/grpc grpc-api "$GRPC_VERSION" 58cb4f05581a5cadf82449b41e3aa50d

ENTRYPOINT ["/app/script/entrypoint.sh"]
