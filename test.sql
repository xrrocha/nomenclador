WITH t_perfiles AS (
    SELECT   area,
             perfil
    FROM     perfiles
    WHERE    area = (
        SELECT   area
        FROM     perfiles
        GROUP BY area
        HAVING   COUNT(*) = 32
        LIMIT    1
    )
    ORDER BY perfil
), t_pares AS (
    SELECT perfil_1.area,
           perfil_1.perfil AS perfil_1,
           perfil_2.perfil AS perfil_2
    FROM   t_perfiles perfil_1
           JOIN t_perfiles perfil_2
           ON perfil_1.area = perfil_2.area AND
              perfil_1.perfil > perfil_2.perfil
), t_distancias AS (
    SELECT area,
           perfil_1,
           perfil_2,
           (
                WITH p_interseccion AS (
                    SELECT UNNEST(perfil_1) AS palabra
                    INTERSECT
                    SELECT UNNEST(perfil_2)
                ), p_union AS (
                    SELECT UNNEST(perfil_1) AS palabra
                    UNION
                    SELECT UNNEST(perfil_2)
                ), d_interseccion AS (
                    SELECT COALESCE(SUM(pa.idf), 0.0) AS suma
                    FROM   p_interseccion
                           JOIN palabras_area pa
                           ON ps.area = pa.area AND
                              p_interseccion.palabra = pa.palabra
                ), d_union AS (
                    SELECT SUM(pa.idf) AS suma
                    FROM   p_union
                           JOIN palabras_area pa
                           ON ps.area = pa.area AND
                              p_union.palabra = pa.palabra
                )
                SELECT 1.0 - (d_interseccion.suma / d_union.suma)
                FROM   d_interseccion, d_union
           ) AS distancia
    from   t_pares ps
), t_vectores AS (
    SELECT area, perfil_1, perfil_2, distancia FROM t_distancias
    UNION
    SELECT area, perfil_2, perfil_1, distancia FROM t_distancias
    UNION
    SELECT area, perfil, perfil, 0.0 FROM t_perfiles
    ORDER BY 1, 2, 3
), t_matriz AS (
    SELECT   area,
             perfil_1 AS perfil,
             ARRAY_AGG(distancia ORDER BY perfil_2) AS vector
    FROM     t_vectores
    GROUP BY area,
             perfil_1
    ORDER BY area,
             perfil_1
), t_pares_matriz AS (
    SELECT  v1.area,
            v1.perfil AS perfil_1,
            v1.vector AS vector_1,
            v2.perfil AS perfil_2,
            v2.vector AS vector_2
    FROM    t_matriz v1
            JOIN t_matriz v2
            ON v1.area = v2.area AND
               v1.perfil < v2.perfil
), t_distancias_matriz AS (
    SELECT  area,
            perfil_1,
            perfil_2,
            1.0 -
            (
                SELECT SUM(a * b) AS dot_product
                FROM   UNNEST(vector_1, vector_2) p(a, b)
            ) /
            (
                SELECT
                    (SELECT SQRT(SUM(p1 * p1)) FROM UNNEST(vector_1) p1) *
                    (SELECT SQRT(SUM(p2 * p2)) FROM UNNEST(vector_2) p2)
                    AS magnitude
            ) AS distancia -- 1.0 - similitud_coseno
    FROM    t_pares_matriz
), t_estad_distancias AS (
    SELECT   area,
             MIN(distancia) AS min,
             MAX(distancia) - MIN(distancia) AS denom
    FROM     t_distancias_matriz
    GROUP BY area
), t_distancias_normalizadas AS (
    SELECT dm.area,
           dm.perfil_1,
           dm.perfil_2,
           (dm.distancia - em.min) / em.denom AS distancia
    FROM   t_distancias_matriz dm
           JOIN t_estad_distancias em ON dm.area = em.area
    UNION
    SELECT  area,
            perfil,
            perfil,
            0.0
    FROM    t_perfiles
)
SELECT   area,
         perfil_1,
         perfil_2,
         distancia
FROM     t_distancias_normalizadas
WHERE    distancia < 0.5
ORDER BY area, perfil_1, distancia, perfil_2;
