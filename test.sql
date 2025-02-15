\timing on
\set ECHO all
\set ON_ERROR_STOP on

WITH desacentuados AS (
    SELECT area,
           nombre,
           TRANSLATE(
                nombre,
                'ÁÉÍÓÚÜ',
                'AEIOUU'
           ) AS nombre_desacentuado
     FROM  escuelas.escuelas
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
), nombres_normalizados AS (
    SELECT   area,
             nombre,
             ARRAY_TO_STRING(
                ARRAY_AGG(palabra ORDER BY posicion),
                ' '
             ) AS nombre_normalizado
    FROM     palabras_apostrofe
    GROUP BY area, nombre
    ORDER BY area, nombre
), palabras_solas AS (
    SELECT   palabra,
             COUNT(*) AS ocurrencias
    FROM     nombres_normalizados n
             JOIN LATERAL REGEXP_SPLIT_TO_TABLE(n.nombre_normalizado, '\s+')
             AS palabra ON TRUE
    WHERE    palabra != ''
    GROUP BY palabra
), estad_palabras AS (
    SELECT   MIN(ocurrencias)                          AS min,
             MAX(ocurrencias) - MIN(ocurrencias)::REAL AS denom
    FROM     palabras_solas
), palabras_normalizadas AS (
    SELECT palabra,
           ocurrencias,
           1.0 - ((ocurrencias - min) / denom) AS relevancia
    FROM palabras_solas p,
         estad_palabras a
)
select area, nombre_normalizado, count(*),
       array_agg(nombre order by nombre)
from nombres_normalizados
group by area, nombre_normalizado
order by 3 desc, 1, 2;
