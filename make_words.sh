#!/bin/bash
# make_words.sh — build a sorted, lowercase word list for KeySpeak
#
# Usage: ./make_words.sh [wordlist.txt] [real-dictionary ...]
#   wordlist.txt     one word per line; build.sh passes base.txt (frequency list + extras)
#   names.txt        optional; a NAMES=names.txt environment variable adds these words
#                    AFTER the dictionary filter, so proper names and family words survive it.
#   real-dictionary  optional; keep only words appearing LOWERCASE in these files.
#                    Strips abbreviations and brands (ca, zdnet, html). SCOWL lists work well,
#                    e.g. Debian/Ubuntu wamerican + wbritish (/usr/share/dict/*-english).
# Output: words.txt (space-separated, for embedding in the page)
set -euo pipefail
src="${1:-base.txt}"
shift || true

# 2-letter entries are mostly abbreviations, so only these are allowed through
TWO_LETTER='^(am|an|as|at|be|by|do|go|he|hi|if|in|is|it|me|my|no|of|oh|ok|on|or|ox|so|to|up|us|we)$'
clean() { tr -d '\r' | grep -E '^[a-z]{2,24}$' | grep -E '[aeiouy]' | grep -Ev '^[a-z]{2}$' ; }
two()   { tr -d '\r' | grep -E "$TWO_LETTER"; }

tmp=$(mktemp)
{ tr 'A-Z' 'a-z' < "$src" | clean; echo "$TWO_LETTER" | tr -d '^$()' | tr '|' '\n'; } | LC_ALL=C sort -u > "$tmp"
if [ $# -gt 0 ]; then
  { cat "$@" | clean; cat "$@" | two; } | LC_ALL=C sort -u | LC_ALL=C comm -12 "$tmp" - > "$tmp.f"
  mv "$tmp.f" "$tmp"
fi

if [ -n "${NAMES:-}" ] && [ -f "$NAMES" ]; then   # names bypass the dictionary filter
  { cat "$tmp"; tr 'A-Z' 'a-z' < "$NAMES" | tr -d '\r' | grep -E '^[a-z]{2,24}$'; } | LC_ALL=C sort -u > "$tmp.n"
  mv "$tmp.n" "$tmp"
fi

tr '\n' ' ' < "$tmp" | sed 's/ $//' > words.txt
echo "words.txt: $(wc -w < words.txt | tr -d ' ') words, $(wc -c < words.txt | tr -d ' ') bytes"
rm -f "$tmp"
