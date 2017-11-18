#!/bin/bash
set -e

PROGPATH=$(dirname "$0")
source $PROGPATH/env.sh

cd $PROGPATH

wget -O pgfutter https://github.com/lukasmartinelli/pgfutter/releases/download/v1.1/pgfutter_linux_amd64
chmod +x pgfutter

rm -f postgis-vt-util.sql
wget https://raw.githubusercontent.com/mapbox/postgis-vt-util/v1.0.0/postgis-vt-util.sql

mkdir -p $GOPATH
go get github.com/omniscale/imposm3
go install github.com/omniscale/imposm3/cmd/imposm3
