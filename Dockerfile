# syntax=docker/dockerfile:1.0-experimental

FROM gcr.io/shopify-docker-images/cloud/kafka-connect:2.6.2

USER root
COPY script/install_maven /app/script/
RUN /app/script/install_maven
COPY poms/ /app/src/poms/
ARG GO_OFFLINE
ARG IGNORE_CACHE_ERROR
RUN --mount=type=secret,id=maven_read,dst=/root/.m2/settings.xml    \
    --mount=type=cache,target=/root/.m2/repository       \
    $GO_OFFLINE || $IGNORE_CACHE_ERROR

COPY script/ /app/script/

WORKDIR /app/src
COPY . /app/src/

ARG BUILD_CONNECTOR_MYSQL
ENV DEBEZIUM_VERSION "1.6.0-SNAPSHOT"
RUN --mount=type=secret,id=maven_read,dst=/root/.m2/settings.xml \
    --mount=type=cache,target=/root/.m2/repository       \
    $BUILD_CONNECTOR_MYSQL

# DEBEZIUM_CORE_VERSION is used to import debezium-core for all versions of DBZ released with this pipeline.

ENV CDC_LARGE_RECORD_VERSION=e2878d4 \
    CDC_REWRITE_NAMESPACE_VERSION=2ea8ccf \
    CDC_QUERY_MINIFIER_VERSION=2ea8ccf \
    CDC_REDACT_BEFORE=2ea8ccf \
    CDC_SOURCE_METADATA=2ea8ccf \
    DEBEZIUM_CORE_VERSION="1.5.1.Final"


ARG JARS_CLOUDSMITH_TOKEN

RUN docker-maven-download shaded-cdc-jar com/shopify cdc-large-record "$CDC_LARGE_RECORD_VERSION" f5da682ddb31b976ad024b628f84425b && \
    docker-maven-download cdc-jar com/shopify cdc-rewrite-namespace "$CDC_REWRITE_NAMESPACE_VERSION" bae212c7e9f67330381036885e5c2fc9 && \
    docker-maven-download cdc-jar com/shopify cdc-query-minifier "$CDC_QUERY_MINIFIER_VERSION" 0efe8462f94a7bc8ec46149fd2417e39 && \
    docker-maven-download cdc-jar com/shopify cdc-redact-before "$CDC_REDACT_BEFORE" 524960211bae4beea43dd8df93e6e2c0 && \
    docker-maven-download cdc-jar com/shopify cdc-source-metadata "$CDC_SOURCE_METADATA" 5b70889907d353b58f53b607ff5b86e0 && \
    docker-maven-download central io/debezium debezium-core "$DEBEZIUM_CORE_VERSION" 4da16b4f5e1c6a3fc77a0150305ab079

ENTRYPOINT ["/app/script/entrypoint.sh"]
