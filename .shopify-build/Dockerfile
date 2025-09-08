# This Dockerfile is used by cdc-core to build the Debezium Image for the Shopify CDC in that buildkite pipeline
FROM us-docker.pkg.dev/shopify-docker-images/containers/cloud/maven-gradle-sbt-jdk@sha256:cb3a7e87993d1865d6169142b0fb6033445ea7bfea80aaebb401408e28cf43b4

USER root

WORKDIR /app/src
COPY . /app/src/

# Install the components needed to build the project
RUN --mount=type=secret,id=maven_read,dst=/root/.m2/settings.xml \
    --mount=type=cache,target=/root/.m2 \
    mvn clean install -pl debezium-connector-mysql -am -Passembly -DskipITs -DskipTests && \
    mvn clean install -pl debezium-core -am -Passembly -DskipITs -DskipTests && \
    mvn clean install -pl debezium-api -am -Passembly -DskipITs -DskipTests \
