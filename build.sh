#!/bin/bash
# build.sh — regenerate the dictionary and inject it into keyspeak.html
#
# Sources:
#   en_50k.txt    frequency-ranked English (OpenSubtitles via hermitdave/FrequencyWords);
#                 the top FREQ_TOP entries form the base vocabulary
#   extras.txt    everyday words a frequency corpus under-weights (zebra, sock, kite)
#   names.txt     family and personal names
#   names-au.txt  common Australian given names
#   places.txt    place names
# The base is cross-filtered against SCOWL (/usr/share/dict/*-english) to drop
# abbreviations and misspellings; names and places BYPASS that filter, since SCOWL
# only holds them capitalised.
set -euo pipefail
cd "$(dirname "$0")"
FREQ_TOP="${FREQ_TOP:-20000}"

awk -v n="$FREQ_TOP" 'NR<=n{print $1}' en_50k.txt > base.txt
cat extras.txt >> base.txt
sort -u names.txt names-au.txt places.txt > names-all.txt

NAMES=names-all.txt ./make_words.sh base.txt \
  /usr/share/dict/american-english /usr/share/dict/british-english

python3 - << 'PY'
words = open('words.txt').read().strip()
names = ' '.join(sorted(set(open('names-all.txt').read().split())))
html  = open('page.html').read()
assert '__WORDS__' in html and '__NAMES__' in html
open('keyspeak.html', 'w').write(html.replace('__WORDS__', words).replace('__NAMES__', names))
print('keyspeak.html:', len(open('keyspeak.html').read()), 'bytes;', len(names.split()), 'names')
PY
