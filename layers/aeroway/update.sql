DELETE FROM osm_aeroway_polygon WHERE area IS NULL OR area < 1;

CLUSTER osm_aeroway_polygon USING osm_aeroway_polygon_geom;

