DROP INDEX osm_island_polygon_geom;

UPDATE osm_island_polygon SET geometry=ST_PointOnSurface(geometry) WHERE ST_GeometryType(geometry) <> 'ST_Point';
UPDATE osm_island_polygon SET "rank"=island_rank(area);

CREATE INDEX IF NOT EXISTS osm_island_polygon_geom ON osm_island_polygon USING gist(geometry);
