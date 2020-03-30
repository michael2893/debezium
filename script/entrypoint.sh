#!/bin/bash
set -euo 

. /app/script/tls.sh
exec /docker-entrypoint.sh start
