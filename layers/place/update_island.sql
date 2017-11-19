UPDATE osm_island_polygon SET geometry=ST_PointOnSurface(geometry) WHERE ST_GeometryType(geometry) <> 'ST_Point';
UPDATE osm_island_polygon SET "rank"=island_rank(area);
