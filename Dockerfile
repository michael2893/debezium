FROM gcr.io/shopify-docker-images/cloud/kafka-connect:2.5.1

USER root
COPY script/ /app/script/

RUN /app/script/install_maven

WORKDIR /app/src
COPY . /app/src/

ENV DEBEZIUM_VERSION "1.4.0-SNAPSHOT"
RUN /app/script/build_connector_mysql

ENV CDC_LARGE_RECORD_VERSION=74 \
    CDC_REWRITE_NAMESPACE_VERSION=70 \
    CDC_QUERY_MINIFIER_VERSION=73

ARG JARS_PACKAGE_CLOUD_TOKEN

RUN /app/script/docker-maven-download.sh shaded-cdc-jar com/shopify cdc-large-record "$CDC_LARGE_RECORD_VERSION" 43bf97c0a26363b15c7f13224fa79af3 && \
    /app/script/docker-maven-download.sh cdc-jar com/shopify cdc-rewrite-namespace "$CDC_REWRITE_NAMESPACE_VERSION" 951db6c80826861e1b129c266d05ccc5 && \
    /app/script/docker-maven-download.sh cdc-jar com/shopify cdc-query-minifier "$CDC_QUERY_MINIFIER_VERSION" 386ff485c43a94836a7b7c256be98808

ENTRYPOINT ["/app/script/entrypoint.sh"]
