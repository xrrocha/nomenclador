#!/usr/bin/env bash
xz -d < escuelas-2003.tsv.xz |\
awk '
    BEGIN { FS = OFS = "\t"}
    NR > 1 { printf("%02d%02d%02d\t%s\t\%s\n", $4, $5, $6, $2, $1) }
' |\
xz -z > escuelas.tsv.xz
