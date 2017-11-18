UPDATE osm_aerodrome_label_point
SET geometry = ST_Centroid(geometry)
WHERE ST_GeometryType(geometry) <> 'ST_Point';
