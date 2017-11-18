-- todo change to something similar to mapnik import and use population in style
UPDATE osm_country_point AS osm
SET "rank" = 6
WHERE "rank" IS NULL;
