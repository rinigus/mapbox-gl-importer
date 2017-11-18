#!/bin/bash
set -e

PROGPATH=$(dirname "$0")
source $PROGPATH/env.sh

cd $PROGPATH

./generate_layers.py layers build
./generate_vector_source.py build/layers.yaml "$EXPORT_DIR"/"$MBTILES_BASE_NAME"
mkdir -p "$EXPORT_DIR"
