FROM gcr.io/shopify-docker-images/cloud/kafka-connect:2.4.0

USER root
COPY script/ /app/script/

RUN /app/script/install_maven

WORKDIR /app/src
COPY . /app/src/

ENV DEBEZIUM_VERSION "1.2.0-SNAPSHOT"
RUN /app/script/build_connector_mysql

ENTRYPOINT ["/app/script/entrypoint.sh"]
