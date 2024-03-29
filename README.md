# Mapbox GL tiles

Mapbox GL map import is based on [OpenMapTiles schema](https://github.com/openmaptiles/openmaptiles).

In contrast to OpenMapTiles approach, this import procedure does not require docker images and is using the directly accessible database. The imported tiles are split along zoom level 7 into global (zooms 0-6) and local (7-14) tiles. This is to simplify redistribution of the generated tiles and their usage in offline applications, such as [OSM Scout Server](https://rinigus.github.io/osmscout-server). Import can be done by GNU `make` allowing usage of parallel import jobs.

The overall import procedure is split into importing PBFs into the data source supported by Mapnik (such as PostGIS), generation of Mapnik XML used as a source for `tilelive-copy`, and running `tilelive-copy` to generate vector tiles and store them into MBTiles database. Thus, you would need to have `tilelive-copy` installed and in your path together with all other packages required for reading Mapnik source and storing MBTiles.

The scripts, including layer definitions, from OpenMapTiles repositories have been adjusted, if needed. All import is done in Linux, but similar approach could work on other platforms as well.

The import is described on the basis of PostGIS data source. Similar approach should work with other data sources supported by Mapnik.

## Dependencies

On a Debian-based distribution, at least the following dependencies were required:

```
sudo apt-get install postgis parallel python2.7 python-yaml libleveldb-dev libgeos-dev golang wget python-psycopg2 python-lxml python-jinja2 python-shapely npm nodejs
```

For npm installation, you may have to add `libssl1.0-dev` to the packages above.

In addition, the following packages have to be installed for tile generation in this directory:
```
npm install @mapbox/mbtiles @mapbox/tilelive @mapbox/tilelive-bridge
```

You may want to add corresponding PostgreSQL path into `PATH`, if its tools (createdb and oters) are not in the path already. For example, `/usr/lib/postgresql/10/bin`.

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

At the end of the import, `import_osm.sh` simplifies larger polygons in `osm_landcover_processed_polygon` table and its lower zoom variants. Simplification uses a script from https://github.com/rory/split-large-polygons . Corresponding script is a part of this repository and you should adjust `split-large-polygons/split_large_polygons.py` to load correct database (fill variable `connect_args` accordingly). Such simplification is expected to significantly increase the speed of import in such areas as Greenland.

* Make a link to the planet.pbf: `ln -s ../planet/planet-latest.osm.pbf .`

* Run: `./import_osm.sh planet-latest.osm.pbf`

## Vector tile generation

Vector tiles layers are defined using YAML configuration files that are scriptable using Jinja2 allowing to change definitions on the basis of the used zoom level, as given by ZLEVEL variable in the configuration files.

* Collect definition of layers into a single YAML under `build` sub-directory; generate Mapnik data source, layers definitions, and define destination of generated vector tiles (prefix for the created databases):
  ```
  ./prepare_vector_source.sh
  ```

There are two ways to generate vector tiles: using bash script or GNU make. The bash script allows to specify the additional parameters that will be passed to `tilelive-copy` as arguments. For example, bounding box and zoom levels could be specified allowing to generate vector tiles for specified coordinates into a single MBTiles file. GNU Makefile approach would generate vector tiles covering the planet by splitting the task into small sub-tasks. As a result, one can run several imports in parallel (`-j` option for `make`), stop the import and continue later with some loss of imported data due to interrupted jobs. It is suggested to use bash script for testing and make in production cases.

Its possible to limit the coverage of planet import by POLY files. For that, create a subfolder named `hierarchy`, as in https://github.com/rinigus/osmscout-server/tree/master/scripts/import/hierarchy and position POLY files under the subfolders of `hierarchy`. The vector tile source generation script `prepare_vector_source.sh` will read POLY files stored at `hierarchy` by walking through all subfolders and check each tile for intersection with at least one of the given polygons. To skip a polygon for some of the territories, add `ignore` file in the same subfolder. For example, one can just use hierarchy as provided in OSM Scout Server import scripts to exclude Antarctica and cover only the countries. 

The information regarding bash script path and make example are listed at the end of `./generate_vector_source.py` run (this script is executed as a part of `prepare_vector_source.sh`). While import using make is shown with the full command, for bash script only the path of the script is printed. An example usage for importing using the bash script:

```
bash build/layers/layers.xml-importer.sh --bounds="21,57,29,60" mbtiles://./tiles/world.mbtiles
```

## Profiling import

To be sure that the import goes well, its good to monitor it. For that, before import, reset statistics in PostGIS database after logging into it:

```
shell # psql --echo-queries -h `pwd`/pg-socket -p 35432 osm
psql> select pg_stat_statements_reset();
```

(adjust psql command line parameters as appropriate). After that, check the stats

```
select calls, total_time, query from pg_stat_statements order by total_time desc limit 10
```

In normal operation, transportation layer should be using most of the postgres query time. When something is wrong, postgres starts using most of CPU, not node processes. In one of the  imports, looks like osm_landuse tables were not clustered that well. After performing new cluster statement for these tables + vacuum analyze, all started working quite fast.

