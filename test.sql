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
WITH pares AS (
    SELECT   p1, p2
    FROM     distancias_edicion
    UNION
    SELECT   p2, p1
    FROM     distancias_edicion
    UNION
    SELECT   p1, p1
    FROM (
        SELECT p1 FROM distancias_edicion
        UNION
        SELECT p2 FROM distancias_edicion
    )
    ORDER BY p1, p2
), perfiles AS (
    SELECT   p1 AS palabra,
             ARRAY_AGG(p2 ORDER BY p2) AS perfil
    FROM     pares
    GROUP BY p1
    ORDER BY p1
), pares_perfiles AS (
    SELECT d.p1,
           d.p2,
           (
                SELECT ARRAY_AGG(p ORDER BY p)
                FROM (
                    SELECT UNNEST(v1.perfil) AS p
                    UNION
                    SELECT UNNEST(v2.perfil)
                )
           ) AS perfil
    FROM distancias_edicion d
         JOIN perfiles v1 ON d.p1 = v1.palabra
         JOIN perfiles v2 ON d.p2 = v2.palabra
    ORDER BY d.p1, d.p2
), vectores_perfil AS (
    SELECT   p1,
             p2,
             (
                  SELECT ARRAY_AGG(
                      distancia_edicion(p1, termino)
                      ORDER BY termino
                  )
                  FROM   UNNEST(perfil) termino
             ) AS v1,
             (
                  SELECT ARRAY_AGG(
                      distancia_edicion(p2, termino)
                      ORDER BY termino
                  )
                  FROM   UNNEST(perfil) termino
             ) AS v2
    FROM     pares_perfiles
    ORDER BY p1, p2
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
    FROM    vectores_perfil
)
SELECT   *
FROM     distancia_vectores;
