#!/bin/bash
set -euo

mkdir /app/ssl
/usr/local/create_truststore.sh

if [[ -n "${PROFILER_ENABLED:-}" && "$PROFILER_ENABLED" == "true" ]]; then
  export KAFKA_OPTS="$KAFKA_OPTS $PROFILER_CONFIGS"
fi

exec /docker-entrypoint.sh start
