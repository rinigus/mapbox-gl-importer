#!/bin/bash
set -e

PROGPATH=$(dirname "$0")
source $PROGPATH/env.sh

pbf_file="$1"
MAPPING_YAML=build/mapping.yaml
LAST_UPDATE_SQL=build/last_update.sql

readonly PG_CONNECT="postgis: user=$POSTGRES_USER password=$POSTGRES_PASSWORD  host=$POSTGRES_HOST port=$POSTGRES_PORT dbname=$POSTGRES_DB"
echo $PG_CONNECT

mkdir -p "$IMPOSM_CACHE_DIR"

./generate_mapping.py layers build

echo "DROP SCHEMA backup CASCADE;" | psql --echo-queries -v ON_ERROR_STOP=1 --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --dbname="$POSTGRES_DB" --username="$POSTGRES_USER" || true

imposm import \
       -connection "$PG_CONNECT" \
       -mapping "$MAPPING_YAML" \
       -overwritecache \
       -cachedir "$IMPOSM_CACHE_DIR" \
       -read "$pbf_file" \
       -deployproduction \
       -write

echo "DROP SCHEMA backup CASCADE;" | psql --echo-queries -v ON_ERROR_STOP=1 --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --dbname="$POSTGRES_DB" --username="$POSTGRES_USER" || true

#################################
# update sql

#psql --echo-queries -v ON_ERROR_STOP=1 --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --dbname="$POSTGRES_DB" --username="$POSTGRES_USER" < "$UPDATE_SQL"

#parallel --lb --halt now,fail=1 'cat {} | psql --echo-queries -v ON_ERROR_STOP=1 --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --dbname="$POSTGRES_DB" --username="$POSTGRES_USER"' ::: build/layer*sql
parallel --lb --halt now,fail=1 'cat {} | psql --echo-queries --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --dbname="$POSTGRES_DB" --username="$POSTGRES_USER"' ::: build/layer*sql

#################################
# handle large polygons in osm_landcover_processed_polygon
AREA="1e+10"
for table in osm_landcover_processed_polygon_z12 osm_landcover_processed_polygon_z13 osm_landcover_processed_polygon ; do
    echo Processing $table
    python split-large-polygons/split_large_polygons.py -t $table -c geometry -i row_id -a $AREA -s 3857
    echo "CLUSTER $table USING ${table}_geometry_idx;" | psql --echo-queries -v ON_ERROR_STOP=1 --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --dbname="$POSTGRES_DB" --username="$POSTGRES_USER"
    echo
done

psql --echo-queries -v ON_ERROR_STOP=1 --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --dbname="$POSTGRES_DB" --username="$POSTGRES_USER" < "$LAST_UPDATE_SQL"

