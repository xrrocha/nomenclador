#!/usr/bin/env bash
xz -d < diccionario-completo.tsv.xz |\
tr '[:lower:]' '[:upper:]' |\
tr 'ÁÉÍÓÚÜ' 'AEIOUU' |\
sort -u |\
xz -z > diccionario-reducido.tsv.xz
