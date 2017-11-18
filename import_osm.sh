#!/bin/bash
set -e

PROGPATH=$(dirname "$0")
source $PROGPATH/env.sh

pbf_file="$1"
#MAPPING_YAML=openmaptiles/openmaptiles/build/mapping.yaml
MAPPING_YAML=build/mapping.yaml
UPDATE_SQL=build/update.sql

readonly PG_CONNECT="postgis: user=$POSTGRES_USER password=$POSTGRES_PASSWORD  host=$POSTGRES_HOST port=$POSTGRES_PORT dbname=$POSTGRES_DB"
echo $PG_CONNECT

mkdir -p "$IMPOSM_CACHE_DIR"

#(cd openmaptiles/openmaptiles && make)
./generate_mapping.py layers build

imposm3 import \
        -connection "$PG_CONNECT" \
        -mapping "$MAPPING_YAML" \
        -overwritecache \
        -cachedir "$IMPOSM_CACHE_DIR" \
        -read "$pbf_file" \
        -deployproduction \
        -write

# update sql
psql --echo-queries -v ON_ERROR_STOP=1 --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --dbname="$POSTGRES_DB" --username="$POSTGRES_USER" < "$UPDATE_SQL"
