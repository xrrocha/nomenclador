\set ON_ERROR_STOP ON
\set TIMING ON
\set ECHO ALL

DROP TABLE IF EXISTS nombres;

CREATE TABLE nombres (
    area        VARCHAR(6)  NOT NULL,
    nombre      VARCHAR(48) NOT NULL,
    occurencias INTEGER NOT NULL
);

\COPY nombres FROM data/corpus.tsv DELIMITER E'\t';

-- Generar nombres normalizados
ALTER TABLE nombres ADD COLUMN nombre_normalizado VARCHAR(48);

UPDATE nombres
SET    nombre_normalizado = (
            SELECT  ARRAY_TO_STRING(ARRAY_AGG(palabra), ' ')
            FROM    (
                        SELECT REGEXP_SPLIT_TO_TABLE(
                            nombre,
                            '[^[:alnum:]]'
                        ) AS palabra
                    )
            WHERE   palabra != ''
       );

-- Generar perfil de nombres normalizados
ALTER TABLE nombres_normalizados ADD COLUMN perfil VARCHAR[];

UPDATE nombres_normalizados
SET perfil = (
    Select ARRAY_AGG(palabra ORDER BY PALABRA)
    FROM (
        SELECT DISTINCT palabra
        FROM REGEXP_SPLIT_TO_TABLE(nombre_normalizado, ' ') AS palabra
    )
);
