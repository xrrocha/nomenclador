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
de clusterización `k-means`. Pero esto tampoco funcionaría porque no es simple
determinar en cuántos clústers querríamos dividir cada grupo de nombres por
área geográfica. Para emplear algoritmos de clustering capaces de descubrir
grupos naturales dentro del corpus (p. ejm. `dbscan`) tenemos que identificar
métricas de similitud documental resistentes a los errores de transcripción
de nuestro corpus (p. ejm. `tf-idf`) en combinación con métricas apropiadas
de similitud de cadenas de caracteres (p. ejm. `damerau-levenshtein`).

Dadas estas consideraciones nos proponemos los siguientes objetivos dentro
de nuestra excursión intelectual:

- Estudiar y _entender_ el proceso de clusterización renunciando a la idea
  de que es posible delegarlo de forma "simple" en herramientas establecidas
- **Sacar partido de capacidades avanzadas de SQL (como aquellas presentes en
  Postgres) de forma que el proceso completo se pueda implementar de manera
  simple e inteligible... _empleando únicamente SQL_!**

## Estrategia Nomenclador
