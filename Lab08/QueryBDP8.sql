CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;

CREATE TABLE MergedSouthWales AS 
SELECT ST_Union(rast) AS rast FROM public."Exports";

SELECT * FROM public.MergedSouthWales;

