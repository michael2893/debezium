FROM gcr.io/shopify-docker-images/cloud/kafka-connect:2.4.0

USER root
COPY script/ /app/script/

RUN /app/script/install_maven

WORKDIR /app/src
COPY . /app/src/

ENV DEBEZIUM_VERSION "1.2.0-SNAPSHOT"
RUN /app/script/build_connector_mysql

ENV CDC_LARGE_RECORD_VERSION=29 \
    CDC_REWRITE_NAMESPACE_VERSION=20

ARG JARS_PACKAGE_CLOUD_TOKEN

RUN /app/script/docker-maven-download.sh cdc-jar com/shopify cdc-large-record "$CDC_LARGE_RECORD_VERSION" 80530d1080182f60e7d35708c6ce2ec2 && \
    /app/script/docker-maven-download.sh cdc-jar com/shopify cdc-rewrite-namespace "$CDC_REWRITE_NAMESPACE_VERSION" 4aa1b76099c2e4138afea4e4f63dde37

ENTRYPOINT ["/app/script/entrypoint.sh"]
