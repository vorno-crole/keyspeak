#!/bin/bash
# fetch-sources.sh — download the word-frequency list the build needs.
# Run once after cloning; the file is gitignored because it is large and reproducible.
set -euo pipefail
cd "$(dirname "$0")"
url=https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/en/en_50k.txt
echo "Fetching $url"
curl -fsSLo en_50k.txt "$url"
echo "en_50k.txt: $(wc -l < en_50k.txt | tr -d ' ') lines"

if [ ! -f /usr/share/dict/american-english ]; then
  cat <<'MSG'

The build also cross-filters against SCOWL spelling dictionaries, which are missing.
  Debian/Ubuntu : sudo apt-get install wamerican wbritish
  macOS         : brew install scowl   (then point build.sh at the installed lists)
MSG
fi
