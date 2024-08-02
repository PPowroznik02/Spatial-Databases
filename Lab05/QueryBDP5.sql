-- Bazy danych przestrzennych – ćwiczenia 6. Praca z kolekcjami geometrii i EWKT.
-- 1. Utwórz tabelę obiekty. W tabeli umieść nazwy i geometrie obiektów przedstawionych poniżej. Układ odniesienia
-- ustal jako niezdefiniowany. Definicja geometrii powinna odbyć się za pomocą typów złożonych, właściwych dla EWKT.

CREATE TABLE obiekty(
	nazwa VARCHAR(50),
	geom GEOMETRY
)

DROP TABLE obiekty

-- obiekt1
INSERT INTO obiekty VALUES('obiekt1', ST_GeomFromEWKT('SRID=-1; COMPOUNDCURVE((0 1, 1 1),  
		CIRCULARSTRING(1 1, 2 0, 3 1), CIRCULARSTRING(3 1, 4 2, 5 1), (5 1, 6 1))'))

-- obiekt2
INSERT INTO obiekty VALUES('obiekt2', ST_GeomFromEWKT('SRID=-1; CURVEPOLYGON(
	COMPOUNDCURVE((10 2, 10 6, 10 6, 14 6), CIRCULARSTRING(14 6, 16 4, 14 2), CIRCULARSTRING(14 2, 12 0, 10 2)), 
		CIRCULARSTRING(11 2, 13 2, 11 2))'))

-- obiekt 3
INSERT INTO obiekty VALUES('obiekt3', ST_GeomFromEWKT('SRID=-1; CURVEPOLYGON(COMPOUNDCURVE((7 15, 10 17, 12 13, 7 15)))'))

-- obiekt 4
INSERT INTO obiekty VALUES('obiekt4', ST_GeomFromEWKT('SRID=-1; MULTILINESTRING((20.5 19.5, 22 19, 26 21, 25 22, 27 24, 25 25, 20 20))'))

-- obiekt 5 (w przestrzeni 3dz)
INSERT INTO obiekty VALUES('obiekt5', ST_GeomFromEWKT('SRID=-1; MULTIPOINT((30 30 59), (38 32 234))'))

-- obiekt 6
INSERT INTO obiekty VALUES('obiekt6', ST_GeomFromEWKT('SRID=-1; GEOMETRYCOLLECTION(POINT(4 2), LINESTRING(1 1, 3 2))'))

SELECT nazwa, ST_AsText(geom) FROM obiekty


-- 1. Wyznacz pole powierzchni bufora o wielkości 5 jednostek, który został utworzony wokół najkrótszej linii łączącej
-- obiekt 3 i 4.
SELECT ST_AREA(ST_Buffer(ST_ShortestLine((SELECT geom FROM obiekty WHERE nazwa='obiekt3'),
					  (SELECT geom FROM obiekty WHERE nazwa='obiekt4')), 5))
					  
					  
-- 2. Zamień obiekt4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to zadanie? Zapewnij te warunki.	
WITH polygon AS(						 
SELECT ST_AsText(ST_MakePolygon(ST_MakeLine((SELECT ST_LineMerge(geom) FROM obiekty WHERE nazwa='obiekt4'), 
	ST_PointN((SELECT ST_LineMerge(geom) FROM obiekty WHERE nazwa='obiekt4'), 1)))) 
AS geom 
)
UPDATE obiekty
SET geom=(SELECT geom FROM polygon)
WHERE nazwa='obiekt4'

							 
						
-- 3. W tabeli obiekty, jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4.
INSERT INTO obiekty VALUES ('obiekt7', ST_Union((SELECT ST_AsText(geom) FROM obiekty WHERE nazwa='obiekt3'),
			(SELECT ST_AsText(geom) FROM obiekty WHERE nazwa='obiekt4')))


-- 4. Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek, które zostały utworzone wokół obiektów nie zawierających łuków.
SELECT SUM(ST_Area(ST_Buffer(geom, 5))) FROM obiekty WHERE ST_HasArc(geom)='false'




-- Przydatne funkcje:
-- ST_LineToCurve - converts a LINESTRING/POLYGON to a CIRCULARSTRING, CURVED POLYGON; 
-- ST_CurveToLine - converts a CIRCULARSTRING/CURVEDPOLYGON to a LINESTRING/POLYGON 
-- ST_Line_Interpolate_Point — Returns a point interpolated along a line. Second argument is a 
-- float8 between 0 and 1 representing fraction of total length of linestring the point has to be located.
-- ST_GeometryType - return the geometry type of the ST_Geometry value.
-- ST_LineFromMultiPoint — Creates a LineString from a MultiPoint geometry.
-- ST_HasArc - Returns true if a geometry or geometry collection contains a circular string.
-- ST_ShortestLine — Returns the 2-dimensional shortest line between two geometries (for version 1.5.0).