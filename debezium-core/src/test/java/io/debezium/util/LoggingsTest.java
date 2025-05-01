package io.debezium.util;

import static org.junit.Assert.assertEquals;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;

public class LoggingsTest {

    private static final Logger LOGGER = LoggerFactory.getLogger(LoggingsTest.class);
    private static final Logger LOGGINGS_LOGGER = LoggerFactory.getLogger(Loggings.class);
    private ListAppender<ILoggingEvent> listAppender;
    private Level originalLoggingsLevel;
    private Level originalCallerLevel;

    @Before
    public void beforeEach() {
        listAppender = new ListAppender<>();
        listAppender.start();
        ((ch.qos.logback.classic.Logger) LOGGER).addAppender(listAppender);
        originalLoggingsLevel = ((ch.qos.logback.classic.Logger) LOGGINGS_LOGGER).getLevel();
        originalCallerLevel = ((ch.qos.logback.classic.Logger) LOGGER).getLevel();
    }

    @After
    public void afterEach() {
        ((ch.qos.logback.classic.Logger) LOGGER).detachAppender(listAppender);
        ((ch.qos.logback.classic.Logger) LOGGINGS_LOGGER).setLevel(originalLoggingsLevel);
        ((ch.qos.logback.classic.Logger) LOGGER).setLevel(originalCallerLevel);
    }

    @Test
    public void shouldRedactSensitiveDdlWhenTraceDisabled() {
        // Set caller to INFO - should redact sensitive DDL
        ((ch.qos.logback.classic.Logger) LOGGER).setLevel(Level.INFO);

        String sensitiveDdl = "ALTER USER 'test_user'@'%' IDENTIFIED BY 'password123'";
        String result = (String) Loggings.maybeRedactSensitiveData(sensitiveDdl);
        assertEquals("[REDACTED]", result);
    }

    @Test
    public void shouldNotRedactRegularDdlWhenTraceDisabled() {
        // Set caller to INFO - should NOT redact regular DDL
        ((ch.qos.logback.classic.Logger) LOGGER).setLevel(Level.INFO);

        String regularDdl = "CREATE TABLE users (id INT, name VARCHAR(100))";
        String result = (String) Loggings.maybeRedactSensitiveData(regularDdl);
        assertEquals(regularDdl, result);
    }

    @Test
    public void shouldShowSensitiveDdlWhenTraceEnabled() {
        // Set caller to TRACE - should show sensitive DDL
        ((ch.qos.logback.classic.Logger) LOGGER).setLevel(Level.TRACE);

        String sensitiveDdl = "ALTER USER 'test_user'@'%' IDENTIFIED BY 'password123'";
        String result = (String) Loggings.maybeRedactSensitiveData(sensitiveDdl);
        assertEquals(sensitiveDdl, result);
    }

    @Test
    public void demonstrateLoggingOutput() {
        // Set caller to INFO to show normal logging behavior
        ((ch.qos.logback.classic.Logger) LOGGER).setLevel(Level.INFO);

        // Example of a DDL that should be filtered (RDS heartbeat)
        String rdsHeartbeatDdl = "INSERT INTO mysql.rds_heartbeat2(id, value) values (1, '2025-04-30 14:51:37') ON DUPLICATE KEY UPDATE value = '2025-04-30 14:51:37'";
        LOGGER.info("a DDL '{}' was filtered out of processing by regular expression '{}'",
                Loggings.maybeRedactSensitiveData(rdsHeartbeatDdl), "INSERT INTO (mysql\\.)?rds_heartbeat2.*");

        // Example of a sensitive DDL that should be redacted
        String sensitiveDdl = "ALTER USER 'test_user'@'%' IDENTIFIED BY 'password123'";
        LOGGER.info("a DDL '{}' was filtered out of processing by regular expression '{}'",
                Loggings.maybeRedactSensitiveData(sensitiveDdl), "ALTER USER.*IDENTIFIED BY.*");

        // Example of a regular DDL that should not be redacted
        String regularDdl = "CREATE TABLE users (id INT, name VARCHAR(100))";
        LOGGER.info("a DDL '{}' was filtered out of processing by regular expression '{}'",
                Loggings.maybeRedactSensitiveData(regularDdl), "CREATE TABLE.*");

        // Print the actual log messages
        System.out.println("\nActual log output:");
        for (ILoggingEvent event : listAppender.list) {
            System.out.println(event.getFormattedMessage());
        }
    }
}
