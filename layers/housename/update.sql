UPDATE osm_housename_point
SET geometry =
  CASE WHEN ST_NPoints(ST_ConvexHull(geometry))=ST_NPoints(geometry)
  THEN ST_Centroid(geometry)
  ELSE ST_PointOnSurface(geometry)
  END
WHERE ST_GeometryType(geometry) <> 'ST_Point';
