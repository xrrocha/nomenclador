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
SELECT   n.area,
         n.nombre_normalizado,
         COUNT(*)                         AS cuenta_nombres,
         SUM(n.ocurrencias)               AS ocurrencias,
         ARRAY_AGG(DISTINCT p ORDER BY p) AS perfil
FROM     (
            SELECT   area,
                     nombre_normalizado,
                     SUM(ocurrencias) AS ocurrencias
            FROM     nombres
            GROUP BY area,
                     nombre_normalizado
            ORDER BY area,
                     nombre_normalizado
         ) n
         JOIN LATERAL STRING_TO_TABLE(n.nombre_normalizado, ' ') p ON TRUE
GROUP BY area,
         nombre_normalizado
ORDER BY area,
         nombre_normalizado;

DROP TABLE IF EXISTS perfiles;
CREATE TABLE perfiles AS
SELECT   area,
         perfil,
         COUNT(*)            AS cuenta_normalizados,
         SUM(cuenta_nombres) AS cuenta_nombres,
         SUM(ocurrencias)    AS ocurrencias
FROM     nombres_normalizados
GROUP BY area,
         perfil
ORDER BY area,
         perfil;

DROP TABLE IF EXISTS palabras_area;
CREATE TABLE palabras_area AS
SELECT   area,
         UNNEST(perfil)         AS palabra,
         COUNT(DISTINCT perfil) AS cuenta_perfiles
FROM     perfiles
GROUP BY area,
         palabra
ORDER BY area,
         palabra;
CREATE UNIQUE INDEX pa_area_palabra ON palabras_area(area, palabra);

DROP TABLE IF EXISTS estad_area;
CREATE TABLE estad_area AS
SELECT   area,
         COUNT(*) AS cuenta_perfiles
FROM     perfiles
GROUP BY area
ORDER BY area;
CREATE UNIQUE INDEX ea_area ON estad_area(area);

ALTER TABLE palabras_area ADD column idf REAL;
UPDATE palabras_area p
SET idf = (
    SELECT LOG(a.cuenta_perfiles / p.cuenta_perfiles::REAL)
    FROM   estad_area a
    WHERE  p.area = a.area
);


\o
