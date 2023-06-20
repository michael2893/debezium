# syntax=docker/dockerfile:1.0-experimental

FROM gcr.io/shopify-docker-images/cloud/kafka-connect:3.4.0-1

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
ENV CDC_STATSD_METER_REGISTRY_VERSION=935c529 \
    CDC_LARGE_RECORD_VERSION=935c529 \
    CDC_REWRITE_NAMESPACE_VERSION=935c529 \
    CDC_QUERY_MINIFIER_VERSION=935c529 \
    CDC_REDACT_BEFORE=935c529 \
    CDC_SOURCE_METADATA=935c529 \
    CDC_SLOW_DOWN=935c529 \
    CDC_DOMAIN_EVENTS=935c529 \
    DEBEZIUM_CORE_VERSION="2.2.1.Final" \
    GRPC_VERSION="1.47.0"

# NB: use md5 of cdc-large-record-shaded and cdc-slow-down-shaded below!
RUN --mount=type=secret,id=maven_read,dst=/root/.m2/settings.xml \
    --mount=type=cache,target=/root/.m2/repository       \
    docker-maven-download cdc-jar com/shopify cdc-statsd-meter-registry "$CDC_STATSD_METER_REGISTRY_VERSION" 231d6a628d3f04aeb38fa9f91a84993e && \
    docker-maven-download shaded-cdc-jar com/shopify cdc-large-record "$CDC_LARGE_RECORD_VERSION" f7620280d560f64e4157092bc61875ab && \
    docker-maven-download cdc-jar com/shopify cdc-rewrite-namespace "$CDC_REWRITE_NAMESPACE_VERSION" c0ad4ba8f8239d9764426cdc4713570d && \
    docker-maven-download cdc-jar com/shopify cdc-query-minifier "$CDC_QUERY_MINIFIER_VERSION" 06f6a9515dc818726b6be37a1b0c67bf && \
    docker-maven-download cdc-jar com/shopify cdc-redact-before "$CDC_REDACT_BEFORE" 16a0621b7bd44cc20faad6735e814e75 && \
    docker-maven-download cdc-jar com/shopify cdc-source-metadata "$CDC_SOURCE_METADATA" 75a19d0263a7c8087178c8a70cfeccd2 && \
    docker-maven-download shaded-cdc-jar com/shopify cdc-slow-down "$CDC_SLOW_DOWN" 3638b54d8a0ecf62348b4bb8fd9cbf77 && \
    docker-maven-download cdc-jar com/shopify cdc-domain-events "$CDC_DOMAIN_EVENTS" bcea6ef2e2ff5c4cb0b67a93b9a327a3 && \
    docker-maven-download central io/debezium debezium-core "$DEBEZIUM_CORE_VERSION" 9543b1b766acefe56ff88a59fad228d1 && \
    docker-maven-download central io/debezium debezium-api "$DEBEZIUM_CORE_VERSION" 6810b562eb342067d301a9d3c9c29097 && \
    docker-maven-download central io/debezium debezium-connector-vitess "$DEBEZIUM_CORE_VERSION" 37587c505cb3214abb27c4371c8992b1 && \
    docker-maven-download central io/grpc grpc-api "$GRPC_VERSION" 58cb4f05581a5cadf82449b41e3aa50d

ENTRYPOINT ["/app/script/entrypoint.sh"]
