FROM gcr.io/shopify-docker-images/cloud/kafka-connect:2.6.0

USER root
COPY script/ /app/script/

RUN /app/script/install_maven

WORKDIR /app/src
COPY . /app/src/

ENV DEBEZIUM_VERSION "1.6.0-SNAPSHOT"
RUN /app/script/build_connector_mysql

# DEBEZIUM_CORE_VERSION is used to import debezium-core for all versions of DBZ released with this pipeline.

ENV CDC_LARGE_RECORD_VERSION=114 \
    CDC_REWRITE_NAMESPACE_VERSION=114 \
    CDC_QUERY_MINIFIER_VERSION=114 \
    CDC_REDACT_BEFORE=114 \
    CDC_SOURCE_METADATA=114 \
    DEBEZIUM_CORE_VERSION="1.4.0.Final"


ARG JARS_CLOUDSMITH_TOKEN

RUN docker-maven-download shaded-cdc-jar com/shopify cdc-large-record "$CDC_LARGE_RECORD_VERSION" ec44a4b579ea940c86ee8adecb1e3c46 && \
    docker-maven-download cdc-jar com/shopify cdc-rewrite-namespace "$CDC_REWRITE_NAMESPACE_VERSION" 547ae9129a557f31b93cad7cf06500d8 && \
    docker-maven-download cdc-jar com/shopify cdc-query-minifier "$CDC_QUERY_MINIFIER_VERSION" 89d195faac2c519091d856c9828545cc && \
    docker-maven-download cdc-jar com/shopify cdc-redact-before "$CDC_REDACT_BEFORE" 7d6664ec8e3a1d80a7174955d67b5a83 && \
    docker-maven-download cdc-jar com/shopify cdc-source-metadata "$CDC_SOURCE_METADATA" bd4117a7b067beaa7672c187d54794cb && \
    docker-maven-download central io/debezium debezium-core "$DEBEZIUM_CORE_VERSION" bcbc9b3d39c685ba2bd2992913eb58b6

ENTRYPOINT ["/app/script/entrypoint.sh"]
