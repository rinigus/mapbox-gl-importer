DROP TABLE IF EXISTS osm_landcover_processed_polygon CASCADE;

CREATE TABLE osm_landcover_processed_polygon AS (
  SELECT osm_id, geometry,
    CASE
    WHEN landuse IN ('farmland', 'farm', 'orchard', 'vineyard', 'plant_nursery') THEN 'farmland'
    WHEN "natural" IN ('glacier', 'ice_shelf') THEN 'ice'
    WHEN "natural"='wood' OR landuse IN ('forest') THEN 'wood'
    WHEN "natural" IN ('bare_rock', 'scree') THEN 'rock'
    WHEN "natural"='grassland'
        OR landuse IN ('grass', 'meadow', 'allotments', 'grassland',
            'park', 'village_green', 'recreation_ground')
        OR leisure IN ('park', 'garden')
    THEN 'grass'
    WHEN "natural"='wetland' OR wetland IN ('bog', 'swamp', 'wet_meadow', 'marsh', 'reedbed', 'saltern', 'tidalflat', 'saltmarsh', 'mangrove') THEN 'wetland'
    ELSE NULL
    END AS class,
    COALESCE(
      NULLIF("natural", ''), NULLIF(landuse, ''),
      NULLIF(leisure, ''), NULLIF(wetland, '')
    ) AS subclass, area
    FROM osm_landcover_polygon
);

DROP TABLE IF EXISTS  osm_landcover_processed_polygon_z13 CASCADE;
DROP TABLE IF EXISTS  osm_landcover_processed_polygon_z12 CASCADE;
DROP TABLE IF EXISTS  osm_landcover_processed_polygon_z11 CASCADE;
DROP TABLE IF EXISTS  osm_landcover_processed_polygon_z10 CASCADE;
DROP TABLE IF EXISTS  osm_landcover_processed_polygon_z9 CASCADE;
DROP TABLE IF EXISTS  osm_landcover_processed_polygon_z8 CASCADE;
DROP TABLE IF EXISTS  osm_landcover_processed_polygon_z7 CASCADE;
DROP TABLE IF EXISTS  osm_landcover_processed_polygon_z6 CASCADE;
DROP TABLE IF EXISTS  osm_landcover_processed_polygon_z5 CASCADE;

CREATE TABLE osm_landcover_processed_polygon_z13 AS (SELECT * FROM osm_landcover_processed_polygon WHERE area > ZAREA13);
UPDATE osm_landcover_processed_polygon_z13 SET geometry = ST_SimplifyPreserveTopology(geometry, ZTOL13);

CREATE TABLE osm_landcover_processed_polygon_z12 AS (SELECT * FROM osm_landcover_processed_polygon WHERE area > ZAREA12);
UPDATE osm_landcover_processed_polygon_z12 SET geometry = ST_SimplifyPreserveTopology(geometry, ZTOL12);

CREATE TABLE osm_landcover_processed_polygon_z11 AS (SELECT * FROM osm_landcover_processed_polygon WHERE area > ZAREA11);
UPDATE osm_landcover_processed_polygon_z11 SET geometry = ST_SimplifyPreserveTopology(geometry, ZTOL11);

CREATE TABLE osm_landcover_processed_polygon_z10 AS (SELECT * FROM osm_landcover_processed_polygon WHERE area > ZAREA10);
UPDATE osm_landcover_processed_polygon_z10 SET geometry = ST_SimplifyPreserveTopology(geometry, ZTOL10);

CREATE TABLE osm_landcover_processed_polygon_z9 AS (SELECT * FROM osm_landcover_processed_polygon WHERE area > ZAREA9);
UPDATE osm_landcover_processed_polygon_z9 SET geometry = ST_SimplifyPreserveTopology(geometry, ZTOL9);

CREATE TABLE osm_landcover_processed_polygon_z8 AS (SELECT * FROM osm_landcover_processed_polygon WHERE area > ZAREA8);
UPDATE osm_landcover_processed_polygon_z8 SET geometry = ST_SimplifyPreserveTopology(geometry, ZTOL8);

CREATE TABLE osm_landcover_processed_polygon_z7 AS (SELECT * FROM osm_landcover_processed_polygon WHERE area > ZAREA7);
UPDATE osm_landcover_processed_polygon_z7 SET geometry = ST_SimplifyPreserveTopology(geometry, ZTOL7);

CREATE TABLE osm_landcover_processed_polygon_z6 AS (SELECT * FROM osm_landcover_processed_polygon WHERE area > ZAREA6);
UPDATE osm_landcover_processed_polygon_z6 SET geometry = ST_SimplifyPreserveTopology(geometry, ZTOL6);

CREATE TABLE osm_landcover_processed_polygon_z5 AS (SELECT * FROM osm_landcover_processed_polygon WHERE area > ZAREA5);
UPDATE osm_landcover_processed_polygon_z5 SET geometry = ST_SimplifyPreserveTopology(geometry, ZTOL5);

-- indexes
CREATE INDEX IF NOT EXISTS osm_landcover_processed_polygon_geometry_idx ON osm_landcover_processed_polygon USING gist (geometry);

CREATE INDEX IF NOT EXISTS osm_landcover_processed_polygon_z13_geometry_idx ON osm_landcover_processed_polygon_z13 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_landcover_processed_polygon_z12_geometry_idx ON osm_landcover_processed_polygon_z12 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_landcover_processed_polygon_z11_geometry_idx ON osm_landcover_processed_polygon_z11 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_landcover_processed_polygon_z10_geometry_idx ON osm_landcover_processed_polygon_z10 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_landcover_processed_polygon_z9_geometry_idx ON osm_landcover_processed_polygon_z9 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_landcover_processed_polygon_z8_geometry_idx ON osm_landcover_processed_polygon_z8 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_landcover_processed_polygon_z7_geometry_idx ON osm_landcover_processed_polygon_z7 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_landcover_processed_polygon_z6_geometry_idx ON osm_landcover_processed_polygon_z6 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_landcover_processed_polygon_z5_geometry_idx ON osm_landcover_processed_polygon_z5 USING gist (geometry);
