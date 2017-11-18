#!/bin/bash

# Prepare SQL functions for import. Has to be run every time when import-sql was required

set -e

PROGPATH=$(dirname "$0")
source $PROGPATH/env.sh

function exec_psql_file() {
    local file_name="$1"
    echo $file_name
    PGPASSWORD="$POSTGRES_PASSWORD" psql \
        -v ON_ERROR_STOP="1" \
        --host="$POSTGRES_HOST" \
        --port="$POSTGRES_PORT" \
        --dbname="$POSTGRES_DB" \
        --username="$POSTGRES_USER" \
        -f "$file_name"
}

function main() {
  exec_psql_file "$PROGPATH/postgis-vt-util.sql"
}

main
