DROP INDEX IF EXISTS osm_housenumber_point_geom;

UPDATE osm_housenumber_point
SET geometry =
  CASE WHEN ST_NPoints(ST_ConvexHull(geometry))=ST_NPoints(geometry)
  THEN ST_Centroid(geometry)
  ELSE ST_PointOnSurface(geometry)
  END
WHERE ST_IsValid(geometry) AND ST_GeometryType(geometry) <> 'ST_Point';

CREATE INDEX IF NOT EXISTS osm_housenumber_point_geom ON osm_housenumber_point USING gist(geometry);
CLUSTER osm_housenumber_point USING osm_housenumber_point_geom;
