DELETE FROM osm_peak_point WHERE ele is null;

UPDATE osm_peak_point SET
ele_ft = ele*3.2808399,
rank_points = ele +
  (CASE WHEN NULLIF(wikipedia, '') is not null THEN 10000 ELSE 0 END) +
  (CASE WHEN NULLIF(name, '') is not null THEN 10000 ELSE 0 END);
