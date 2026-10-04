#!/bin/bash
# build.sh — inject the dictionary into keyspeak.html
#
# Sources:
#   wordlist.txt  the dictionary, one lowercase word per line; edit this to add words
#   names.txt     family and personal names
#   names-au.txt  common Australian given names
#   places.txt    place names
#   blocklist.txt words removed last, e.g. 'yell', which stops 'yellow' being reached
# Names and places are added to the dictionary and are also spoken with a capital.
set -euo pipefail
cd "$(dirname "$0")"

python3 - << 'PY'
import re

def read(path):
    return [w.strip().lower() for w in open(path) if w.strip()]

names = set(read('names.txt') + read('names-au.txt') + read('places.txt'))
names = {n for n in names if re.fullmatch(r'[a-z]{2,24}', n)}
block = set(read('blocklist.txt'))
# The page binary-searches this list, so it must stay sorted.
words = sorted((set(read('wordlist.txt')) | names) - block)

html = open('page.html').read()
assert '__WORDS__' in html and '__NAMES__' in html
html = html.replace('__WORDS__', ' '.join(words)).replace('__NAMES__', ' '.join(sorted(names)))
open('keyspeak.html', 'w').write(html)
print('keyspeak.html:', len(html), 'bytes;', len(words), 'words;', len(names), 'names')
PY
