SELECT n.area,
       n.nombre_normalizado,
       p1.palabra AS palabra_1,
       p1.total_ocurrencias AS ocurrencias_1,
       p2.palabra AS palabra_2,
       p2.total_ocurrencias AS ocurrencias_2,
       p3.palabra,
       p3.total_ocurrencias AS ocurrencias_3
FROM nombres_normalizados n
     JOIN LATERAL generate_series(1, n.numero_palabras - 1) s(i) ON TRUE
     JOIN palabras_nombre_area p1
        ON n.area = p1.area AND
            n.nombre_normalizado = p1.nombre_normalizado AND
            s.i = p1.posicion
     JOIN palabras_nombre_area p2
        ON n.area = p2.area AND
           n.nombre_normalizado = p2.nombre_normalizado AND
           s.i + 1 = p2.posicion
     JOIN palabras_area p3
        ON n.area = p3.area AND
           p1.palabra || p2.palabra = p3.palabra AND
           (
                p3.total_ocurrencias > p1.total_ocurrencias AND
                p3.total_ocurrencias > p2.total_ocurrencias
           )
ORDER BY n.area, n.nombre_normalizado, s.i;
