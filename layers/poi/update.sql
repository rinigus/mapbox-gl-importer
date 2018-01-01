DROP INDEX IF EXISTS osm_poi_point_geom;

-- Load polygons into point while changing the geometry to point
INSERT INTO osm_poi_point
(osm_id, geometry, name, name_en, aerialway, amenity, barrier, building,
highway, historic, landuse, leisure, man_made, railway, religion, shop, sport, station,
tourism, waterway)
SELECT osm_id, 
  CASE WHEN ST_NPoints(ST_ConvexHull(geometry))=ST_NPoints(geometry) THEN ST_Centroid(geometry)
  ELSE ST_PointOnSurface(geometry)
  END AS geometry,
  name, name_en, aerialway, amenity, barrier, building,
highway, historic, landuse, leisure, man_made, railway, religion, shop, sport, station,
tourism, waterway FROM osm_poi_polygon
WHERE NOT EXISTS (
      SELECT 'X' FROM osm_poi_point WHERE osm_poi_polygon.osm_id=osm_poi_point.osm_id);


-- determine class, symbol, and zlevel
UPDATE osm_poi_point SET
"class" = CASE
WHEN amenity IN ('clinic', 'dentist', 'doctors', 'hospital', 'nursing_home', 'pharmacy', 'veterinary') THEN 'health'
WHEN amenity IN ('arts_centre', 'cinema', 'theatre') OR tourism IN ('artwork', 'gallery') THEN 'art'
WHEN amenity IN ('bar', 'bbq', 'biergarten', 'cafe', 'fast_food', 'food_court', 'ice_cream', 'pub', 'restaurant') THEN 'restaurant'
WHEN amenity IN ('bicycle_rental', 'bus_station', 'car_rental', 'ferry_terminal', 'taxi') OR
                 highway IN ('bus_stop') OR
                 railway <> ''
                 THEN 'transport'
WHEN amenity IN ('charging_station', 'fuel', 'parking') THEN 'car'
WHEN amenity IN ('college', 'kindergarten', 'school', 'university') OR
                  building IN ('college', 'kindergarten', 'school', 'university')
                  THEN 'school'
WHEN amenity IN ('bank', 'community_centre', 'courthouse', 'embassy', 'fire_station', 'grave_yard', 'library', 'place_of_worship', 
                 'post_office', 'ranger_station', 'recycling', 'shelter', 'telephone', 'toilets', 'townhall') OR
                 historic IN ('castle', 'monument') OR
                 landuse IN ('basin', 'cemetery', 'reservoir') OR
                 leisure IN ('dog_park', 'garden', 'marina', 'park', 'playground', 'water_park') OR
                 man_made IN ('lighthouse') OR
                 -- churches should be included via place_of_worship, religion is not needed separately
                 tourism IN ('attraction', 'aquarium', 'information', 'museum', 'picnic_site', 'theme_park', 'viewpoint', 'zoo') OR
                 waterway <> ''
                 THEN 'public'
WHEN amenity IN ('police', 'prison') OR barrier IN ('border_control') THEN 'police'
WHEN amenity IN ('marketplace') OR shop <> '' THEN 'shop'
WHEN amenity IN ('swimming_pool') OR leisure IN ('golf_course', 'ice_rink', 'miniature_golf', 'pitch', 'sports_centre', 'stadium',
                 'swimming_area', 'swimming_pool' ) OR
                 sport <> ''
                 THEN 'sport'
WHEN tourism IN ('alpine_hut', 'bed_and_breakfast', 'camp_site', 'caravan_site', 'chalet',
                  'guest_house', 'hostel', 'hotel', 'motel') THEN 'lodging'
ELSE NULL END,

symbol = CASE
WHEN amenity IN ('arts_centre') OR tourism IN ('artwork', 'gallery') THEN 'art_gallery'
WHEN amenity IN ('biergarten', 'pub') THEN 'beer'
WHEN amenity IN ('bus_station') OR highway IN ('bus_stop') THEN 'bus'
WHEN amenity IN ('car_rental', 'taxi') THEN 'car'
WHEN amenity IN ('clinic') THEN 'hospital'
WHEN amenity IN ('ferry_terminal') THEN 'ferry'
WHEN amenity IN ('food_court') THEN 'fast_food'
WHEN amenity IN ('grave_yard') OR landuse IN ('cemetery') THEN 'cemetery'
WHEN amenity IN ('kindergarten') OR building IN ('kindergarten') THEN 'playground'
WHEN amenity IN ('marketplace') THEN 'shop'
WHEN amenity IN ('post_office') THEN 'post'
WHEN amenity IN ('swimming_pool') OR leisure IN ('swimming_area', 'swimming_pool', 'water_park') THEN 'swimming'
WHEN amenity IN ('university') OR building IN ('university') THEN 'college'
WHEN amenity='place_of_worship' AND religion IN ('buddhist', 'christian', 'jewish', 'muslim') THEN 'religious_' || religion
WHEN barrier IN ('border_control') THEN 'barrier'
WHEN amenity IN ('bank', 'bar', 'bbq', 'bicycle_rental', 'cafe', 'charging_station', 'cinema', 'college',
                 'community_centre', 'courthouse', 'dentist', 'doctors', 'embassy', 'fast_food', 'fire_station',
                 'fuel', 'hospital', 'ice_cream', 'library', 'parking', 'pharmacy', 'place_of_worship', 'police',
                 'prison', 'ranger_station', 'recycling', 'restaurant', 'school', 'shelter', 'telephone', 'theatre', 'toilets',
                 'townhall', 'veterinary') THEN amenity
WHEN building IN ('college', 'school') THEN building
WHEN historic IN ('castle', 'monument') THEN historic
WHEN leisure IN ('golf_course', 'miniature_golf') THEN 'golf'
WHEN leisure IN ('dog_park', 'garden', 'park', 'pitch', 'playground', 'stadium') THEN leisure
WHEN man_made IN ('lighthouse') THEN man_made
WHEN railway IN ('station', 'halt') THEN 'rail'
WHEN railway IN ('tram_stop') THEN 'rail_light'
WHEN shop IN ('supermarket', 'butcher') THEN 'shop'
WHEN shop IN ('alcohol', 'beverages', 'wine') THEN 'shop_alcohol'
WHEN shop IN ('bicycle') THEN 'bicycle_rental'
WHEN shop IN ('books') THEN 'library'
WHEN shop IN ('doityourself', 'hardware') THEN 'shop_diy'
WHEN shop IN ('fishmonger') THEN 'shop_seafood'
WHEN shop IN ('ice_cream') THEN 'ice_cream'
WHEN shop IN ('art', 'bag', 'bakery', 'clothes', 'coffee', 'convenience', 'deli', 'department_store', 
              'florist', 'garden_centre', 'gift', 'hairdresser', 'laundry', 'music', 'pet', 'seafood',
              'toys', 'sports') THEN 'shop_' || shop
WHEN sport IN ('cycling') THEN 'bicycle'
WHEN sport IN ('horse_racing') THEN 'horse_riding'
WHEN sport IN ('american_football', 'baseball', 'basketball', 'cricket', 'golf',
               'skiing', 'soccer', 'swimming', 'tennis' ) THEN sport
WHEN tourism IN ('alpine_hut') THEN 'shelter'
WHEN tourism IN ('bed_and_breakfast', 'guest_house', 'hostel', 'hotel', 'motel') THEN 'lodging'
WHEN tourism IN ('caravan_site') THEN 'camp_site'
WHEN tourism IN ('chalet') THEN 'home'
WHEN tourism IN ('gallery') THEN 'art_gallery'
WHEN tourism IN ('attraction', 'aquarium', 'camp_site', 'information', 'museum', 'picnic_site', 'zoo') THEN tourism

-- specified cases without symbols
WHEN amenity IN ('nursing_home') OR landuse IN ('basin', 'reservoir', 'sports_centre') OR
     leisure IN ('ice_rink', 'marina') THEN 'dot'

-- everything else
ELSE 'dot' END;

-- Delete rows that don't have special symbol nor name
DELETE FROM osm_poi_point WHERE "class" IS NULL OR (symbol='dot' AND ((name <> '') IS NOT TRUE));

-- Set rank
UPDATE osm_poi_point SET
rank = CASE
WHEN symbol IN ('hospital') THEN 13
WHEN symbol IN ('townhall', 'fire_station') THEN 14
WHEN symbol IN ('college', 'police', 'bank') OR amenity IN ('taxi') OR barrier IN ('border_control') THEN 15
ELSE 99 END;

-- Update geometry
-- UPDATE osm_poi_point
-- SET
-- class = poi_class(subclass, mapping_key),
-- "rank" = poi_class_rank(class);

CREATE INDEX IF NOT EXISTS osm_poi_point_geom ON osm_poi_point USING gist(geometry);
