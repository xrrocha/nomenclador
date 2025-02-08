\set ON_ERROR_STOP ON
\set TIMING ON
\set ECHO ALL

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

-- Generar perfiles de nombres normalizados
DROP TABLE IF EXISTS nombres_normalizados;
CREATE TABLE nombres_normalizados AS
SELECT    area,
          nombre_normalizado,
          COUNT(*)            AS cuenta_nombres,
          SUM(ocurrencias)    AS ocurrencias
FROM      nombres
GROUP BY area, nombre_normalizado
ORDER BY 1, 2;

ALTER TABLE nombres_normalizados ADD COLUMN perfil VARCHAR[];

UPDATE nombres_normalizados
SET perfil = (
    Select ARRAY_AGG(palabra ORDER BY PALABRA)
    FROM (
        SELECT DISTINCT palabra
        FROM REGEXP_SPLIT_TO_TABLE(nombre_normalizado, ' ') AS palabra
    )
);
