FROM gcr.io/shopify-docker-images/cloud/maven-gradle-sbt-jdk@sha256:cca42609f7a9bb30c2fc7a23345f830b078a486d5bd527dddaefc48b127aa678

USER root

WORKDIR /app/src
COPY . /app/src/

# Install the components needed to build the project
RUN --mount=type=secret,id=maven_read,dst=/root/.m2/settings.xml \
    --mount=type=cache,target=/root/.m2 \
    mvn clean install -pl debezium-connector-mysql -am -Passembly -DskipITs -DskipTests && \
    mvn clean install -pl debezium-core -am -Passembly -DskipITs -DskipTests && \
    mvn clean install -pl debezium-api -am -Passembly -DskipITs -DskipTests
