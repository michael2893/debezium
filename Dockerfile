# syntax=docker/dockerfile:1.0-experimental

FROM gcr.io/shopify-docker-images/cloud/kafka-connect:3.2.0-0

USER root
RUN apt-get update && \
    apt-get install -y git

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
ENV CDC_STATSD_METER_REGISTRY_VERSION=42def1a \
    CDC_LARGE_RECORD_VERSION=42def1a \
    CDC_REWRITE_NAMESPACE_VERSION=9632679 \
    CDC_QUERY_MINIFIER_VERSION=42def1a \
    CDC_REDACT_BEFORE=9632679 \
    CDC_SOURCE_METADATA=9632679 \
    CDC_SLOW_DOWN=42def1a \
    CDC_DOMAIN_EVENTS=15e9f9d \
    DEBEZIUM_CORE_VERSION="1.9.3.Final"

# NB: use md5 of cdc-large-record-shaded and cdc-slow-down-shaded below!
RUN --mount=type=secret,id=maven_read,dst=/root/.m2/settings.xml \
    --mount=type=cache,target=/root/.m2/repository       \
    docker-maven-download cdc-jar com/shopify cdc-statsd-meter-registry "$CDC_STATSD_METER_REGISTRY_VERSION" 262392d9e01e6acccf1f57123efcb179 && \
    docker-maven-download shaded-cdc-jar com/shopify cdc-large-record "$CDC_LARGE_RECORD_VERSION" d61a93b5f0d28012c49553c22f614685 && \
    docker-maven-download cdc-jar com/shopify cdc-rewrite-namespace "$CDC_REWRITE_NAMESPACE_VERSION" ce69307e7a0b1bdd3aebba84c2da4d2c && \
    docker-maven-download cdc-jar com/shopify cdc-query-minifier "$CDC_QUERY_MINIFIER_VERSION" 009f3df2d9c4cdebcae8215ab0fbc357 && \
    docker-maven-download cdc-jar com/shopify cdc-redact-before "$CDC_REDACT_BEFORE" c776a8a64b6a214035042badbe664846 && \
    docker-maven-download cdc-jar com/shopify cdc-source-metadata "$CDC_SOURCE_METADATA" 5924c6fcf1109fa38422b9499492d761 && \
    docker-maven-download shaded-cdc-jar com/shopify cdc-slow-down "$CDC_SLOW_DOWN" 147e25c1bbb15b6b05479f9bc4077743 && \
    docker-maven-download cdc-jar com/shopify cdc-domain-events "$CDC_DOMAIN_EVENTS" 601ec9bd1dcf73fe7b167a57ae22d48d && \
    docker-maven-download central io/debezium debezium-core "$DEBEZIUM_CORE_VERSION" a48600b50730a2cbafbf36cf7fc60792 && \
    docker-maven-download central io/debezium debezium-api "$DEBEZIUM_CORE_VERSION" 7906d55cc0e65098421e64f733c5f2f5 && \
    docker-maven-download debezium vitess "$DEBEZIUM_CORE_VERSION" ba4b0e27759c9f43a7d619daa315c6b6

ENTRYPOINT ["/app/script/entrypoint.sh"]
