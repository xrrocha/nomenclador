# _Nomenclador_: Una Aventura en Estandarización de Datos

## Diccionario oficial de palabras empleadas en nombres de escuela

Tenemos un corpus de 11.185 nombres oficiales de escuela localizadas en 1.072 áreas
geográficas.

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

- Depurar y uniformizar los nombres oficiales para corregir errores de tecleo y
  eliminar inconsistencias de formato
- Construir un diccionario de palabras "oficiales" empleadas en los nombres de
  las escuelas

El diccionario de palabras oficiales será (sumamente) útil en la estandarización y
corrección de nombres transcritos en las encuestas.
 
## Estandarización de nombres de escuela oficiales

Dado que estos nombres de escuela son oficiales la mayoría de ellos están
correctamente escritos pero se observa cierta irregularidad en el uso de espacios,
signos de puntuación e, incluso, de caracteres alfabéticos:

|  Área  |                     Nombre                   | Código |
|--------|----------------------------------------------|-------:|
| 170119 | UNIDAD EDUCATIVA DEL SUR **(T.S.E.C.P.P)**   | 1119   |
| 170115 | INTI RAYMI **(**SAN ROQUE**)**               | 1154   |
| 100154 | GRUPO DE **C.#.36** YAGUACHI (INDIGENA)      | 1165   |
| 170606 | SIN NOMBRE **<EL ESFUERZO>**                 | 1482   |
| 092056 | CABO CARLOS MEJIA, **FAE-3  # 1**            | 1846   |
| 170156 | ROSARIO DE ALCAZAR **N=1**                   | 1857   |
| 120901 | EUGENIO DE SANTA CRUZ Y **ESPEJO(CERRADA)G*  | 13135  |
| 120851 | SIN NOMBRE   **[MOROCHO/ANT/SOTOMAYOR]**     | 13159  |
| 121201 | **"TECNICO AGROPECUARIO ""MOCACHE"""**       | 13536  |
| 121201 | VASCO NUÑEZ DE **BALBOA(CERRADA)**           | 14323  |
| 090601 | DAULE  **#3%**                               | 14329  |
| 090601 | SIN NOMBRE (DAULE) **# 3**                   | 14347  |
| 090601 | RIO DAULE  **(# 19)**                        | 14393  |
| 040153 | HECTOR LARA ZAMBRAN**0**                     | 2764   |
| 120651 | J**0**SÉ DE ANTEPARA                         | 13234  |
| 110202 | JOS*É* MIGUEL ONTANEDA TORRES                | 2382   |
| 110202 | JOS*E* MIGUEL ONTANEDA TORRES                | 2383   |

### Remoción de Acentos

El primer paso en la estandarización de estos nombres oficiales es _suprimir los
acentos_ a fin de unificar las palabras en que fueron escritas con tildes o
diéresis.

Esto se requiere porque, con frecuencia, algunos nombres que deberían contener
tildes o diéresis fueron registrados sin ellas. Al unificar estas vocales se
posibilita considerar como equivalentes nombres que únicamente difieren en este
aspecto.

```sql
SELECT   nombre,
         TRANSLATE(nombre, 'ÁÉÍÓÚÜ', 'AEIOUU') AS nombre_normalizado
FROM     escuelas
ORDER BY area, nombre;
```

|  Área  |            Nombre          |    Nombre Sin Acentos     |
|--------|----------------------------|---------------------------|
| 010102 | AURELIO NIÑO V**Á**SQUEZ   | AURELIO NIÑO V**A**SQUEZ  |
| 010108 | CAZADORES DE LOS R**Í**OS  | CAZADORES DE LOS R**I**OS |
| 010109 | ANDRES F. C**Ó**RDOVA      | ANDRES F. C**O**RDOVA     |
| 010111 | **Á**NGELA RODRIGUEZ       | **A**NGELA RODRIGUEZ      |
| 010112 | ANGEL POLIBIO CH**Á**VEZ   | ANGEL POLIBIO CH**A**VEZ  |
| 120103 | RAQUEL ROMERO AG**Ü**ERO   | RAQUEL ROMERO AG**U**ERO  |


> 👉 Nótese que la letra `Ñ` _NO_ se translitera!

### Remoción de signos de puntuación

El segundo paso en la estandarización de estos nombres oficiales es _suprimir los
signos de puntación_, en la medida en que estos no juegan un papel en la
construcción del diccionario.

Sin embargo, en este paso, se preservan los siguientes signos de puntuación:

- El punto (`.`), empleado en abreviaturas que se deben preservar (y, en lo
  posible, reemplazar por su forma completa)
- El singo numeral (`#`) ampliamente empleado para numerar las escuelas dentro de
  su área (`# 123`, `#234`)
- El superíndice `ᵒ` empleado en:
  - Ordinales (`1°`, `2°`)
  - Ciertas abreviaturas (`N°` por `#` o `Edᵒ` por `Eduardo`)
- El superíndice `ᵃ` empleado en algunas abreviaturas de nombres femeninos
  (`Mᵃ` por `María`)

Todos los demas signos de puntuacion se reemplazan por espacios:

```sql
SELECT REGEXP_REPLACE(
            nombre,
            '[][,;:"()<>{}`´~!/*_&^%$@!=-]',
            ' ', -- reemplazar por un blanco...
            'g'  -- ...globalmente
       ) AS nombre_normalizado
FROM   escuelas
```
