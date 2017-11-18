# Mapbox GL tiles

Mapbox GL map import is based on [OpenMapTiles schema](https://github.com/openmaptiles/openmaptiles).

In contrast to OpenMapTiles approach, this import procedure does not require docker images and is using the directly accessible database. The imported tiles are split along zoom level 7 into global (zooms 0-6) and local (7-14) tiles. This is to simplify redistribution of the generated tiles and their usage in offline applications, such as [OSM Scout Server](https://rinigus.github.io/osmscout-server). Import can be done by GNU `make` allowing usage of parallel import jobs.

The overall import procedure is split into importing PBFs into the data source supported by Mapnik (such as PostGIS), generation of Mapnik XML used as a source by `tilelive-copy`, and running `tilelive-copy` to generate vector tiles and store them into MBTiles database. Thus, you would need to have `tilelive-copy` installed and in your path together with all other packages required for reading Mapnik source and storing MBTiles.

The scripts, including layer definitions, from OpenMapTiles repositories have been adjusted, if needed. All import is done in Linux, but similar approach could work on other platforms as well.

The import is described on the basis of PostGIS data source. Similar approach should work with other data sources supported by Mapnik.

## Preparation of PostGIS database

Install PostgreSQL, PostGIS using your distribution.

To initialize local PostGIS database:

* In this directory, run to create database storage space (or replace current directory argument with something else where you have space): ```initdb `pwd`/db```

* Create socket directory, here subdirectory is used for that: ```mkdir `pwd`/pg-socket```

* Edit socket directory setting in `db/postgresql.conf` by adjusting
  * `unix_socket_directories` should point to the created socket directory
  * `port` for your PostgreSQL instance should be adjusted

* If you wish, adjust security settings in `db/pg_hba.conf`

* Start PostgreSQL: ```postgres -D `pwd`/db```

* Copy `env.sh-template` to `env.sh` and adjust environment variables in `env.sh`

* Create the database by running `./create_database.sh`

## Obtaining the required programs

There are several programs that are used during import and are possibly not available in a general Linux distributions. To get the corresponding tools, run `prepare_tools.sh`

## Obtaining the data

In addition to Planet OSM, there are several other datasets used in generation of the tiles. Run `prepare_datasets.sh` to get the datasets.

## Importing additional data into PostGIS

* Run: `./import_datasets.sh` . This is for importing coastlines, borders, and other data that is not coming from Planet PBF.

* Run `./prepare_sql.sh` to define additional helper functions.

## Importing Planet.PBF into PostGIS

Importing Planet.PBF goes through [imposm3](https://github.com/omniscale/imposm3) and requires definition of the layers. These layers are defined together with vector tile layers under `layers` sub-directory. During the import, the script generates imposm3 layers mapping and SQL script that is run after the import to prepare the data for vector tile generation.

* Make a link to the planet.pbf: `ln -s ../planet/planet-latest.osm.pbf .`

* Run: `./import_osm.sh planet-latest.osm.pbf`

## Vector tile generation

Vector tiles layers are defined using YAML configuration files that are scriptable using Jinja2 allowing to change definitions on the basis of the used zoom level, as given by ZLEVEL variable in the configuration files.

* Collect definition of layers into a single YAML under `build` sub-directory; generate Mapnik data source, layers definitions, and define destination of generated vector tiles (prefix for the created databases):
  ```
  ./prepare_vector_source.sh
  ```

There are two ways to generate vector tiles: using bash script or GNU make. The bash script allows to specify the additional parameters that will be passed to `tilelive-copy` as arguments. For example, bounding box and zoom levels could be specified allowing to generate vector tiles for specified coordinates into a single MBTiles file. GNU Makefile approach would generate vector tiles covering the planet by splitting the task into small sub-tasks. As a result, one can run several imports in parallel (`-j` option for `make`), stop the import and continue later with some loss of imported data due to interrupted jobs. It is suggested to use bash script for testing and make in production cases.

The information regarding bash script path and make example are listed at the end of `./generate_vector_source.py` run (this script is executed as a part of `prepare_vector_source.sh`). While import using make is shown with the full command, for bash script only the path of the script is printed. An example usage for importing using the bash script:

```
bash build/layers/layers.xml-importer.sh --bounds="21,57,29,60" mbtiles://./tiles/world.mbtiles
```
