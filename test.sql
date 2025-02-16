\timing on
\set ECHO all
\set ON_ERROR_STOP on

WITH palabras_alfabeticas AS (
    SELECT   nombre,
             posicion,
             palabra
    FROM     palabras_nombre
    WHERE    palabra ~ '^[A-ZÑ]+$'
    ORDER BY nombre, posicion
), palabras_conocidas AS (
    SELECT palabra FROM diccionario
    UNION
    SELECT palabra FROM nombres_personales
), palabras_no_conocidas AS (
    SELECT palabra FROM palabras_alfabeticas
    EXCEPT
    SELECT palabra FROM palabras_conocidas
), abreviaturas AS (
    SELECT DISTINCT n.palabra
    FROM    palabras_no_conocidas n
            JOIN palabras_nombre p ON n.palabra || '.' = p.palabra
    WHERE   LENGTH(p.palabra) <= 5 -- kludge
), nombres_alfabeticos AS (
    SELECT   nombre,
             ARRAY_AGG(n.palabra ORDER BY n.palabra) AS palabras
    FROM     palabras_alfabeticas p
             JOIN palabras_no_conocidas n ON p.palabra = n.palabra
    WHERE    n.palabra NOT IN (SELECT palabra FROM abreviaturas)
    GROUP BY nombre
    ORDER BY nombre
)
SELECT   palabras,
         ARRAY_AGG(nombre ORDER BY nombre) AS nombres
FROM     nombres_alfabeticos
WHERE    array_length(palabras, 1) > 1
GROUP BY palabras
ORDER BY palabras;
