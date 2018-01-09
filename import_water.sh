#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

PROGPATH=$(dirname "$0")
source $PROGPATH/env.sh

readonly WATER_POLYGONS_FILE="$IMPORT_DATA_DIR/water_polygons.shp"
readonly SIMPLIFIED_WATER_POLYGONS_FILE="$IMPORT_DATA_DIR/simplified_water_polygons.shp"

function exec_psql() {
    PGPASSWORD=$POSTGRES_PASSWORD psql --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --dbname="$POSTGRES_DB" --username="$POSTGRES_USER"
}

function import_shp() {
    local shp_file=$1
    local table_name=$2
    shp2pgsql -s 3857 -I -g geometry "$shp_file" "$table_name" | exec_psql | hide_inserts
}

function hide_inserts() {
    grep -v "INSERT 0 1"
}

function drop_table() {
    local table=$1
    local drop_command="DROP TABLE IF EXISTS $table;"
    echo "$drop_command" | exec_psql
}

function generalize_water() {
    local target_table_name="$1"
    local source_table_name="$2"
    local tolerance="$3"
    echo "Generalize $target_table_name with tolerance $tolerance from $source_table_name"
    echo "CREATE TABLE $target_table_name AS SELECT ST_Simplify(geometry, $tolerance) AS geometry FROM $source_table_name" | exec_psql
    echo "CREATE INDEX ${target_table_name}_geom ON $target_table_name USING gist (geometry)" | exec_psql
    echo "CLUSTER $target_table_name USING ${target_table_name}_geom" | exec_psql
    echo "ANALYZE $target_table_name" | exec_psql
}

function import_simple_water() {
    local table_name="osm_ocean_simplified_polygon"
    drop_table "$table_name"
    import_shp "$SIMPLIFIED_WATER_POLYGONS_FILE" "$table_name"
}

function import_water() {
    local table_name="osm_ocean_polygon"
    drop_table "$table_name"
    import_shp "$WATER_POLYGONS_FILE" "$table_name"

    local gen1_table_name="osm_ocean_polygon_z12"
    drop_table "$gen1_table_name"
    generalize_water "$gen1_table_name" "$table_name" 20

    local gen2_table_name="osm_ocean_polygon_z11"
    drop_table "$gen2_table_name"
    generalize_water "$gen2_table_name" "$table_name" 40

    local gen3_table_name="osm_ocean_polygon_z10"
    drop_table "$gen3_table_name"
    generalize_water "$gen3_table_name" "$table_name" 80
}

import_simple_water
import_water
