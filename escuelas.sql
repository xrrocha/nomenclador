\timing on
\set ECHO all
\set ON_ERROR_STOP on

\o escuelas.log

/*
DROP TABLE IF EXISTS escuelas;
CREATE TABLE escuelas (
    area   VARCHAR(6)       NOT NULL,
    nombre VARCHAR(48)      NOT NULL,
    codigo VARCHAR(5)       NOT NULL UNIQUE
);
\COPY escuelas FROM data/escuelas.tsv DELIMITER E'\t';

DROP TABLE IF EXISTS nombres_normalizados;
CREATE TABLE nombres_normalizados AS
WITH desacentuados AS (
    SELECT area,
           nombre,
           TRANSLATE(
                nombre,
                'ÁÉÍÓÚÜ',
                'AEIOUU'
           ) AS nombre_desacentuado
     FROM  escuelas
), puntuacion AS (
    SELECT   SUBSTR(p, i, 1) AS signo,
             COUNT(*)        AS cuenta
    FROM     desacentuados e
             JOIN LATERAL REGEXP_SPLIT_TO_TABLE(
                 e.nombre_desacentuado,
                 '[#.°''[:alpha:][:digit:]]+'
             ) p ON TRUE
             JOIN LATERAL GENERATE_SERIES(1, LENGTH(p)) i ON TRUE
    WHERE   SUBSTR(p, i, 1) != ' '
    GROUP BY signo
    ORDER BY signo
), patron_puntuacion AS (
    SELECT ARRAY_TO_STRING(ARRAY_AGG(signo), '') AS patron
    FROM   puntuacion
), reducidos AS (
    SELECT  area,
            nombre,
            TRIM(TRANSLATE(
                nombre_desacentuado,
                patron,
                REPEAT(' ', LENGTH(patron))
            )) AS nombre_reducido
    FROM    desacentuados,
            patron_puntuacion
), palabras_numeral_1 AS (
    SELECT area,
           nombre,
           REGEXP_REPLACE(
                nombre_reducido,
                '((#|NR?[O0°]?)[ .]*([[:digit:]]))', '#\3', 'g'
           ) AS nombre_reducido
    FROM   reducidos
), palabras_numeral_2 AS (
    SELECT DISTINCT
             area,
             nombre,
             nombre_reducido,
             posicion,
             palabra
    FROM     palabras_numeral_1 r
             JOIN LATERAL REGEXP_SPLIT_TO_TABLE(
                REPLACE(r.nombre_reducido, '#', ' #'),
                '\s+'
             ) WITH ORDINALITY AS p(palabra, posicion) ON TRUE
    ORDER BY area, nombre, nombre_reducido, posicion, palabra
), palabras_puntuadas AS (
        SELECT   area,
                 nombre,
                 nombre_reducido,
                 posicion,
                 CASE
                    WHEN palabra NOT LIKE '%.%' THEN palabra
                    ELSE CASE
        
                        WHEN palabra ~ '^[A-Z]+\.$' THEN palabra
                        WHEN palabra ~ '^([A-Z]\.)+[A-Z]$' THEN palabra || '.'
        
                        WHEN palabra ~ '^([A-Z]\.)+$' THEN palabra
                        WHEN palabra ~ '^([A-Z]\.)+[A-Z]{2,}$' THEN
                            REGEXP_REPLACE(palabra, '^(([A-Z]\.)+)([A-Z]{2,})$', '\1 \3')
        
                        WHEN palabra ~ '^([A-Z]{2}\.){2}$' THEN palabra
                        WHEN palabra ~ '^(([A-Z]{2}\.){2})[A-Z]{2,}' THEN
                            REGEXP_REPLACE(palabra, '^(([A-Z]{2}\.){2})([A-Z]{2,})$', '\1 \3')
                        ELSE REPLACE(palabra, '.', '. ')
                    END
                 END      AS palabra
        FROM     palabras_numeral_2
        ORDER BY area, nombre, nombre_reducido, posicion
), palabras_apostrofe AS (
    -- TODO INS.TEC.SUP[^.]
    SELECT   area,
             nombre,
             posicion,
             CASE
                WHEN palabra NOT LIKE '%''%' THEN palabra
                WHEN palabra LIKE '%D''LA%' THEN REPLACE(palabra, 'D''LA', 'DE LA')
                WHEN palabra LIKE '%P''LA%' THEN REPLACE(palabra, 'P''LA', 'PARA LA')
                WHEN palabra ~ 'D''[AEIOU]'
                  OR palabra ~ 'O''[A-Z]' THEN palabra
                ELSE REPLACE(palabra, '''', ' ')
             END        AS palabra
    FROM     palabras_puntuadas
    ORDER BY area, nombre, posicion
)
SELECT   area,
         nombre,
         ARRAY_TO_STRING(
            ARRAY_AGG(
                palabra
                ORDER BY posicion
            ),
            ' '
         ) AS nombre_normalizado
FROM     palabras_apostrofe
GROUP BY area, nombre
ORDER BY area, nombre;

DROP TABLE IF EXISTS palabras;
CREATE TABLE palabras AS
WITH palabras_solas AS (
    SELECT   palabra,
             COUNT(*) AS ocurrencias
    FROM     nombres_normalizados n
             JOIN LATERAL REGEXP_SPLIT_TO_TABLE(n.nombre_normalizado, '\s+')
             AS palabra ON TRUE
    WHERE    palabra != ''
    GROUP BY palabra
), estad_palabras AS (
    SELECT   MIN(ocurrencias)::REAL                      AS min,
             (MAX(ocurrencias) - MIN(ocurrencias))::REAL AS denom
    FROM     palabras_solas
)
SELECT   palabra,
         ocurrencias,
         1.0 - ((ocurrencias - min) / denom) AS relevancia
FROM     palabras_solas p,
         estad_palabras a
ORDER BY palabra;

DROP TABLE IF EXISTS palabras_nombre;
CREATE TABLE palabras_nombre AS
SELECT n.nombre_normalizado  AS nombre,
       p.posicion,
       p.palabra
FROM (
    SELECT DISTINCT nombre_normalizado
    FROM nombres_normalizados
) n
JOIN LATERAL REGEXP_SPLIT_TO_TABLE(n.nombre_normalizado, '\s+')
    WITH ORDINALITY AS p(palabra, posicion) ON TRUE
ORDER BY nombre_normalizado, posicion;
CREATE UNIQUE INDEX pn_posicion ON palabras_nombres(nombre, posicion);
CREATE INDEX pn_palabra ON palabras_nombres(palabra);

DROP TABLE IF EXISTS diccionario;
CREATE TABLE diccionario (
    palabra VARCHAR(48) NOT NULL UNIQUE
);
\COPY diccionario FROM data/diccionario-reducido.tsv;

DROP TABLE IF EXISTS nombres_personales;
CREATE TABLE nombres_personales (
    palabra VARCHAR(48) NOT NULL UNIQUE
);
\COPY nombres_personales FROM data/nombres-personales.tsv;
*/

\o
\q
