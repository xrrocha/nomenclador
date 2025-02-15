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
), reducidos_numeral AS (
    SELECT area,
           nombre,
           REGEXP_REPLACE(
                nombre_reducido,
                '((#|N[O0°])[ .]+([[:digit:]]))', '#\3'
           ) AS nombre_reducido
    FROM   reducidos
)
SELECT DISTINCT
         area,
         nombre,
         nombre_reducido,
         posicion,
         palabra
FROM     reducidos_numeral r
         JOIN LATERAL REGEXP_SPLIT_TO_TABLE(
            r.nombre_reducido,
            '\s+'
         ) WITH ORDINALITY AS p(palabra, posicion) ON TRUE
ORDER BY area, nombre, nombre_reducido, posicion, palabra;
