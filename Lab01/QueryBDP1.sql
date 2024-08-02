CREATE EXTENSION postgis;

CREATE TABLE budynki (
	id INT PRIMARY KEY NOT NULL, 
	geom GEOMETRY NOT NULL,
	nazwa VARCHAR(50)
);

CREATE TABLE drogi (
	id INT PRIMARY KEY NOT NULL,
	geom GEOMETRY NOT NULL,
	nazwa VARCHAR (50)
);

CREATE TABLE punkty_informacyjne(
	id INT PRIMARY KEY NOT NULL,
	geom GEOMETRY,
	nazwa VARCHAR(50)
);

INSERT INTO budynki VALUES (1, ST_GeomFromText('POLYGON((8 1.5, 10.5 1.5, 10.5 4, 8 4, 8 1.5))', -1), 'BuildingA');
INSERT INTO budynki VALUES (2, ST_GeomFromText('POLYGON((4 5, 6 5, 6 7, 4 7, 4 5))', -1), 'BuildingB');
INSERT INTO budynki VALUES (3, ST_GeomFromText('POLYGON((3 6, 5 6, 5 8, 3 8, 3 6))', -1), 'BuildingC');
INSERT INTO budynki VALUES (4, ST_GeomFromText('POLYGON((9 8, 10 8, 10 9, 9 9, 9 8))', -1), 'BuildingD');
INSERT INTO budynki VALUES (5, ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))', -1), 'BuildingF');

SELECT id, ST_AsText(geom), nazwa FROM budynki;

INSERT INTO punkty_informacyjne VALUES 
(1, ST_GeomFromText(('POINT(1 3.5)'), -1), 'G'),
(2, ST_GeomFromText(('POINT(5.5 1.5)'), -1), 'H'),
(3, ST_GeomFromText(('POINT(9.5 6)'), -1), 'I'),
(4, ST_GeomFromText(('POINT(6.5 6)'), -1), 'J'),
(5, ST_GeomFromText(('POINT(6 9.5)'), -1), 'K');

SELECT id, ST_AsText(geom), nazwa FROM punkty_informacyjne;

INSERT INTO drogi VALUES (1, ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)', -1), 'RoadX');
INSERT INTO drogi VALUES (2, ST_GeomFromText('LINESTRING(7.5 0, 7.5 10.5)', -1), 'RoadY');

SELECT id, ST_AsText(geom), nazwa FROM drogi;


-- a. Wyznacz całkowitą długość dróg w analizowanym mieście.
SELECT SUM(ST_Length(geom)) FROM drogi;


-- b. Wypisz geometrię (WKT), pole powierzchni oraz obwód poligonu reprezentującego budynek o nazwie BuildingA.
SELECT ST_AsText(geom) AS geometria, ST_Area(geom) AS pole_powierzchni, ST_Perimeter(geom) AS obwod 
FROM budynki WHERE nazwa = 'BuildingA';


-- c. Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki posortuj alfabetycznie.
SELECT nazwa, ST_Area(geom) AS pole_powierzchni FROM budynki ORDER BY nazwa;


-- d. Wypisz nazwy i obwody 2 budynków o największej powierzchni.
SELECT nazwa, ST_Perimeter(geom) AS obwod FROM budynki ORDER BY ST_Area(geom) DESC LIMIT 2;


-- e. Wyznacz najkrótszą odległość między budynkiem BuildingC a punktem G.
SELECT ST_Distance(b.geom, p.geom) AS odleglosc 
FROM budynki b, punkty_informacyjne p WHERE b.nazwa = 'BuildingC' AND p.nazwa = 'G';


-- f. Wypisz pole powierzchni tej części budynku BuildingC, która znajduje się w odległości większej niż 0.5 od budynku BuildingB.
SELECT ST_Area( ST_Difference(
	(SELECT geom FROM budynki WHERE nazwa='BuildingC'), 
	(ST_Buffer((SELECT geom FROM budynki WHERE nazwa='BuildingB'), 0.5))
)) AS pole_powierzchni FROM budynki WHERE nazwa = 'BuildingC';


-- g. Wybierz te budynki, których centroid (ST_Centroid) znajduje się powyżej drogi o nazwie RoadX. 
SELECT b.id, ST_AsText(b.geom), b.nazwa FROM budynki b, drogi d 
WHERE ST_Y(ST_Centroid(b.geom)) > ST_Y(ST_Centroid(d.geom)) AND d.nazwa='RoadX';


-- 8. Oblicz pole powierzchni tych części budynku BuildingC i poligonu o współrzędnych (4 7, 6 7, 6 8, 4 8, 4 7), 
-- które nie są wspólne dla tych dwóch obiektów.
SELECT ST_Area(ST_SymDifference(geom, ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'))) 
AS pole_powierzchni FROM budynki WHERE nazwa='BuildingC';



