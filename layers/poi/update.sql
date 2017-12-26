CREATE OR REPLACE FUNCTION poi_class_rank(class TEXT)
RETURNS INT AS $$
    SELECT CASE class
        WHEN 'hospital' THEN 20
        WHEN 'park' THEN 25
        WHEN 'cemetery' THEN 30
        WHEN 'railway' THEN 40
        WHEN 'bus' THEN 50
        WHEN 'attraction' THEN 70
        WHEN 'harbor' THEN 75
        WHEN 'college' THEN 80
        WHEN 'school' THEN 85
        WHEN 'stadium' THEN 90
        WHEN 'zoo' THEN 95
        WHEN 'town_hall' THEN 100
        WHEN 'campsite' THEN 110
        WHEN 'cemetery' THEN 115
        WHEN 'park' THEN 120
        WHEN 'library' THEN 130
        WHEN 'police' THEN 135
        WHEN 'post' THEN 140
        WHEN 'golf' THEN 150
        WHEN 'shop' THEN 400
        WHEN 'grocery' THEN 500
        WHEN 'fast_food' THEN 600
        WHEN 'clothing_store' THEN 700
        WHEN 'bar' THEN 800
        ELSE 1000
    END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION poi_class(subclass TEXT, mapping_key TEXT)
RETURNS TEXT AS $$
    SELECT CASE
        WHEN subclass IN ('accessories','antiques','art','beauty','bed','boutique','camera','carpet','charity','chemist','chocolate','coffee','computer','confectionery','convenience','copyshop','cosmetics','garden_centre','doityourself','erotic','electronics','fabric','florist','furniture','video_games','video','general','gift','hardware','hearing_aids','hifi','ice_cream','interior_decoration','jewelry','kiosk','lamps','mall','massage','motorcycle','mobile_phone','newsagent','optician','outdoor','perfumery','perfume','pet','photo','second_hand','shoes','sports','stationery','tailor','tattoo','ticket','tobacco','toys','travel_agency','watches','weapons','wholesale') THEN 'shop'
        WHEN subclass IN ('townhall','public_building','courthouse','community_centre') THEN 'town_hall'
        WHEN subclass IN ('golf','golf_course','miniature_golf') THEN 'golf'
        WHEN subclass IN ('fast_food','food_court') THEN 'fast_food'
        WHEN subclass IN ('park','bbq') THEN 'park'
        WHEN subclass IN ('bus_stop','bus_station') THEN 'bus'
        -- because 'station' might be from both aeroway and railway
        WHEN (subclass='station' AND mapping_key = 'railway') OR subclass IN ('halt', 'tram_stop', 'subway') THEN 'railway'
        WHEN subclass IN ('camp_site','caravan_site') THEN 'campsite'
        WHEN subclass IN ('laundry','dry_cleaning') THEN 'laundry'
        WHEN subclass IN ('supermarket','deli','delicatessen','department_store','greengrocer','marketplace') THEN 'grocery'
        WHEN subclass IN ('books','library') THEN 'library'
        WHEN subclass IN ('university','college') THEN 'college'
        WHEN subclass IN ('hotel','motel','bed_and_breakfast','guest_house','hostel','chalet','alpine_hut','camp_site') THEN 'lodging'
        WHEN subclass IN ('chocolate','confectionery') THEN 'ice_cream'
        WHEN subclass IN ('post_box','post_office') THEN 'post'
        WHEN subclass IN ('cafe') THEN 'cafe'
        WHEN subclass IN ('school','kindergarten') THEN 'school'
        WHEN subclass IN ('alcohol','beverages','wine') THEN 'alcohol_shop'
        WHEN subclass IN ('bar','nightclub') THEN 'bar'
        WHEN subclass IN ('marina','dock') THEN 'harbor'
        WHEN subclass IN ('car','car_repair','taxi') THEN 'car'
        WHEN subclass IN ('hospital','nursing_home', 'doctors', 'clinic') THEN 'hospital'
        WHEN subclass IN ('grave_yard','cemetery') THEN 'cemetery'
        WHEN subclass IN ('attraction','viewpoint') THEN 'attraction'
        WHEN subclass IN ('biergarten','pub') THEN 'beer'
        WHEN subclass IN ('music','musical_instrument') THEN 'music'
        WHEN subclass IN ('american_football','stadium','soccer','pitch') THEN 'stadium'
        WHEN subclass IN ('accessories','antiques','art','artwork','gallery','arts_centre') THEN 'art_gallery'
        WHEN subclass IN ('bag','clothes') THEN 'clothing_store'
        WHEN subclass IN ('swimming_area','swimming') THEN 'swimming'
        ELSE subclass
    END;
$$ LANGUAGE SQL IMMUTABLE;

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
WHEN amenity IN ('bank') THEN 'bank'
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
                 'post_office', 'shelter', 'telephone', 'toilets', 'townhall') OR
                 historic IN ('monument') OR
                 landuse IN ('basin', 'cemetery', 'reservoir') OR
                 leisure IN ('dog_park', 'garden', 'marina', 'park', 'playground', 'water_park') OR
                 man_made IN ('lighthouse') OR
                 -- churches should be included via place_of_worship, religion is not needed separately
                 tourism IN ('attraction', 'information', 'museum', 'picnic_site', 'theme_park', 'viewpoint', 'zoo') OR
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
WHEN amenity='place_of_worship' AND religion IN ('christian', 'jewish', 'muslim') THEN 'religious_' || religion
WHEN barrier IN ('border_control') THEN 'police'
WHEN amenity IN ('bank', 'bar', 'bbq', 'bicycle_rental', 'cafe', 'charging_station', 'cinema', 'college',
                 'community_centre', 'courthouse', 'dentist', 'doctors', 'embassy', 'fast_food', 'fire_station',
                 'fuel', 'hospital', 'ice_cream', 'library', 'parking', 'pharmacy', 'place_of_worship', 'police',
                 'prison', 'restaurant', 'school', 'shelter', 'telephone', 'theatre', 'toilets',
                 'townhall', 'veterinary') THEN amenity
WHEN building IN ('college', 'school') THEN building
WHEN historic IN ('monument') THEN historic
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
WHEN shop IN ('fishmonger', 'seafood') THEN 'shop_seafood'
WHEN shop IN ('ice_cream') THEN 'ice_cream'
WHEN shop IN ('art', 'bag', 'bakery', 'coffee', 'convenience', 'deli', 'department_store', 
              'garden_centre', 'pet', 'toys', 'sports') THEN 'shop_' || shop

-- specified cases without symbols
WHEN amenity IN ('nursing_home') OR landuse IN ('basin', 'reservoir', 'sports_centre') OR
     leisure IN ('ice_rink', 'marina') THEN 'dot'

-- everything else
ELSE 'dot' END;

-- Delete rows that don't have special symbol nor name
DELETE FROM osm_poi_point WHERE symbol='dot' AND ((name <> '') IS NOT TRUE);

-- Update geometry
-- UPDATE osm_poi_point
-- SET
-- class = poi_class(subclass, mapping_key),
-- "rank" = poi_class_rank(class);

CREATE INDEX IF NOT EXISTS osm_poi_point_geom ON osm_poi_point USING gist(geometry);
