\timing on
\set ECHO all
\set ON_ERROR_STOP on

/*
DROP TABLE IF EXISTS distancias_edicion;
CREATE TABLE distancias_edicion AS
WITH distancias AS (
    SELECT   p1.palabra                            AS p1,
             p2.palabra                            AS p2,
             distancia_edicion(p1.palabra, p2.palabra) AS distancia
    FROM     palabras p1
             JOIN palabras p2 ON p1.palabra < p2.palabra
    ORDER BY p1, p2
)
SELECT   *
FROM     distancias
WHERE    distancia <= 0.22
ORDER BY distancia;
*/

DROP TABLE IF EXISTS distancias_vectores;
CREATE TABLE distancias_vectores AS
WITH palabras AS (
    SELECT    p1 AS palabra
    FROM      distancias_edicion
    UNION
    SELECT    p2
    FROM      distancias_edicion
    ORDER BY palabra
), distancias AS (
    SELECT   p1.palabra                                AS p1,
             p2.palabra                                AS p2,
             distancia_edicion(p1.palabra, p2.palabra) AS distancia
    FROM     palabras p1
             JOIN palabras p2 ON p1.palabra < p2.palabra
    ORDER BY p1, p2
), todos AS (
    SELECT p1, p2, distancia FROM distancias
    UNION
    SELECT p2, p1, distancia FROM distancias
    UNION
    SELECT palabra, palabra, 0.0 FROM palabras
), vectores AS (
    SELECT   p1 AS palabra,
             ARRAY_AGG(distancia ORDER BY p2) AS vector
    FROM     todos
    GROUP BY p1
    ORDER BY p1
), pares AS (
    SELECT v1.palabra AS p1,
           v2.palabra AS p2,
           v1.vector AS v1,
           v2.vector AS v2
    FROM   vectores v1
           JOIN vectores v2 ON v1.palabra < v2.palabra
), distancia_vectores AS (
    SELECT  p1,
            p2,
            1.0 -
            (
                SELECT SUM(a * b) AS dot_product
                FROM   UNNEST(v1, v2) p(a, b)
            ) /
            (
                SELECT
                    (SELECT SQRT(SUM(p1 * p1)) FROM UNNEST(v1) p1) *
                    (SELECT SQRT(SUM(p2 * p2)) FROM UNNEST(v1) p2)
                    AS magnitude
            ) AS distancia -- 1.0 - similitud_coseno
    FROM    pares
), estad_distancias AS (
    SELECT  MIN(distancia)                    AS min,
            (MAX(distancia) - MIN(distancia)) AS denom
    FROM    distancia_vectores
), distancias_normalizadas AS (
    SELECT  p1                        AS palabra_1,
            p2                        AS palabra_2,
            (distancia - min) / denom AS distancia
    FROM    distancia_vectores,
            estad_distancias
)
SELECT   *
FROM     distancias_normalizadas
WHERE    distancia < 0.5
ORDER BY distancia, palabra_1, palabra_2
