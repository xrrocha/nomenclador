# _Nomenclador_: Una Aventura en Estandarización de Datos

## Diccionario oficial de palabras empleadas en nombres de escuela

Tenemos un corpus de 11.185 nombres oficiales de escuela localizadas en 1.072
áreas geográficas.

Cada registro de este corpus contiene tres campos:

- El código del área geográfica
- El nombre oficialmente registrado de la escuela
- El código oficial (globalmente único) asignado a la esculea

|  Área  |        Nombre            | Código |
|--------|--------------------------|-------:|
| 010101 | 3 DE NOVIEMBRE           | 11214  |
| 010102 | AURELIO AGUILAR VASQUEZ  | 11240  |
| 010103 | 12 DE ABRIL              | 11255  |
| 010104 | 13 DE ABRIL              | 11248  |
| 010105 | CARLOS ARIZAGA VEGA      | 11217  |
| 010106 | ALFONSO CORDERO PALACIOS | 11560  |
| 010107 | ALIANZA FRANCESA         | 11265  |
| 010108 | CAZADORES DE LOS RIOS    | 11605  |
| 010109 | ANDRES F.CORDOVA         | 11275  |
| 010110 | LUIS CORDERO CRESPO      | 11282  |
| 010111 | ANGELA RODRIGUEZ         | 11221  |
| 010112 | ANGEL POLIBIO CHAVEZ     | 11514  |

Nuestro objetivo es analizar los nombres oficiales de las escuelas para:

- Depurar y uniformizar los nombres oficiales para corrigiendo errores de tecleo
  y eliminando inconsistencias de formato
- Construir un diccionario de palabras "oficiales" empleadas en los nombres de
  las escuelas

El diccionario de palabras oficiales será (sumamente) útil en la estandarización
y corrección de nombres transcritos en las encuestas.
 
## Estandarización de nombres de escuela oficiales

Dado que estos nombres de escuela son oficiales la mayoría de ellos están
correctamente escritos pero se observa cierta irregularidad en el uso de
acentos, signos de puntuación e, incluso, de caracteres alfabéticos:

|                   Nombre                     |
|----------------------------------------------|
| UNIDAD EDUCATIVA DEL SUR **(T.S.E.C.P.P)**   |
| INTI RAYMI **(**SAN ROQUE**)**               |
| GRUPO DE **C.#.36** YAGUACHI (INDIGENA)      |
| SIN NOMBRE **<**EL ESFUERZO**>**             |
| CABO CARLOS MEJIA, **FAE-3  # 1**            |
| ROSARIO DE ALCAZAR **N=1**                   |
| EUGENIO DE SANTA CRUZ Y **ESPEJO(CERRADA)**  |
| SIN NOMBRE **[MOROCHO/ANT/SOTOMAYOR]**       |
| **"TECNICO AGROPECUARIO ""MOCACHE"""**       |
| VASCO NÚÑEZ DE **BALBOA(CERRADA)**           |
| DAULE **#3%**                                |
| SIN NOMBRE (DAULE) **# 3**                   |
| RIO DAULE **(# 19)**                         |
| HECTOR LARA ZAMBRAN**0**                     |
| J**0**SÉ DE ANTEPARA                         |
| JOS**É** MIGUEL ONTANEDA TORRES              |
| JOS**E** MIGUEL ONTANEDA T.                  |

La estandarización no busca "corregir" los nombres sino reducirlos a una forma
regular que permita agrupar correctamente nombres _semejantes_ (no
necesariamente idénticos).

Así, una vez estandarizados los nombres anteriores lucirían como:


|                   Nombre                     |              Nombre Normalizado        |
|----------------------------------------------|----------------------------------------|
| UNIDAD EDUCATIVA DEL SUR **(T.S.E.C.P.P)**   | UNIDAD EDUCATIVA DEL SUR T.S.E.C.P.P.  |
| INTI RAYMI **(**SAN ROQUE**)**               | INTI RAYMI SAN ROQUE                   |
| GRUPO DE **C.#.36** YAGUACHI (INDIGENA)      | GRUPO DE C. #36 YAGUACHI INDIGENA      |
| SIN NOMBRE **<**EL ESFUERZO**>**             | SIN NOMBRE EL ESFUERZO                 |
| CABO CARLOS MEJIA, **FAE-3  # 1**            | CABO CARLOS MEJIA, FAE 3 #1            |
| ROSARIO DE ALCAZAR **N=1**                   | ROSARIO DE ALCAZAR #1                  |
| EUGENIO DE SANTA CRUZ Y **ESPEJO(CERRADA)**  | EUGENIO DE SANTA CRUZ Y ESPEJO CERRADA |
| SIN NOMBRE **[MOROCHO/ANT/SOTOMAYOR]**       | SIN NOMBRE MOROCHO ANT SOTOMAYOR       |
| **"TECNICO AGROPECUARIO ""MOCACHE"""**       | TECNICO AGROPECUARIO MOCACHE           |
| VASCO NÚÑEZ DE **BALBOA(CERRADA)**           | VASCO NUÑEZ DE BALBOA CERRADA          |
| DAULE **#3%**                                | DAULE #3                               |
| SIN NOMBRE (DAULE) **# 3**                   | SIN NOMBRE DAULE #3                    |
| RIO DAULE **(# 19)**                         | RIO DAULE #19                          |
| HECTOR LARA ZAMBRAN**0**                     | HECTOR LARA ZAMBRANO                   |
| J**0**SÉ DE ANTEPARA                         | JOSE DE ANTEPARA                       |
| JOS*É* MIGUEL ONTANEDA TORRES                | JOSE MIGUEL ONTANEDA TORRES            |
| JOS*E* MIGUEL ONTANEDA T.                    | JOSE MIGUEL ONTANEDA T.                |

### Remoción de Acentos

El primer paso en la estandarización de estos nombres oficiales es _suprimir los
acentos_ a fin de unificar las palabras en que varían solo en el uso de tildes o
diéresis en sus vocales.

Esto es relevante porque los nombres de nuestro corpus están todos escritos en
mayúsculas y en español se solía omitir los acentos en las vocales de palabras
mayúsculas.  Como consecuencia, una misma palabra puede aparecer en ambas formas
(véanse _JOSE_ y _JOSÉ_ en el ejemplo anterior).

```sql
-- desacentuados
SELECT   nombre,
         TRANSLATE(
            nombre,
            'ÁÉÍÓÚÜ',
            'AEIOUU'
        ) AS nombre_normalizado
FROM     escuelas
ORDER BY area,
         nombre;
```

|  Área  |       Nombre Original      |     Nombre Sin Acentos    |
|--------|----------------------------|---------------------------|
| 010102 | AURELIO NIÑO V**Á**SQUEZ   | AURELIO NIÑO V**A**SQUEZ  |
| 010108 | CAZADORES DE LOS R**Í**OS  | CAZADORES DE LOS R**I**OS |
| 010109 | ANDRES F. C**Ó**RDOVA      | ANDRES F. C**O**RDOVA     |
| 010111 | **Á**NGELA RODRIGUEZ       | **A**NGELA RODRIGUEZ      |
| 010112 | ANGEL POLIBIO CH**Á**VEZ   | ANGEL POLIBIO CH**A**VEZ  |
| 120103 | RAQUEL AG**Ü**ERO          | RAQUEL AG**U**ERO         |


> 👉 Nótese que la letra `Ñ` _NO_ se translitera!

### Análisis de signos de puntuación

El siguiente paso en la estandarización de estos nombres oficiales es suprimir
los signos de puntación innecesarios, en la medida en que estos no contribuyan a
la formación de palabras.

Así, por ejemplo, los caracteres empleados para rodear texto (paréntesis,
corchetes, etc.) pueden ser suprimidos sin pérdida semántica

|                   Nombre                       |              Nombre Normalizado        |
|------------------------------------------------|----------------------------------------|
| UNIDAD EDUCATIVA DEL SUR **(**T.S.E.C.P.P**)** | UNIDAD EDUCATIVA DEL SUR T.S.E.C.P.P.  |
| INTI RAYMI **[**SAN ROQUE**]**                 | INTI RAYMI SAN ROQUE                   |
| SIN NOMBRE **<**EL ESFUERZO**>**               | SIN NOMBRE EL ESFUERZO                 |

Para determinar qué símbolos de puntuación están presentes en el corpus basta
con considerar todos los caracteres que no sean espacios, alfabéticos o
numéricos:

```sql
-- puntuacion
SELECT   SUBSTR(p, i, 1) AS signo,
         COUNT(*)        AS cuenta
FROM     desacentuados e
         JOIN LATERAL REGEXP_SPLIT_TO_TABLE(
             e.nombre_normalizado,
             '[ [:alpha:][:digit:]]+'
         ) p ON TRUE
         JOIN LATERAL GENERATE_SERIES(
            1, LENGTH(p)
         ) i ON TRUE
GROUP BY signo
ORDER BY 2 DESC, 1;
```

| signo | cuenta|
|-------|-------|
| #     |   2370|
| .     |   2095|
| (     |   1493|
| )     |   1464|
| -     |     79|
| "     |     42|
| °     |     28|
| ,     |     26|
| <     |     16|
| >     |     16|
| /     |     12|
| '     |      7|
| =     |      7|
| [     |      7|
| ]     |      7|
| :     |      5|
| *     |      3|
| ´     |      2|
| _     |      1|

De interés para nuestro propósito son los símbolos:

- Numeral `#`, el más frecuente en todo el corpus
- Punto `.`, el segundo más frecuente y empleado en abreviaturas que requerimos
  preservar
- Superíndice `°`, empleado en abreviaturas como `1°` o `N°`
- Apóstropfe `'`, empleados en ciertos apellidos como `D'ALAMBERT` u
  `O'LEARY`

Una rápida inspección de los signos de puntuación restantes nos muestra que
estos pueden ser removidos (o, más precisamente, _reemplazados por espacios_,
para evitar la juntura accidental de palabras separadas por ellos).

Examinemos estos casos en orden de complejidad relativa:

#### Apóstrofe

Las siguientes palabras ilustran el uso de apóstrofes en el corpus:

```sql
SELECT   palabra,
         COUNT(*)   AS cuenta
FROM     escuelas.escuelas e
         JOIN LATERAL
            REGEXP_SPLIT_TO_TABLE(e.nombre, '\s+') AS palabra
         ON TRUE
WHERE    palabra LIKE '%''%'
GROUP BY PALABRA
ORDER BY 2 DESC, 1;
```

|     Palabra     | Cuenta |
|-----------------|--------|
| O'LEARY         |      2 |
| O'NEIL          |      2 |
| D'ALEMBERT      |      1 |
| **D'LA**        |      1 |
| INVEST.**P'LA** |      1 |

En estas palabras se consideran apropiados los prefijo `D'` antes de una vocal
y `O'` antes de cualquier otro alfabético. En los demás casos se suprime el
apóstrofe (reemplazándolo por un espacio).

#### Superíndice `°`

Las siguientes palabras ilustran los patrones de uso del superíndice `°`:

```sql
SELECT   palabra,
         COUNT(*)   AS cuenta
FROM     escuelas.escuelas e
         JOIN LATERAL
            REGEXP_SPLIT_TO_TABLE(e.nombre, '\s+') AS palabra
         ON TRUE
WHERE    palabra LIKE '%°%'
GROUP BY PALABRA
ORDER BY 2 DESC, 1;
```

|    Palabra    | Cuenta |
|---------------|-------:|
| N°            |      7 |
| N°.           |      3 |
| N°10          |      3 |
| N°2           |      3 |
| N°1           |      2 |
| 1°            |      1 |
| 2°            |      1 |
| **GAMALIEL°** |      1 |

Este superíndice se emplea para construir el prefijo de numeral `N°` así como
los ordinales `1°` y `2°`.

Por razones que se detallan en la siguiente sección es de suma importancia
preservar estos numerales.

En otros casos que no corresponden a numerales (p. ejm., `GAMALIEL°` arriba)
este signo se remueve reemplazándolo por un espacio.

#### Signo de numeral

El signo `#` es especial porque se emplea muy frecuentemente para asociar el
nombre de la escuela con su número:

```sql
SELECT nombre
FROM   escuelas.escuelas
WHERE  nombre ~ '#\s*[[:digit:]]';
```

|            Nombre            |
|------------------------------|
| ELOY ALFARO # 1              |
| REPUBLICA DE BRASIL # 30     |
| TARQUI  # 7                  |
| CONSEJO PROVINCIAL **#518**  |
| BEATRIZ ERAZURI (# 362)      |
| JUAN MONTALVO (# 1)          |

Como se aprecia, la mayoría de tales numerales ocurren con un espacio entre
el signo `#` y los dígitos. Ocasionalmente, sin embargo, se omite este espacio
intermedio y nuestra estandarización debe abarcar ambos casos.

> 👉 En los nombres irregulares que debemos clusterizar también se emplea
profusamente el numeral de la escuela.

Es importante preservar estos numerales _como palabra de diccionario_. Si los
suprimiéramos habría ambigüedad (y, dada nuestra estrategia de clusterización,
pérdida de valiosa información) en casos como:

|            Nombre         |
|---------------------------|
| **24** DE MAYO **# 24**   |
| **3** DE NOVIEMBRE **#3** |

#### Signo punto

El signo punto ocurre frecuentemente en las abreviaturas presentes en nuestro
corpus, incluyendo ciertos usos irregulares que deben ser corregidos como
parte de la normalización:

```sql
SELECT nombre
FROM   escuelas.escuelas
WHERE  nombre ~ '\.';
```

|                    Nombre            |
|------------------------------------- |
| AB. JOAQUIN COLINA                   |
| DOLORES J. TORRES                    |
| DR. ALFARO AUGUSTO DEL POZO          |
| EE.UU. DE NORTEAMERICA # 1           |
| F.A.E.                               |
| GRAL. JOSE DE VILLAMIL               |
| I.T.S. SALESIANO                     |
| ***INST.TEC.SUP.ANDRES F.CORDOVA***  |
| ANDRES **F.CORDOVA**                 |
| **DR.CARLOS** RUFINO MARIN           |
| **INST.PEDAG.INTER.BIL.** (INDIGENA) |
| **INST.TEC.** SUPERIOR TRES DE MARZO |
| **SIN NOMBRE-SAN FRANC.CAÑAY**       |

Los usos apropiados del signo punto en abreviaturas son:

- Una o más letras seguidas de un punto:
  - `AB.` por _ABOGADO_
  - `GRAL.` por _GENERAL_
- Secuencia de una o más parejas de una letra seguida de punto:
  - `F.A.E` por _FUERZA AÉREA ECUATORIANA_
  - `I.T.S.` por _INSTITUTO TÉCNICO SUPERIOR_
- Secuencia de una o más parejas _de un mismo alfabético_ seguido de punto:
  - `EE.UU.` por _ESTADOS UNIDOS_
  - `FF.AA.` por _FUERZAS ARMADAS_

Ocasionalmente en este corpus se omite el punto final de la abreviatura:

- `DR` en vez de `DR.`
- `I.T.S` en vez de `I.T.S.`
- `EE.UU` en vez de `EE.UU.`

_Todos_ los demás usos de punto se reemplazan por un espacio en blanco.
Esto resuelve un error muy común en este corpus consistente en no colocar
espacios en blanco entre abreviaturas consecutivas:

- `INST.PEDAG.INTER.BIL. (INDIGENA)` se separa en
  `INST. PEDAG. INTER. BIL. (INDIGENA)`
- `INST.TEC. SUPERIOR` se separa en `INST. TEC. SUPERIOR`

En los nombres irregulares que debemos clusterizar también se emplean
frecuentemente abreviaturas (así como su concatenación sin espacios).

> 👉 Una buena opción para el diccionario oficial de términos es añadir a las
> abreviaturas mismas sus formas completas. Así, por ejemplo, `LICENCIADO`
> aparecería en el diccionario _aun si en el corpus aparece únicamente la
> abreviatura `LCDO.`_
