\timing on
\set echo all
\set on_error_stop on

\o nomenclador.log

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
CREATE OR REPLACE FUNCTION edit_distance(a TEXT, b TEXT) RETURNS REAL AS
$$
    SELECT levenshtein(a, b)::REAL / GREATEST(LENGTH(a), LENGTH(b));
$$
    LANGUAGE SQL;

DROP TABLE IF EXISTS nombres;
CREATE TABLE nombres (
    area        VARCHAR(6)  NOT NULL,
    nombre      VARCHAR(48) NOT NULL,
    ocurrencias INTEGER NOT NULL
);

\COPY nombres FROM data/corpus.tsv DELIMITER E'\t';

-- Generar nombres normalizados
ALTER TABLE nombres ADD COLUMN nombre_normalizado VARCHAR(48);

UPDATE nombres
SET    nombre_normalizado = (
            SELECT  ARRAY_TO_STRING(ARRAY_AGG(palabra), ' ')
            FROM    REGEXP_SPLIT_TO_TABLE(nombre, '[^[:alnum:]]') AS palabra
            WHERE   palabra != ''
       );
DELETE FROM nombres WHERE nombre_normalizado IS NULL; -- 9 rows

DROP TABLE IF EXISTS nombres_normalizados;
CREATE TABLE nombres_normalizados AS
SELECT   area,
         nombre_normalizado,
         COUNT(*)                 AS cuenta_nombres,
         SUM(ocurrencias)         AS total_ocurrencias
FROM     nombres
GROUP BY area,
         nombre_normalizado
ORDER BY area,
         nombre_normalizado;

-- Extraer palabras
DROP TABLE IF EXISTS palabras_nombre_area;
CREATE TABLE palabras_nombre_area AS -- 1'196.167
SELECT n.area,
       n.nombre_normalizado,
       n.cuenta_nombres,
       n.total_ocurrencias,
       p.posicion,
       p.palabra
FROM   nombres_normalizados n
       JOIN LATERAL STRING_TO_TABLE(n.nombre_normalizado, ' ')
            WITH ORDINALITY AS p(palabra, posicion) ON TRUE
ORDER BY n.area,
         n.nombre_normalizado,
         n.cuenta_nombres,
         n.total_ocurrencias,
         p.posicion,
         p.palabra;

DROP TABLE IF EXISTS palabras_area;
CREATE TABLE palabras_area AS -- 287.481
SELECT   area,
         palabra,
         COUNT(*)                           AS cuenta_palabra,
         COUNT(DISTINCT nombre_normalizado) AS cuenta_normalizados,
         SUM(cuenta_nombres)                AS cuenta_nombres,
         SUM(total_ocurrencias)             AS total_ocurrencias
FROM     palabras_nombre_area
GROUP BY area,
         palabra
ORDER BY 1, 2;

DROP TABLE IF EXISTS area; -- 1.166
CREATE TABLE area AS
SELECT   area,
         COUNT(*)               AS cuenta_palabras,
         SUM(total_ocurrencias) AS ocurrencias_palabras,
         AVG(total_ocurrencias) AS promedio_ocurrencias_palabra
FROM     palabras_area
GROUP BY area
ORDER BY area;

CREATE UNIQUE INDEX nn_area_nombre
ON nombres_normalizados(area, nombre_normalizado);
CREATE UNIQUE INDEX np_area_nombre ON
palabras_nombre_area(area, nombre_normalizado, posicion);
ALTER TABLE nombres_normalizados ADD COLUMN numero_palabras INTEGER;
UPDATE nombres_normalizados n -- 351,966
SET numero_palabras = (
    SELECT COUNT(*)
    FROM   palabras_nombre_area p
    WHERE  n.area = p.area
      AND  n.nombre_normalizado = p.nombre_normalizado
);
CREATE UNIQUE INDEX pa_area_palabra
ON palabras_area(area, palabra);

\o
