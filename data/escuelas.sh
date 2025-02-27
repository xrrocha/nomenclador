#!/usr/bin/env bash
xz -d < escuelas-2003.tsv.xz |\
awk '
    BEGIN { FS = OFS = "\t" }
    NR > 1 { print sprintf("%02d%02d%02d", $4, $5, $6), $2, $1
}' |\
sed \
    -e 's/^  *//' \
    -e 's/  *$//' \
    -e 's/   */ /g' |\
sort -u |\
xz -z > escuelas.tsv.xz
