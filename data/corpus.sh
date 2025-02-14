#!/usr/bin/env bash
xz -d < encuestas-2003.tsv.xz |\
tr -d '"'"'" |\
awk 'NR > 1'|\
awk -F\\t '{ printf("%02d%02d%02d\t%s\n", $1, $2, $3, $5) } ' |\
sed -e 's/ *\t */\t/g' -e 's/  */ /g' -e 's/ *$//' -e '/\t$/d' |\
sort |\
uniq -c |\
sed -e 's/^ *//' -e 's/  */\t/' |\
awk 'BEGIN { FS = OFS ="\t" } { print $2, $3, $1 }' |\
xz -z > corpus.tsv.xz
