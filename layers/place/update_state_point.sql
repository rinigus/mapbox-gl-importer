-- TODO: Maybe use population for it
UPDATE osm_state_point AS osm
SET "rank" = 1
WHERE "rank" = 0;
