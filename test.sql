WITH t_perfiles AS (
    SELECT   area,
             (ROW_NUMBER()
                OVER(ORDER  BY area, ocurrencias DESC, perfil))::INT
                AS id,
             perfil,
             ocurrencias
    FROM     perfiles
    WHERE    area = (
        SELECT   area
        FROM     perfiles
        GROUP BY area
        HAVING   COUNT(*) = 48
        LIMIT    1
    )
    ORDER BY area, ocurrencias DESC, perfil
), t_pares AS (
    SELECT p1.area,
           p1.id      AS id_1,
           p1.perfil  AS perfil_1,
           p2.id      AS id_2,
           p2.perfil  AS perfil_2
    FROM   t_perfiles p1
           JOIN t_perfiles p2
           ON p1.area = p2.area AND
              p1.perfil > p2.perfil
), t_distancias AS (
    SELECT area,
           id_1,
           id_2,
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
    FROM   t_pares ps
), t_vectores AS (
    SELECT area, id_1, id_2, distancia FROM t_distancias
    UNION
    SELECT area, id_2, id_1, distancia FROM t_distancias
    UNION
    SELECT area, id, id, 0.0 FROM t_perfiles
    ORDER BY 1, 2, 3
), t_matriz AS (
    SELECT   area,
             id_1 AS id,
             ARRAY_AGG(distancia ORDER BY id_2) AS vector
    FROM     t_vectores
    GROUP BY area,
             id_1
    ORDER BY area,
             id_1
), t_pares_matriz AS (
    SELECT  v1.area,
            v1.id     AS id_1,
            v1.vector AS vector_1,
            v2.id     AS id_2,
            v2.vector AS vector_2
    FROM    t_matriz v1
            JOIN t_matriz v2
            ON v1.area = v2.area AND
               v1.id < v2.id
), t_distancias_matriz AS (
    SELECT  area,
            id_1,
            id_2,
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
           dm.id_1,
           dm.id_2,
           (dm.distancia - em.min) / em.denom AS distancia
    FROM   t_distancias_matriz dm
           JOIN t_estad_distancias em ON dm.area = em.area
    WHERE  (dm.distancia - em.min) / em.denom < 0.2737
), t_distancias_completas AS (
    SELECT area, id_1, id_2,distancia FROM t_distancias_normalizadas
    UNION
    SELECT area, id_2, id_1, distancia FROM t_distancias_normalizadas
    UNION
    SELECT area, id, id, 0 FROM t_perfiles
), t_pares_finales AS (
SELECT   dn.area,
         dn.id_1,
         dn.id_2
         -- dn.distancia,
         -- ps.ocurrencias
FROM     t_distancias_completas dn
         JOIN t_perfiles ps
         ON dn.area = ps.area AND
            dn.id_1 = ps.id
ORDER BY area,
         ps.ocurrencias DESC,
         distancia,
         id_1,
         id_2
), t_pasos_cluster AS (
    WITH RECURSIVE clusters AS (
        SELECT area,
               id,
               FALSE          AS clustered,
               id             AS num_cluster,
               ARRAY[]::INT[] AS visited
        FROM   t_perfiles
        UNION 
        SELECT p.area,
               p.id_2,
               TRUE,
               LEAST(c.num_cluster, p.id_2),
               visited || p.id_2
        FROM   clusters c
               JOIN t_pares_finales p
               ON c.area = p.area AND
                  c.id = p.id_1
        WHERE  NOT p.id_1 = ANY(c.visited)
    )
    SELECT *
    FROM   clusters
    WHERE  clustered
), t_elementos_cluster AS (
    SELECT c.area,
                    c.num_cluster,
                    c.id,
                    p.perfil
    FROM            t_pasos_cluster c
                    JOIN t_perfiles p
                    ON c.area = p.area AND
                       c.id = p.id
    ORDER BY        c.area, c.num_cluster
), t_clusters AS (
    SELECT   area,
            num_cluster,
            ARRAY_AGG(
                ARRAY_TO_STRING(perfil, ' ')
                ORDER BY id
            )  AS cluster
    FROM     t_elementos_cluster
    GROUP BY area,
            num_cluster
    ORDER BY area,
            num_cluster
)
SELECT num_cluster, array_length(cluster, 1), cluster
FROM (
SELECT num_cluster,
       ARRAY_AGG(
        ARRAY_TO_STRING(p.perfil, ',')
        ORDER BY xvisited
       ) AS cluster
FROM (
        SELECT   area,
                 MIN(num_cluster) AS num_cluster,
                 UNNEST(visited) AS xvisited
        FROM     t_pasos_cluster
        GROUP BY area, xvisited
        ORDER BY area, num_cluster
     ) c
     JOIN t_perfiles p
     ON c.area = p.area AND c.xvisited = p.id
GROUP BY num_cluster
)
ORDER BY ARRAY_LENGTH(cluster, 1) DESC, num_cluster;

-- SELECT area, perfil, num_cluster
-- FROM   t_elementos_cluster
-- ORDER BY 1, 2, 3;

-- SELECT DISTINCT(distancia)
-- FROM t_distancias_normalizadas
-- ORDER BY 1;
