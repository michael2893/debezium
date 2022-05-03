# syntax=docker/dockerfile:1.0-experimental

FROM gcr.io/shopify-docker-images/cloud/kafka-connect:2.8.1-4

USER root
COPY script/install_maven /app/script/
RUN /app/script/install_maven

COPY script/ /app/script/

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
ENV CDC_LARGE_RECORD_VERSION=25e4a0f \
    CDC_REWRITE_NAMESPACE_VERSION=2ea8ccf \
    CDC_QUERY_MINIFIER_VERSION=9d749d4 \
    CDC_REDACT_BEFORE=2ea8ccf \
    CDC_SOURCE_METADATA=2ea8ccf \
    CDC_SLOW_DOWN=cc230e6 \
    DEBEZIUM_CORE_VERSION="1.8.0.Final"


RUN --mount=type=secret,id=maven_read,dst=/root/.m2/settings.xml \
    --mount=type=cache,target=/root/.m2/repository       \
    docker-maven-download shaded-cdc-jar com/shopify cdc-large-record "$CDC_LARGE_RECORD_VERSION" 78c2cdb9d3c2fee960aa6587722fb982 && \
    docker-maven-download cdc-jar com/shopify cdc-rewrite-namespace "$CDC_REWRITE_NAMESPACE_VERSION" bae212c7e9f67330381036885e5c2fc9 && \
    docker-maven-download cdc-jar com/shopify cdc-query-minifier "$CDC_QUERY_MINIFIER_VERSION" e266a0dd22e93ec313856c50bf0cd045 && \
    docker-maven-download cdc-jar com/shopify cdc-redact-before "$CDC_REDACT_BEFORE" 524960211bae4beea43dd8df93e6e2c0 && \
    docker-maven-download cdc-jar com/shopify cdc-source-metadata "$CDC_SOURCE_METADATA" 5b70889907d353b58f53b607ff5b86e0 && \
    docker-maven-download shaded-cdc-jar com/shopify cdc-slow-down "$CDC_SLOW_DOWN" ebd2d78d6ec248f4d528368bedc9e168 && \
    docker-maven-download central io/debezium debezium-core "$DEBEZIUM_CORE_VERSION" 66f609f5df6e037b1f41694b1ac63ff5 && \
    docker-maven-download central io/debezium debezium-api "$DEBEZIUM_CORE_VERSION" 02aee962ed6accac1be4396ccc129131

# Introduce support for initial incorporation of experimental or custom built connectors for testing
COPY support/connectors/* /kafka/connect/

ENTRYPOINT ["/app/script/entrypoint.sh"]
