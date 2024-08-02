CREATE EXTENSION postgis;


-- 4. Wyznacz liczbę budynków (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty) położonych w 
-- odległości mniejszej niż 1000 jednostek od głównych rzek. Budynki spełniające to kryterium zapisz do osobnej tabeli tableB.
SELECT  count(p.f_codedesc) FROM popp p, rivers r 
WHERE ST_Distance(p.geom, r.geom) < 1000
AND p.f_codedesc = 'Building'; 


SELECT * FROM popp;


-- 5. Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich
-- geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.
SELECT name, elev, geom INTO airportsNew FROM airports

SELECT * FROM airportsNew;

-- a) Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód.
SELECT name, elev, ST_AsText(geom) 
FROM airportsNew an 
ORDER BY ST_X(an.geom) LIMIT 1;

SELECT name, elev, ST_AsText(geom) 
FROM airportsNew an ORDER BY ST_X(an.geom) 
DESC LIMIT 1;


-- b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie
-- środkowym drogi pomiędzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB. Wysokość n.p.m. przyjmij dowolną.
-- Uwaga: geodezyjny układ współrzędnych prostokątnych płaskich (x – oś pionowa, y – oś pozioma)
INSERT INTO airportsNew VALUES(
	'airportB',
	80,
	(SELECT ST_Centroid(
		ST_MakeLine(
			(SELECT geom FROM airportsNew an ORDER BY ST_X(an.geom) LIMIT 1), 
			   (SELECT geom FROM airportsNew an ORDER BY ST_X(an.geom) DESC LIMIT 1)
			   ))
	)
);

SELECT *, ST_AsText(geom) FROM airportsNew WHERE name = 'airportB'


-- 6. Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek od najkrótszej
-- linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”
SELECT an.name, l.names, ST_Area(ST_Buffer(ST_ShortestLine(an.geom, l.geom), 1000)) AS area 
FROM airportsNew an, lakes l 
WHERE an.name = 'AMBLER' AND l.names = 'Iliamna Lake';


-- 7. Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących
-- poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps).
SELECT tr.vegdesc, SUM(ST_Area(tr.geom)) AS area
FROM trees tr, tundra tu, swamp sw
WHERE ST_Contains(tu.geom, tr.geom) OR ST_Contains(sw.geom, tr.geom)
GROUP BY tr.vegdesc;


SELECT tr.vegdesc, 
SUM(ST_Area(ST_Intersection(ST_Union(sw.geom, tu.geom), tr.geom))) AS area
FROM trees tr, tundra tu, swamp sw
GROUP BY tr.vegdesc


SELECT UpdateGeometrySRID('tundra','geom',2964);
SELECT ST_SRID(geom) FROM tundra;