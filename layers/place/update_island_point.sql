UPDATE osm_island_point SET geometry=ST_PointOnSurface(geometry) WHERE ST_GeometryType(geometry) <> 'ST_Point';
