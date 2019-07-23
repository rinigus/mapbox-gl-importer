DROP INDEX IF EXISTS osm_aerodrome_label_point_geom;

UPDATE osm_aerodrome_label_point
SET geometry = ST_Centroid(geometry)
WHERE ST_GeometryType(geometry) <> 'ST_Point';

UPDATE osm_aerodrome_label_point
SET
class = CASE
  WHEN aerodrome = 'international'
      OR aerodrome_type = 'international'
    THEN 'international'
  WHEN
      aerodrome = 'public'
      OR aerodrome_type LIKE '%public%'
      OR aerodrome_type = 'civil'
    THEN 'public'
  WHEN
      aerodrome = 'regional'
      OR aerodrome_type = 'regional'
    THEN 'regional'
  WHEN
      aerodrome = 'military'
      OR aerodrome_type LIKE '%military%'
      OR military = 'airfield'
    THEN 'military'
  WHEN
      aerodrome = 'private'
      OR aerodrome_type = 'private'
    THEN 'private'
  ELSE 'other'
END,
ele_ft = ele*3.2808399;

CREATE INDEX IF NOT EXISTS osm_aerodrome_label_point_geom ON osm_aerodrome_label_point USING gist(geometry);
CREATE INDEX IF NOT EXISTS osm_aerodrome_label_point_iata_idx ON osm_aerodrome_label_point USING gist(geometry) WHERE iata<>'';
CLUSTER osm_aerodrome_label_point USING osm_aerodrome_label_point_geom;
