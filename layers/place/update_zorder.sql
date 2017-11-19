UPDATE osm_city_point SET
z_order=CASE
WHEN place = 'city' THEN 6
WHEN place = 'region' THEN 8
WHEN place = 'county' THEN 7
ELSE -1
END;

UPDATE osm_place_other_point SET
z_order=CASE
WHEN place = 'hamlet' THEN 3
WHEN place = 'suburb' THEN 2
WHEN place = 'neighbourhood' THEN 1
ELSE 0
END;
