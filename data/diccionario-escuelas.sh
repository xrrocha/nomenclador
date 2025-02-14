#!/usr/bin/env bash
xz -d < escuelas-2003.tsv.xz |\
awk '
    BEGIN { FS = OFS = "\t" }
    NR > 1 { print $2, $3
}' ../data/escuelas-sinec.tsv |\
tr '[:lower:]' '[:upper:]' |\
tr 'ÁÉÍÓÚÜ' 'AEIOUU' |\
tr -cs '[:alpha:]' '\n' |
sort -u |\
xz -z > diccionario-escuelas.tsv.xz
