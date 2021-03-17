FROM gcr.io/shopify-docker-images/cloud/kafka-connect:2.6.0

USER root
COPY script/ /app/script/

RUN /app/script/install_maven

WORKDIR /app/src
COPY . /app/src/

ENV DEBEZIUM_VERSION "1.5.0-SNAPSHOT"
RUN /app/script/build_connector_mysql

# DEBEZIUM_CORE_VERSION is used to import debezium-core for all versions of DBZ released with this pipeline.
ENV CDC_LARGE_RECORD_VERSION=95 \
    CDC_REWRITE_NAMESPACE_VERSION=85 \
    CDC_QUERY_MINIFIER_VERSION=85 \
    CDC_REDACT_BEFORE=100 \
    CDC_SOURCE_METADATA=97 \
    DEBEZIUM_CORE_VERSION="1.4.0.Final"


ARG JARS_PACKAGE_CLOUD_TOKEN

RUN docker-maven-download shaded-cdc-jar com/shopify cdc-large-record "$CDC_LARGE_RECORD_VERSION" 658a48a27d82f0e8a7f1cffd81c8c290 && \
    docker-maven-download cdc-jar com/shopify cdc-rewrite-namespace "$CDC_REWRITE_NAMESPACE_VERSION" e71d2f7899be4bbe3ed6b9eda3fc9187 && \
    docker-maven-download cdc-jar com/shopify cdc-query-minifier "$CDC_QUERY_MINIFIER_VERSION" da293091385fb2f80ed8b950efb3eda6 && \
    docker-maven-download cdc-jar com/shopify cdc-redact-before "$CDC_REDACT_BEFORE" 8242d375078dfa723995a57a114e8506 && \
    docker-maven-download cdc-jar com/shopify cdc-source-metadata "$CDC_SOURCE_METADATA" 73155702e463a68e4a143a6fcfbab349 && \
    docker-maven-download central io/debezium debezium-core "$DEBEZIUM_CORE_VERSION" bcbc9b3d39c685ba2bd2992913eb58b6

ENTRYPOINT ["/app/script/entrypoint.sh"]
