#!/bin/bash

set -e

PROGPATH=$(dirname "$0")
source $PROGPATH/env.sh

createdb --host=$POSTGRES_HOST --port=$POSTGRES_PORT --user=$POSTGRES_USER $POSTGRES_DB

psql --host=$POSTGRES_HOST --port=$POSTGRES_PORT --user=$POSTGRES_USER --dbname="$POSTGRES_DB" <<-'EOSQL'
    CREATE EXTENSION postgis;
    CREATE EXTENSION hstore;
    CREATE EXTENSION unaccent;
    CREATE EXTENSION fuzzystrmatch;
EOSQL
