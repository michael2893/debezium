## Building the ScyllaDB CDC Connector

Instructions as of 7 September 2021, relevant while we still have the mTLS specific driver and connector forks.

* git clone git@github.com:methodmissing/scylla-cdc-java.git
* `git checkout tls`
* `mvn clean install -DskipTests`
* git clone git@github.com:methodmissing/scylla-cdc-source-connector.git
* `git checkout tls`
* `mvn clean package`
* Look in folder `target/fat-jar` for a JAR matching `scylla-cdc-source-connector-1.0.2-SNAPSHOT-jar-with-dependencies.jar`
* Copy it to the `support/connectors/scylla-cdc-source-connector`
* Add and submit as a PR
