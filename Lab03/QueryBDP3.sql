CREATE EXTENSION postgis;

-- 1. Zaimportuj następujące pliki shapefile do bazy, przyjmij wszędzie układ WGS84:
-- - T2018_KAR_BUILDINGS
-- - T2019_KAR_BUILDINGS
-- Pliki te przedstawiają zabudowę miasta Karlsruhe w latach 2018 i 2019.Znajdź budynki, 
-- które zostały wybudowane lub wyremontowane na przestrzeni roku (zmiana pomiędzy 2018 a 2019).

-- zwraca te budynki ktore sa w obu tabelach, ale ich geometria ulegla zmianie
SELECT b19.* FROM t2018_kar_buildings b18, t2019_kar_buildings b19 
WHERE ST_Equals(b18.geom, b19.geom) = 'false' AND b18.polygon_id = b19.polygon_id
UNION
-- zwraca te budynki ktore sa w t2019_kar_buildings, ale nie ma ich w t2018_kar_buildings (wybudowane)
SELECT DISTINCT b19.* FROM t2018_kar_buildings b18, t2019_kar_buildings b19 
WHERE b19.polygon_id NOT IN (SELECT polygon_id FROM t2018_kar_buildings);


-- zwraca te budynki ktore sa w t2018_kar_buildings, ale nie ma ich w t2019_kar_buildings (wyburzone)
SELECT DISTINCT b18.* FROM t2018_kar_buildings b18, t2019_kar_buildings b19 
WHERE b18.polygon_id NOT IN (SELECT polygon_id FROM t2019_kar_buildings)


-- 2. Zaimportuj dane dotyczące POIs (Points of Interest) z obu lat:
-- - T2018_KAR_POI_TABLE
-- - T2019_KAR_POI_TABLE
-- Znajdź ile nowych POI pojawiło się w promieniu 500 m od wyremontowanych lub
-- wybudowanych budynków, które znalezione zostały w zadaniu 1. Policz je wg ich kategorii.

WITH tmpTable
AS(
	SELECT b19.* FROM t2018_kar_buildings b18, t2019_kar_buildings b19 
	WHERE ST_Equals(b18.geom, b19.geom) = 'false' AND b18.polygon_id = b19.polygon_id
	UNION
	SELECT DISTINCT b19.* FROM t2018_kar_buildings b18, t2019_kar_buildings b19 
	WHERE b19.polygon_id NOT IN (SELECT polygon_id FROM t2018_kar_buildings)
)
SELECT poi19.type, COUNT(poi19.*) FROM T2019_KAR_POI_TABLE poi19 
WHERE ST_Within(poi19.geom, 
				(SELECT ST_Buffer(ST_Union(geom), 500) FROM tmpTable))
AND (poi19.poi_id NOT IN (SELECT poi_id FROM T2018_KAR_POI_TABLE))
GROUP BY poi19.type


-- 3. Utwórz nową tabelę o nazwie ‘streets_reprojected’, która zawierać będzie dane z tabeli
-- T2019_KAR_STREETS przetransformowane do układu współrzędnych DHDN.Berlin/Cassini.

SELECT gid, link_id, st_name, ref_in_id, nref_in_id, func_class, speed_cat, fr_speed_l, to_speed_l,
dir_travel, ST_Transform(geom, 3068) AS geom INTO streets_reprojected FROM  T2019_KAR_STREETS


SELECT DISTINCT ST_SRID(geom) FROM T2019_KAR_STREETS;
SELECT DISTINCT ST_SRID(geom) FROM streets_reprojected;


-- 4. Stwórz tabelę o nazwie ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej.
-- Użyj następujących współrzędnych:
-- X 	   Y
-- 8.36093 49.03174
-- 8.39876 49.00644
-- Przyjmij układ współrzędnych GPS.

CREATE TABLE input_points(
	id INT NOT NULL PRIMARY KEY,
	name VARCHAR(50),
	geom GEOMETRY NOT NULL
)

INSERT INTO input_points VALUES (1, 'PunktA', ST_GeomFromText(('POINT(8.36093 49.03174)'), 4326));
INSERT INTO input_points VALUES (2, 'PunktB', ST_GeomFromText(('POINT(8.39876 49.00644)'), 4326));


SELECT * FROM input_points;


-- 5. Zaktualizuj dane w tabeli ‘input_points’ tak, aby punkty te były w układzie współrzędnych
-- DHDN.Berlin/Cassini. Wyświetl współrzędne za pomocą funkcji ST_AsText().

ALTER TABLE input_points
	ALTER COLUMN geom TYPE GEOMETRY(POINT, 3068)
		USING ST_Transform(geom, 3068)


SELECT ST_AsText(geom), ST_SRID(geom) FROM input_points;


-- 6. Znajdź wszystkie skrzyżowania, które znajdują się w odległości 200 m od linii zbudowanej z punktów w tabeli 
-- ‘input_points’. Wykorzystaj tabelę T2019_STREET_NODE. Dokonaj reprojekcji geometrii, aby była zgodna z resztą tabel.

SELECT * FROM T2019_KAR_STREET_NODE sn 
WHERE ST_Within(ST_Transform(sn.geom, 3068), 
				(SELECT ST_Buffer(ST_MakeLine(geom), 200) FROM input_points))
				AND sn.intersect='Y'


SELECT ST_GeometryType(geom), ST_SRID(geom) FROM T2019_kar_STREET_NODE


-- 7. Policz jak wiele sklepów sportowych (‘Sporting Goods Store’ - tabela POIs) znajduje się
-- w odległości 300 m od parków (LAND_USE_A).

SELECT COUNT(poi.*) FROM t2019_kar_poi_table poi 
WHERE poi.type='Sporting Goods Store' 
AND ST_Distance(poi.geom, (SELECT ST_UNION(geom) FROM t2018_kar_land_use_a 
				 			WHERE type ='Park (City/County)')) < 300 


-- 8. Znajdź punkty przecięcia torów kolejowych (RAILWAYS) z ciekami (WATER_LINES). Zapisz
-- znalezioną geometrię do osobnej tabeli o nazwie ‘T2019_KAR_BRIDGES’.

SELECT DISTINCT ST_Intersection(rw.geom, wl.geom) AS geom INTO T2019_KAR_BRIDGES
FROM t2019_kar_railways rw, t2019_kar_water_lines wl;


SELECT ST_AsText(geom) FROM T2019_KAR_BRIDGES
DROP TABLE T2019_KAR_BRIDGES

