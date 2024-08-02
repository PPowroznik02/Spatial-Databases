CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;

CREATE SCHEMA vectors;
CREATE SCHEMA rasters;

-- 1,2. Pobierz dane o nazwie 1:250 000 Scale Colour Raster™ Free OS OpenData ze strony:
-- https://osdatahub.os.uk/downloads/open
-- Załaduj te dane do tabeli o nazwie uk_250k.

raster2pgsql.exe -s 27700 -N -32767 -t 100x100 -I -F -C -M -d 
C:\Users\ppowr\Downloads\ras250_gb\data\*.tif rasters.uk_250k 
| psql -d Cw8 -h localhost -U postgres -p 5432

SELECT * FROM rasters.uk_250k

-- 3. Wyeksportuj wyniki do pliku GeoTIFF.
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM rasters.uk_250k;
----------------------------------------------
SELECT lo_export(loid, 'D:\uk_250k.tiff') 
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out;

DROP TABLE tmp_out;


gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9 PG:"host=localhost 
port=5432 dbname=Cw8 user=postgres password=admin schema=rasters table=uk_250k 
mode=2" C:\users\ppowr\Desktop\uk_250k.tiff

-- 4,5. Pobierz dane o nazwie OS Open Zoomstack ze strony:
-- https://osdatahub.os.uk/downloads/open/OpenZoomstack
-- Załaduj do bazy danych tabelę reprezentującą granice parków narodowych.

-- a) wygenerowanie w qgis pliku dump i zadaldowanie go do do bazy

-- b) zaladowanie pliku shp wygenerowanego w qgis za pomoca shp2pgsql
shp2pgsql -s 27700 C:\Users\ppowr\Downloads\national_parks.shp vectors.national_parks2 
| psql -h localhost -p 5432 -U postgres -d Cw8

-- c) zaladowanie pliku gpkg bezposrednio do bazy za pomoca ogr2ogr
ogr2ogr -f PostgreSQL PG:"dbname='Cw8' host='localhost' port='5432' 
user='postgres' password='admin'"  -lco SCHEMA=vectors 
C:\Users\ppowr\Desktop\national_parks_geopackage.gpkg -nln national_parks3

-- 6. Utwórz nową tabelę o nazwie uk_lake_district, gdzie zaimportujesz mapy rastrowe z
-- punktu 1., które zostaną przycięte do granic parku narodowego Lake District.
CREATE TABLE rasters.uk_lake_district AS (
	SELECT r.rid, ST_Clip(r.rast, v.wkb_geometry, true) AS rast
	FROM rasters.uk_250k AS r, vectors.national_parks AS v
	WHERE ST_Intersects(r.rast, v.wkb_geometry) AND v.id = 1
)

SELECT * FROM rasters.uk_lake_district

-- 7. Wyeksportuj wyniki do pliku GeoTIFF.
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM rasters.uk_lake_district;
----------------------------------------------
SELECT lo_export(loid, 'D:\uk_lake_district.tiff') 
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out;


-- 8,9. Pobierz dane z satelity Sentinel-2 wykorzystując portal: https://scihub.copernicus.eu Wybierz
-- dowolne zobrazowanie, które pokryje teren parku Lake District oraz gdzie parametr cloud coverage będzie poniżej 20%.
-- Załaduj dane z Sentinela-2 do bazy danych.
raster2pgsql.exe -s 32630 -N 32767 -t 100x100 -I -F -C -M 
C:\Users\ppowr\Downloads\S2B_MSIL1C_20230830T113319_N0509_R080_T30UVF_20230830T122710.SAFE
\GRANULE\L1C_T30UVF_A033854_20230830T113322\IMG_DATA\T30UVF_20230830T113319_B03.jp2 
rasters.landsat2_b03 | psql -d Cw8 -h localhost -U postgres -p 5432

raster2pgsql.exe -s 32630 -N 32767 -t 100x100 -I -F -C -M 
C:\Users\ppowr\Downloads\S2B_MSIL1C_20230830T113319_N0509_R080_T30UVF_20230830T122710.SAFE
\GRANULE\L1C_T30UVF_A033854_20230830T113322\IMG_DATA\T30UVF_20230830T113319_B08.jp2 
rasters.landsat2_b08 | psql -d Cw8 -h localhost -U postgres -p 5432


-- 10. Policz indeks NDWI (to inny indeks niż NDVI) oraz przytnij wyniki do granic Lake District.
-- NDWI=(Green – NIR)/(Green + NIR) || NWDI=(B3 – B8)/(B3 + B8)

WITH b03 AS(
		(SELECT ST_Clip(r.rast, ST_Transform(v.wkb_geometry, 32630), true) AS rast
		FROM rasters.landsat2_b03 AS r, vectors.national_parks AS v
		WHERE ST_Intersects(r.rast, ST_Transform(v.wkb_geometry, 32630)) AND v.id=1)), 
	
b08 AS (
	(SELECT ST_Clip(r.rast, ST_Transform(v.wkb_geometry, 32630), true) AS rast
		FROM rasters.landsat2_b08 AS r, vectors.national_parks AS v
		WHERE ST_Intersects(r.rast, ST_Transform(v.wkb_geometry, 32630)) AND v.id=1))
SELECT ST_MapAlgebra(b03.rast,1, b08.rast,1, '([rast1.val]-[rast2.val])/([rast1.val]+[rast2.val])::float', '32BF') AS rast
INTO rasters.lake_district_ndwi
FROM b03, b08



-- 11. Wyeksportuj obliczony i przycięty wskaźnik NDWI do GeoTIFF.
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM rasters.lake_district_ndwi;
----------------------------------------------
SELECT lo_export(loid, 'D:\lake_district_ndwi.tiff') 
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out;