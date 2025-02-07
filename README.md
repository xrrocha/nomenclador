# Nomenclador: Una Aventura de Estandarización de Datos

## Problema Original

Tenemos un corpus de 439.761 nombres de escuelas localizadas en 1.166
áreas geográficas.

La mayoría de estos nombres contienen errores de transcripción y ortografía,
así como variantes en el orden y ocurrencia de las palabras o en el uso de
abreviaturas.

La siguiente tabla ilustra algunas variantes de dos de los nombres más
frecuentes en el corpus:

|       Fe y Alegría      |        Manuel Abad       |
|-------------------------|--------------------------|
|FE ALEGRIA # 1 ESC       |COL. MANUEL ABAD #37      |
|FE ALEGRIA #1 ESC        |COLEGIO MANUEL ABAD       |
|FE ALEGRIA COL.          |ESC. MANUEL ABAD          |
|FE ALEGRIA ESC           |ESC. MANUELA ABAD         |
|FE ALEGRIA ESC.          |ESCUELA MANUEL ABAD       |
|FE ALEGRIA(ESC)          |JARDIN MANUEL ABAD        |
|FE I¿Y ALEGRIA # 10 ESC-.|MANUELA ABAD JARD.        |
|FE NY ALEGRIA-ESC        |MANUEL ABAD               |
|FE T ALEGRIA. ESC.       |MANUEL ABAD COL. 37       |
|FE Y AALEGRIA ESC        |MANUEL ABAD ESC           |
|FE Y ALEGRIA             |MANUEL ABADF ESC.         |
|FE Y ALEGRIA # .2.       |MANUEL ABAD GOMEZ ESC     |

Cada registro del corpus contiene tres campos:

- El código de área geográfica
- El nombre transcrito a ser estandarizado
- El número de ocurrencias del nombre en su área

| Área |       Nombre        |#|
|------|---------------------|-:|
|010101|12 DE ABRIL ESC      |3 |
|010101|12 DE ABRIL ESC.     |2 |
|010101|13 DE ABRIL ESC      |1 |
|010101|2CARLOS CRESPI ESC   |1 |
|010101|3 DE NAVIEMBRE ESC   |1 |
|010101|3 DE NO VIEMBRE ESC  |1 |
|010101|3 DE NOVIEMBRE       |1 |
|010101|3 DE NOVIEMBRE (ESC) |9 |
|010101|3 DE NOVIEMBRE /ESC  |1 |
|010101|3 DE NOVIEMBRE ESC   |20|

Nuestra tarea es:

- Agrupar (_clusterizar_) los nombres por su similitud léxica dentro de cada
  área geográfica
- Seleccionar, para cada grupo, el nombre más representativo (_medoide_)
- Localizar cada medoide en un archivo oficial de instituciones educativas
- Identificar nombres equivalentes en áreas geográficas _contiguas_ y
  atribuirlos al área apropiada

> 👉 En este proyecto nos centraremos únicamente en el proceso de
> clusterización como tal

## Estrategias Ingenuas

Cuando el corpus está almacenado en una base de datos relacional parecería
apropiado utilizar SQL para filtrar, agrupar y ordenar los nombres a fin de
identificar qué grupos ocurren en él.

```
3 DE NOVIEMBRE (ESC)
3 DE NOVIEMBRE /ESC
3 DE NOVIEMBRE ESC
```

Pero rápidamente resulta claro que esta estrategía no funcionaría con nombres
como:

```
3 DE NOVIEMBRE ESC
ESC 3 DE NOVIEMBRE #42
```

El orden de las palabras no necesariamente corresponde de nombre en nombre
por una agrupación simple no sería apropiada.

Podría pensarse en separar las palabras, reemplazarlas por su representación
_fonética_ (p. ejm., mediante la función SQL `SOUNDEX`) y luego
"reensamblarlas" para agruparlas mediante `GROUP BY`.

Pero esto también falla cuando aparecen términos diferentes, vocales erradas,
palabras partidas o palabras juntadas (para no mencionar que los caracteres no
alafabéticos carecen de representación fonética).

```
ESC #3 DE NAVIEMBRE
3 DE NO VIEMBRE ESC
3 DENOVIEMBRE
``` 

Claramente, se necesita algo más que SQL básico. Se necesita _clusterizar_,
una operación para la que las diferentes variantes de SQL no suelen ofrecer
una solución expedita.

Por supuesto, hay herramientas de aprendizaje maquinal (_machine learning_)
que se podrían utilizar para este propósito. No obstante, el uso de tales
herramientas _no_ es trivial y trae consigo su propia carga de complejidad
impuesta por los algoritmos seleccionados y por las herramientas mismas.

Un científico de datos apresurado podría querer emplear el popular algoritmo
de clusterización `k-means`. Pero esto tampoco funcionaría porque no es
factible anticipar en cuántos clústers querríamos dividir cada grupo de
nombres por área geográfica. Para emplear algoritmos de clustering capaces
de descubrir grupos naturales dentro del corpus (p. ejm. `dbscan`) tenemos
que identificar métricas de similitud documental resistentes a los errores
de transcripción de nuestro corpus (p. ejm. `tf-idf`) en combinación con
métricas apropiadas de similitud de cadenas de caracteres (p. ejm.
`damerau-levenshtein`).

Dadas estas consideraciones nos proponemos los siguientes objetivos dentro
de nuestra excursión intelectual:

- Estudiar y _entender_ el proceso de clusterización renunciando a la idea
  de que es posible delegarlo de forma "simple" en herramientas establecidas
- **Sacar partido de capacidades avanzadas de SQL (como aquellas presentes en
  Postgres) de forma que el proceso completo se pueda implementar de manera
  simple e inteligible... _empleando únicamente SQL_!**

## Estrategia Inicial de Exploración

El primer paso en la exploración de una solución apropiada involucra:

- Normalizar los nombres removiendo caracteres no alfanuméricos
- Clusterizar los nombres resultantes empleando:
  - La métrica de similitud documental `jaccard` (también conocida como
    `tanimoto`)
  - El algoritmo de clusterización `dbscan`
- Identificar y corregir errores de transcripción y ortografía, reforzando
  la normalización de los nombres

Al analizar los resultados se irá refinando el proceso, empleando, por
ejemplo una métrica combinada de distancia de edición (p. ejm. `levenshtein`)
y de co-ocurrencia de términos.

## Carga de datos en Postgres

El primer paso es cargar nuestro corpus a Postgres:

```sql
CREATE TABLE nombres (
    area_geografica VARCHAR(6)  NOT NULL,
    nombre          VARCHAR(48) NOT NULL,
    ocurrencias     INTEGER     NOT NULL
);

\COPY nombres FROM ../src/corpus.tsv DELIMITER E'\t';
```

Los primeros registros de esta tabla lucen como:

```sql
  area  |                  nombre                  | ocurrencias
--------+------------------------------------------+-------------
 010101 | 12 DE ABRIL ESC                          |           3
 010101 | 12 DE ABRIL ESC.                         |           2
 010101 | 13 DE ABRIL ESC                          |           1
 010101 | 2CARLOS CRESPI ESC                       |           1
 010101 | 3 DE NAVIEMBRE ESC                       |           1
 010101 | 3 DE NO VIEMBRE ESC                      |           1
 010101 | 3 DE NOVIEMBRE                           |           1
 010101 | 3 DE NOVIEMBRE (ESC)                     |           9
 010101 | 3 DE NOVIEMBRE /ESC                      |           1
 010101 | 3 DE NOVIEMBRE ESC                       |          20
```

## Normalización de Nombres

Nuestra estrategia inicial de normalización de los nombres es simple:
remover todo carácter no alfabético o numérico de cada palabra del nombre:

```sql
-- Generar nombres normalizados
ALTER TABLE nombres ADD COLUMN nombre_normalizado VARCHAR(48);

UPDATE nombres
SET    nombre_normalizado = (
            SELECT  ARRAY_TO_STRING(ARRAY_AGG(palabra), ' ')
            FROM    (
                        SELECT REGEXP_SPLIT_TO_TABLE(
                            nombre,
                            '[^[:alnum:]]'
                        ) AS palabra
                    )
            WHERE   palabra != ''
       );
```

Con los nombres normalizados nuestra tabla `nombres` ahora luce como:

```sql
  area  |            nombre             | ocurrencias |      nombre_normalizado
--------+-------------------------------+-------------+------------------------------
 010101 | ALBORADA JARDIN               |           1 | ALBORADA JARDIN
 010101 | ALFONSO CORDERO (ESC)         |           2 | ALFONSO CORDERO ESC
 010101 | ALFONSO CORDERO ESC           |          15 | ALFONSO CORDERO ESC
 010101 | ALFONSO CORDERO ESC.          |           7 | ALFONSO CORDERO ESC
 010101 | ALFONSO CORDERO PALACIOS ESC  |           3 | ALFONSO CORDERO PALACIOS ESC
 010101 | ALFONSO CORDERO PALACIOS ESC. |           3 | ALFONSO CORDERO PALACIOS ESC
 010101 | ALKFONSO CORDERO ESC          |           1 | ALKFONSO CORDERO ESC
 010101 | ALKFONSO CORDERO ESEC         |           1 | ALKFONSO CORDERO ESEC
 010101 | AMERICANO BILINGUE JARD.      |           1 | AMERICANO BILINGUE JARD
 010101 | AMERICANO COL                 |           3 | AMERICANO COL
 010101 | AMERICANO COL.                |           3 | AMERICANO COL
 010101 | AMERICANO ESC                 |           8 | AMERICANO ESC
```

Aquí ya notamos que la remoción de los caracteres especiales reduce el número de
distintos nombres:

```sql
SELECT COUNT(DISTINCT nombre), COUNT(DISTINCT nombre_normalizado)
FROM NOMBRES;
 count |  count
-------+-------
301681 | 228977
```

El número de distintos nombres se ha reducido en más de 72.000 luego de la
normalización!

El siguiente paso es crear una tabla de nombres normalizados por área
geográfica:

```sql
DROP TABLE IF EXISTS nombres_normalizados;

CREATE TABLE nombres_normalizados AS
SELECT   area                 AS area,
         nombre_normalizado   AS nombre_normalizado,
         COUNT(*)             AS cuenta_nombres,
         SUM(ocurrencias)     AS ocurrencias
FROM     nombres
GROUP BY area,
         nombre_normalizado
ORDER BY 1, 2;
```

Los primeros nombres normalizados lucen como:

```
  area  |            nombre_normalizado            | cuenta_nombres | ocurrencias
--------+------------------------------------------+----------------+-------------
 010101 | 12 DE ABRIL ESC                          |              2 |           5
 010101 | 13 DE ABRIL ESC                          |              1 |           1
 010101 | 2CARLOS CRESPI ESC                       |              1 |           1
 010101 | 3 DE NAVIEMBRE ESC                       |              1 |           1
 010101 | 3 DE NOVIEMBRE                           |              1 |           1
 010101 | 3 DE NO VIEMBRE ESC                      |              1 |           1
 010101 | 3 DE NOVIEMBRE ESC                       |              5 |          40
```

Para efectos de clusterización, estos nombres nombres normalizados necesitan ser
vistos como _conjuntos_ sin duplicados y sin preservar el ordenamiento original
de sus palabras. A este conjunto de palabras formado a partir del nombre
normalizado lo denominaremos `perfil`:


```sql
ALTER TABLE nombres_normalizados ADD COLUMN perfil VARCHAR[];

UPDATE nombres_normalizados
SET perfil = (
    Select ARRAY_AGG(palabra ORDER BY PALABRA)
    FROM (
        SELECT DISTINCT palabra
        FROM REGEXP_SPLIT_TO_TABLE(nombre_normalizado, ' ') AS palabra
    )
);
```

Los primeros perfiles lucen como:

```
  area  |        perfil         | nombre_normalizado
--------+-----------------------+---------------------
 010101 | {12,ABRIL,DE,ESC}     | 12 DE ABRIL ESC
 010101 |                       | ESC 12 DE ABRIL
 010101 | {13,ABRIL,DE,ESC}     | 13 DE ABRIL ESC
 010101 | {2CARLOS,CRESPI,ESC}  | 2CARLOS CRESPI ESC
 010101 | {3,DE,ESC,NAVIEMBRE}  | 3 DE NAVIEMBRE ESC
 010101 | {3,DE,ESC,NO,VIEMBRE} | 3 DE NO VIEMBRE ESC
 010101 | {3,DE,ESC,NOVIEMBRE}  | 3 DE NOVIEMBRE ESC
 010101 |                       | ESC 3 DE NOVIEMBRE
 010101 | {3,DE,NOVIEMBRE}      | 3 DE NOVIEMBRE
 010101 | {3,ESC,NOV}           | 3 NOV ESC
```

Es de notar que múltiples nombres normalizados distintos pueden dar origen a un
mismo perfil (como `{12,ABRIL,DE,ESC` y `{3,DE,ESC,NOVIEMBRE}` arriba). Esto
reduce aun más el número de distintos nombres que deben ser clusterizados:

```sql
SELECT COUNT(DISTINCT perfil), COUNT(DISTINCT nombre_normalizado)
FROM   nombres_normalizados ;

count  | count
-------+--------
214869 | 228977
```

Esto reduce en más de 14.000 el numero global de distintos nombres que se
deben clusterizar! 👍

Como último paso de normalización previo a la clusterización crearemos una tabla
de perfiles:

```sql
DROP TABLE IF EXISTS perfiles;

CREATE TABLE perfiles AS
SELECT   area,
         perfil,
         COUNT(*)            AS cuenta_normalizados,
         SUM(cuenta_nombres) AS cuenta_nombres,
         SUM(ocurrencias)    AS ocurrencias
FROM     nombres_normalizados
GROUP BY area,
         perfil
ORDER BY 1, 2;
```

Los primeros registros de nuestra tabla de `perfiles` lucen como:

```
  area  |              perfil               | normalizados | nombres | ocurrencias
--------+-----------------------------------+--------------+---------+-------------
 090112 | {471,ESC,N,S}                     |            9 |      24 |          60
 092056 | {1,ESC,NN,NOCTURNA,S}             |            6 |       7 |          12
 092056 | {ESC,N,NOCTURNA,S}                |            5 |       8 |          14
 090114 | {COL,GUAYAQUIL,NACIONAL}          |            5 |       9 |          14
 090112 | {12,215,DE,ESC,FEBRERO}           |            5 |      17 |         100
 090112 | {194,CESAR,ESC,SALGADO,ZAMORA}    |            5 |      11 |          65
 090104 | {AIDA,DE,ESC,LARA,LEON,RODRIGUEZ} |            5 |       8 |          34
 090112 | {BUCARAM,COL,DE,MARTHA,ROLDOS}    |            5 |       8 |         159
 090112 | {471,ESC,NOMBRE,SIN}              |            5 |      12 |          32
 090112 | {426,ESC,JOSE,MERCHAN,MONTENEGRO} |            5 |      13 |          24
```

Con estos perfiles ya podemos proceder a una forma simple de clusterización.
