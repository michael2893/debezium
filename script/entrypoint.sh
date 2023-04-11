#!/bin/bash
set -euo

mkdir /app/ssl
/usr/local/create_truststore.sh

exec /docker-entrypoint.sh start
