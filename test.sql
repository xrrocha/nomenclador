\timing on
\set ECHO all
\set ON_ERROR_STOP on

WITH desacentuados AS (
    SELECT nombre,
           TRANSLATE(
                nombre,
                'ÁÉÍÓÚÜ',
                'AEIOUU'
           ) AS nombre_normalizado
     FROM  escuelas.escuelas
), puntuacion AS (
    SELECT   SUBSTR(p, i, 1) AS signo,
             COUNT(*)        AS cuenta
    FROM     desacentuados e
             JOIN LATERAL REGEXP_SPLIT_TO_TABLE(
                 e.nombre_normalizado,
                 '[.#°ᵃ''[:alpha:][:digit:]]+'
             ) p ON TRUE
             JOIN LATERAL GENERATE_SERIES(1, LENGTH(p)) i ON TRUE
    WHERE   SUBSTR(p, i, 1) != ' '
    GROUP BY signo
    ORDER BY signo
), patron_puntuacion AS (
    SELECT ARRAY_TO_STRING(ARRAY_AGG(signo), '') AS patron
    FROM   puntuacion
), reducidos AS (
    SELECT  nombre,
            TRANSLATE(
                nombre_normalizado,
                patron,
                REPEAT(' ', LENGTH(patron))
            ) AS nombre_normalizado
    FROM    desacentuados,
            patron_puntuacion
)
SELECT   SUBSTR(p, i, 1) AS signo,
         COUNT(*)        AS cuenta
FROM     desacentuados e
         JOIN LATERAL REGEXP_SPLIT_TO_TABLE(
             e.nombre_normalizado,
             '[ [:alnum:]]+'
         ) p ON TRUE
         JOIN LATERAL GENERATE_SERIES(1, LENGTH(p)) i ON TRUE
GROUP BY signo
ORDER BY cuenta DESC, signo;


-- SELECT   REPLACE(p, '.', '. ') AS palabra,
--          COUNT(*)              AS cuenta
-- FROM     reducidos r
--          JOIN LATERAL
--          REGEXP_SPLIT_TO_TABLE(r.nombre_normalizado, '\s+') p ON TRUE
-- WHERE    p != ''
--   AND    p LIKE '%.%'
--   AND    p !~ '^[A-Z]+\.$'
--   AND    p !~ '^[A-Z]\.([A-Z]\.)*[A-Z]?$'
--   AND    p !~ '^([A-Z]{2}\.){2}'
-- GROUP BY p
-- ORDER BY 2 DESC, 1;
