
-- etldoc: layer_mountain_peak[shape=record fillcolor=lightpink,
-- etldoc:     style="rounded,filled", label="layer_mountain_peak | <z7_> z7+" ] ;

CREATE OR REPLACE FUNCTION layer_mountain_peak(bbox geometry, zoom_level integer, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, ele int, ele_ft int, "rank" int) AS $$
   -- etldoc: osm_peak_point -> layer_mountain_peak:z7_
   SELECT osm_id, geometry, name, name_en, ele::int, ele_ft::int, rank::int
   FROM (
     SELECT osm_id, geometry, name,
     COALESCE(NULLIF(name_en, ''), name) AS name_en,
     ele, ele_ft,
       row_number() OVER (
           PARTITION BY LabelGrid(geometry, 100 * pixel_width)
           ORDER BY (rank_points) DESC
       )::int AS "rank"
     FROM osm_peak_point
     WHERE geometry && bbox
   ) AS ranked_peaks
   WHERE zoom_level >= 7 AND (rank <= 5 OR zoom_level >= 14)
   ORDER BY "rank" ASC;

$$ LANGUAGE SQL IMMUTABLE;
