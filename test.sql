SELECT n.area,
       n.nombre_normalizado,
       pn1.palabra AS palabra_1,
       p1.total_ocurrencias AS ocurrencias_1,
       pn2.palabra AS palabra_2,
       p2.total_ocurrencias AS ocurrencias_2,
       p3.palabra,
       p3.total_ocurrencias AS ocurrencias_3
FROM nombres_normalizados n
     JOIN LATERAL generate_series(1, n.numero_palabras - 1) s(i) ON TRUE
     JOIN palabras_nombre_area pn1
        ON n.area = pn1.area AND
            n.nombre_normalizado = pn1.nombre_normalizado AND
            s.i = pn1.posicion
     JOIN palabras_nombre_area pn2
        ON n.area = pn2.area AND
           n.nombre_normalizado = pn2.nombre_normalizado AND
           s.i + 1 = pn2.posicion
     JOIN palabras_area p3
        ON n.area = p3.area AND
           pn1.palabra || pn2.palabra = p3.palabra
     JOIN palabras_area p1
        ON p3.area = p1.area AND
           pn1.palabra = p1.palabra
     JOIN palabras_area p2
        ON p3.area = p2.area AND
           pn2.palabra = p2.palabra
WHERE    p3.total_ocurrencias > p1.total_ocurrencias OR
         p3.total_ocurrencias > p2.total_ocurrencias
ORDER BY n.area, n.nombre_normalizado, s.i;
