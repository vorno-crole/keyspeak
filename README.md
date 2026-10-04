# KeySpeak

A single-page typing toy. Every key says its letter out loud, and when the letters
spell a word, it says the word. Built for a child learning letters; it works with any
keyboard, and on a tablet with none via the on-screen keys.

Speech uses the browser's Web Speech API, so the voices are whatever the device
already has. There is no build step for the page itself — `keyspeak.html` is a single
self-contained file with the dictionary embedded. Open it, or host it anywhere static.

## How it decides when to speak a word

Letters are spoken as they are typed. The word in progress is held in a buffer and
checked against a sorted dictionary with binary search. The buffer is spoken when:

- **Space or Enter** is pressed, or
- no longer word starts with it (`zebra` has nothing after it, so it fires at once), or
- a **pause** passes with the buffer being a valid word.

That pause is measured from the moment the last letter finishes being *spoken*, not
from the keystroke. The voice runs behind the typist, and starting the clock at the
keystroke would cut `alexander` into `alex` + `ander` for anyone typing at a normal
pace. Waiting for the voice to catch up first lets a fast typist reach the longer word.

If the buffer can no longer become any word, the leading letters are dropped until the
remainder is viable again — typing `xqzdog` still says `dog`. A buffer that is not a
word is discarded after 10 seconds. Backspace deletes a letter; Esc clears.

Letters are batched into a single utterance when typing outruns the voice, because each
`speechSynthesis.speak()` call carries 100–200 ms of fixed overhead regardless of how
short the text is. Speaking them one at a time cannot keep up with a fast typist. The
rate also rises slightly while a backlog exists, and a watchdog advances the queue if
the browser never fires `onend`, which some do on very short utterances.

## Files

| File | What it is |
|---|---|
| `keyspeak.html` | **The deliverable.** Self-contained page, dictionary embedded. |
| `page.html` | Source template. Same page with `__WORDS__` and `__NAMES__` placeholders. |
| `build.sh` | Builds the dictionary and fills the placeholders. |
| `make_words.sh` | Dictionary filter: frequency list ∩ SCOWL, plus the name bypass. |
| `fetch-sources.sh` | Downloads the frequency list (gitignored, large, reproducible). |
| `extras.txt` | Everyday words a frequency corpus under-weights: zebra, sock, kite. |
| `names.txt` | Family and personal names. |
| `names-au.txt` | Common Australian given names. |
| `places.txt` | Place names. |

Edit `page.html`, never `keyspeak.html` — the latter is generated and overwritten.

## Building

```bash
./fetch-sources.sh     # once: downloads en_50k.txt
./build.sh             # regenerates words.txt and keyspeak.html
```

Needs bash, awk, python3 and the SCOWL dictionaries (`sudo apt-get install wamerican
wbritish`, which provide `/usr/share/dict/*-english`).

To add a name, append a line to `names.txt` and rebuild. Names go in these files rather
than in `extras.txt` because the SCOWL cross-filter only holds names capitalised and
would strip them; the `NAMES=` path merges them *after* that filter runs.

Dictionary size is set by `FREQ_TOP`, default 20000, giving about 15,500 words after
filtering:

```bash
FREQ_TOP=30000 ./build.sh    # ~21,000 words
```

## Vocabulary sources

The base is the top `FREQ_TOP` entries of a frequency list built from film and TV
subtitles ([hermitdave/FrequencyWords](https://github.com/hermitdave/FrequencyWords),
2018 English). Conversational English suits this better than a web corpus — an earlier
build on the Google 10k web list was missing *dinosaur*, *rosemary* and *melbourne*.
Spelling is sanity-checked against SCOWL, which drops abbreviations and brand names.

Australian given names were seeded from the 2025 state registry announcements
([WA](https://www.wa.gov.au/government/announcements/new-baby-names-enter-was-most-popular-lists-2025),
[SA](https://www.cbs.sa.gov.au/news/most-popular-baby-names-for-2025),
[NSW](https://www.amrtimes.com.au/lifestyle/nsw-registry-of-births-deaths-and-marriages-reveals-top-baby-names-for-2025-surprising-entries-on-list-c-22049020)),
which publish only a top 10 plus new entries. The rest of `names-au.txt`, covering older
generations, was compiled by hand and is not sourced from registry data.

## Pronunciation

Names are sent to the voice capitalised, which makes most engines read them as names.
`SAY_AS` in `page.html` holds respellings for the ones that still come out wrong —
currently `vaughan` → `Vaughn`. The display always shows the real spelling.

## Settings

Voice, speed, letter names vs phonics (`buh, ah, tuh`), pause length, and whether whole
words are spoken. Stored in `localStorage` per browser.

## Known limits

- **Sound needs one interaction first.** Browsers block audio until the user acts, so the
  first keypress or tap is what starts it. The button afterwards is a mute toggle.
- **At full touch-typing speed the voice cannot stay in real time.** Saying "double you"
  takes longer than pressing W. Nothing fixes that; the queue stays complete and catches
  up during pauses rather than skipping.
- **Voice quality varies by device.** Chrome on Android and Safari on iOS are good; some
  Linux and older Android voices are rough. That is the OS's, not the page's.
- **Turning letters off removes the typing cushion**, since the pause then starts at the
  keystroke — there is no speech to wait for.
