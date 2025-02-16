#!/usr/bin/env bash
xz -d < diccionario-completo.tsv.xz |\
sort -u |\
tee diccionario-completo.tsv |\
tr '[:lower:]' '[:upper:]' |\
tr 'ÁÉÈÍÓÚÜ' 'AEEIOUU' |\
sort -u |\
tee diccionario-reducido.tsv |\
xz -z > diccionario-reducido.tsv.xz
