-- drop all areas with too small or no area
DELETE FROM osm_park_polygon WHERE area IS NULL OR area < 1;

-- CLUSTER all larger datasets
CLUSTER osm_park_polygon USING osm_park_polygon_geom;
CLUSTER osm_park_polygon_z13 USING osm_park_polygon_z13_geom;
CLUSTER osm_park_polygon_z12 USING osm_park_polygon_z12_geom;
