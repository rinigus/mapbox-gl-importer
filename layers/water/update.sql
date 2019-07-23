DROP TABLE IF EXISTS  osm_water_point CASCADE;

CREATE TABLE osm_water_point AS (
  SELECT osm_id, ST_PointOnSurface(geometry) AS geometry, name,
  COALESCE(NULLIF(name_en, ''), name) AS name_en,
  CASE WHEN waterway='' AND water<>'river' THEN 'lake' ELSE 'river' END AS class,
  CASE
  WHEN area>6553600000 THEN 7
  WHEN area>1638400000 THEN 8
  WHEN area>409600000 THEN 9
  WHEN area>102400000 THEN 10
  WHEN area>25600000 THEN 11
  WHEN area>6400000 THEN 12
  WHEN area>1600000 THEN 13
  WHEN area>320000 THEN 14
  WHEN area>80000 THEN 15
  WHEN area>20000 THEN 16
  WHEN area>5000 THEN 17
  ELSE 18 END
  AS rank, area
  FROM osm_water_polygon
  WHERE name<>'' AND ST_IsValid(geometry) AND area > 25000
  UNION ALL
  SELECT osm_id, geometry, name,
  COALESCE(NULLIF(name_en, ''), name) AS name_en,
  place AS class,
  18 AS rank, NULL AS area
  FROM osm_marine_point
  WHERE name<>''
);

DROP TABLE IF EXISTS  osm_water_point_z13 CASCADE;
DROP TABLE IF EXISTS  osm_water_point_z12 CASCADE;
DROP TABLE IF EXISTS  osm_water_point_z11 CASCADE;
DROP TABLE IF EXISTS  osm_water_point_z10 CASCADE;
DROP TABLE IF EXISTS  osm_water_point_z9 CASCADE;
DROP TABLE IF EXISTS  osm_water_point_z8 CASCADE;
DROP TABLE IF EXISTS  osm_water_point_z7 CASCADE;

CREATE TABLE osm_water_point_z13 AS (SELECT * FROM osm_water_point WHERE class IN ('sea', 'ocean') OR area > 50000);
CREATE TABLE osm_water_point_z12 AS (SELECT * FROM osm_water_point WHERE class IN ('sea', 'ocean') OR area > 100000);
CREATE TABLE osm_water_point_z11 AS (SELECT * FROM osm_water_point WHERE class IN ('sea', 'ocean') OR area > 400000);
CREATE TABLE osm_water_point_z10 AS (SELECT * FROM osm_water_point WHERE class IN ('sea', 'ocean') OR area > 1600000);
CREATE TABLE osm_water_point_z9 AS (SELECT * FROM osm_water_point WHERE class IN ('sea', 'ocean') OR area > 6400000);
CREATE TABLE osm_water_point_z8 AS (SELECT * FROM osm_water_point WHERE class IN ('sea', 'ocean') OR area > 25600000);
CREATE TABLE osm_water_point_z7 AS (SELECT * FROM osm_water_point WHERE class IN ('sea', 'ocean') OR area > 102400000);

-- indexes
CREATE INDEX IF NOT EXISTS osm_water_point_geometry_idx ON osm_water_point USING gist (geometry);

CREATE INDEX IF NOT EXISTS osm_water_point_z13_geometry_idx ON osm_water_point_z13 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_water_point_z12_geometry_idx ON osm_water_point_z12 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_water_point_z11_geometry_idx ON osm_water_point_z11 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_water_point_z10_geometry_idx ON osm_water_point_z10 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_water_point_z9_geometry_idx ON osm_water_point_z9 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_water_point_z8_geometry_idx ON osm_water_point_z8 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_water_point_z7_geometry_idx ON osm_water_point_z7 USING gist (geometry);

CLUSTER osm_ocean_polygon USING osm_ocean_polygon_geometry_idx;
CLUSTER osm_water_polygon USING osm_water_polygon_geom;
