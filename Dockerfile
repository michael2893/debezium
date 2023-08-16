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
ENV CDC_STATSD_METER_REGISTRY_VERSION=0dcc1e8 \
    CDC_LARGE_RECORD_VERSION=0dcc1e8 \
    CDC_REWRITE_NAMESPACE_VERSION=0dcc1e8 \
    CDC_QUERY_MINIFIER_VERSION=0dcc1e8 \
    CDC_REDACT_BEFORE=0dcc1e8 \
    CDC_SOURCE_METADATA=0dcc1e8 \
    CDC_SLOW_DOWN=0dcc1e8 \
    CDC_DOMAIN_EVENTS=0dcc1e8 \
    DEBEZIUM_CORE_VERSION="2.2.1.Final" \
    GRPC_VERSION="1.47.0"

# NB: use md5 of cdc-large-record-shaded and cdc-slow-down-shaded below!
RUN --mount=type=secret,id=maven_read,dst=/root/.m2/settings.xml \
    --mount=type=cache,target=/root/.m2/repository       \
    docker-maven-download cdc-jar com/shopify cdc-statsd-meter-registry "$CDC_STATSD_METER_REGISTRY_VERSION" ce65156a2b485e999f82d08bc23854e9 && \
    docker-maven-download shaded-cdc-jar com/shopify cdc-large-record "$CDC_LARGE_RECORD_VERSION" cc82c535876fe789c733c862a5a0a45f && \
    docker-maven-download cdc-jar com/shopify cdc-rewrite-namespace "$CDC_REWRITE_NAMESPACE_VERSION" 2d2c4b622b6f384f3fd0cdba37c341e3 && \
    docker-maven-download cdc-jar com/shopify cdc-query-minifier "$CDC_QUERY_MINIFIER_VERSION" ea187fca147b2a23709c81b43629c2cb && \
    docker-maven-download cdc-jar com/shopify cdc-redact-before "$CDC_REDACT_BEFORE" 1b1197efdba9887330c7ad73d312d763 && \
    docker-maven-download cdc-jar com/shopify cdc-source-metadata "$CDC_SOURCE_METADATA" 2cbe7dd3575d07c6b20a878aad13f313 && \
    docker-maven-download shaded-cdc-jar com/shopify cdc-slow-down "$CDC_SLOW_DOWN" f3b4e93d04072b4e7ccad05dde51421b && \
    docker-maven-download cdc-jar com/shopify cdc-domain-events "$CDC_DOMAIN_EVENTS" fcb2139003094938ee9daab02d4d8d4f && \
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
