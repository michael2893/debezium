# syntax=docker/dockerfile:1.0-experimental

FROM gcr.io/shopify-docker-images/cloud/kafka-connect:2.8.1-5

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
ENV CDC_LARGE_RECORD_VERSION=9632679 \
    CDC_REWRITE_NAMESPACE_VERSION=9632679 \
    CDC_QUERY_MINIFIER_VERSION=9632679 \
    CDC_REDACT_BEFORE=9632679 \
    CDC_SOURCE_METADATA=9632679 \
    CDC_SLOW_DOWN=9632679 \
    DEBEZIUM_CORE_VERSION="1.9.3.Final"

# NB: use md5 of cdc-large-record-shaded and cdc-slow-down-shaded below!
RUN --mount=type=secret,id=maven_read,dst=/root/.m2/settings.xml \
    --mount=type=cache,target=/root/.m2/repository       \
    docker-maven-download shaded-cdc-jar com/shopify cdc-large-record "$CDC_LARGE_RECORD_VERSION" 1658e2dd5303af5237bfa36d86a2caee && \
    docker-maven-download cdc-jar com/shopify cdc-rewrite-namespace "$CDC_REWRITE_NAMESPACE_VERSION" ce69307e7a0b1bdd3aebba84c2da4d2c && \
    docker-maven-download cdc-jar com/shopify cdc-query-minifier "$CDC_QUERY_MINIFIER_VERSION" 25cdfbe44b9777bc6cf3e12983c4dc01 && \
    docker-maven-download cdc-jar com/shopify cdc-redact-before "$CDC_REDACT_BEFORE" c776a8a64b6a214035042badbe664846 && \
    docker-maven-download cdc-jar com/shopify cdc-source-metadata "$CDC_SOURCE_METADATA" 5924c6fcf1109fa38422b9499492d761 && \
    docker-maven-download shaded-cdc-jar com/shopify cdc-slow-down "$CDC_SLOW_DOWN" f0f89633a889b233a263554e667bcf4a && \
    docker-maven-download central io/debezium debezium-core "$DEBEZIUM_CORE_VERSION" a48600b50730a2cbafbf36cf7fc60792 && \
    docker-maven-download central io/debezium debezium-api "$DEBEZIUM_CORE_VERSION" 7906d55cc0e65098421e64f733c5f2f5 && \
    docker-maven-download debezium vitess "$DEBEZIUM_CORE_VERSION" ba4b0e27759c9f43a7d619daa315c6b6

# Introduce support for initial incorporation of experimental or custom built connectors for testing
COPY support/connectors/* /kafka/connect/

ENTRYPOINT ["/app/script/entrypoint.sh"]
