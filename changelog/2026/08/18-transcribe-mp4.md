# Plan: Transcribe a single MP4 (and other non-wav) via `transcribe-file`

| Field | Value |
|-------|--------|
| **Date** | 2026-08-18 |
| **Status** | implemented (option A, 2026-08-18) |
| **Scope** | ASC repo `/home/paul/Documents/asc` — `transcribe-file` converts non-wav (including mp4) to sibling `.wav`, then reuses `transcribe.hook.sh`. Core `convert` / `to_wav` ships under the transcription extension. |
| **Related** | `asc/extensions/transcription/transcribe/file.sh`; `…/transcribe.hook.sh`; `…/instance/transcribe.sh`; `…/convert/to_wav.sh` + `to_wav.hook.sh`; `…/transcribe/ogg.hook.sh`; smoke `…/transcribe/asc/transcribe.test.sh`. Home override still has the `%.ogg` stem bug: `/home/paul/scripts/asc/extend/convert/to_wav.sh`. |
| **Lifecycle** | Plan accepted as option A with recommended defaults for open Qs. Implemented in this tree. Home convert override remains a follow-up. |
| **Living docs** | `asc/extensions/README.md` transcription row; root README catalog; `file.sh` header. |

---

## Context

`transcribe.hook.sh` is the generic ASR implementation. It does **not** parse CLI. It reads an exported `a_*` contract and:

1. If `a_targets` is set, loops those paths and **skips anything that is not an existing `*.wav`**.
2. Else scans `a_input_dir` for `*.wav`.
3. Resolves `transcribe.py` with `hook_ms 'dry-run' -a 'transcribe' -c 'py' …`.
4. Writes per-file `$stem.txt` (or `$stem.$lang.txt` when `a_output_lang` is set) via faster-whisper.
5. Appends that text into `agregated_txt`.

The directory entry `instance/transcribe.sh` and `transcribe/all.sh` already used that contract. `file.sh` was a TODO stub whose header specified the missing single-file path:

```text
make transcribe-file path/to/file.mp4
# Result :
# path/to/file.transcribed.txt
```

MP4 cannot be passed straight to `transcribe.hook.sh` or `transcribe.py` (both require `.wav`). Conversion is the only new work; ASR stays in the existing hook.

**What already converted audio before this change (ogg only, and not in this repo):**

- `ogg.hook.sh` calls `scripts/asc/extend/convert/to_wav.sh "$file"`.
- Home’s `to_wav.sh` exports `file` / `wav_file` then `hook_ms -s 'convert' -a 'to_wav'`.
- Home’s debian-13 hook runs `ffmpeg -i "$file" "$wav_file"`.
- Stem bug: `wav_file="${a_file%.ogg}.wav"` — for `clip.mp4` that becomes `clip.mp4.wav`. This must be `${a_file%.*}.wav` before MP4 (or any non-ogg) can work.

This ASC work tree has **no** `convert` subject (`scripts/asc/extend/` is README-only). `test_convert_to_wav_hook_resolves` therefore cannot pass here until a core default exists.

---

## Goals

1. `make transcribe-file path/to/file.mp4` (and the direct `file.sh` call) produces `path/to/file.transcribed.txt` beside the input.
2. Reuse `transcribe.hook.sh` for ASR — no second Python/whisper path.
3. Convert non-wav input to a sibling `.wav` before the hook runs.
4. Keep the same exported contract as `instance/transcribe.sh`: `a_input_dir`, `a_output_lang`, `a_targets`, `agregated_txt` (plus `a_skip_vscodium` for compatibility).
5. Fail with the usual `Error in $BASH_SOURCE line $LINENO` / `Aborting (N)` pattern.

---

## Non-goals (v1)

- Do not change `transcribe.py` (still wav-only).
- Do not teach `transcribe-all` to scan `*.mp4` (no new `mp4.hook.sh` unless accepted as a follow-up).
- Do not open VSCodium (`file.sh` transcribes an arbitrary path, not the `data/media` inbox).
- Do not auto-install ffmpeg, pipx, or faster-whisper.
- Do not delete or overwrite the source MP4.
- Do not rewrite home’s convert scripts in this change set (call out the `%.ogg` bug as a follow-up when running from `$HOME`).

---

## Approaches

### A — Recommended: `file.sh` converts, then `hook_ms -a transcribe`

`file.sh` is a thin abstract entry (same shape as `instance/transcribe.sh`):

1. Parse one input file + optional `-l|--output-lang`.
2. If the file is not `*.wav`, convert to `${path%.*}.wav`.
3. Export `a_targets` = that wav, `agregated_txt` = `${path%.*}.transcribed.txt`.
4. `hook_ms -a 'transcribe' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'`.

Conversion uses the existing convert contract (`file` + `wav_file` + `hook_ms -s convert -a to_wav`), with a **generic core default** shipped under the transcription extension so this repo works without home’s extend tree.

**Why:** Matches “leverage `transcribe.hook.sh`”. One ASR implementation. MP4 is just another ffmpeg-readable container.

### B — `mp4.hook.sh` parallel to `ogg.hook.sh`

Add `mp4.hook.sh` that scans `a_input_dir` for `*.mp4` and converts them. `transcribe-all` would then pick up MP4s. `file.sh` would still need its own convert-one-file path (the mp4 hook is directory-scan oriented).

**Reject for v1:** Extra surface, does not help the documented `transcribe-file` example unless we also do A. Can be a follow-up if batch MP4 in `data/media` is wanted.

### C — Inline ffmpeg in `file.sh` only

Smallest diff: `ffmpeg` in `file.sh`, no core `convert` subject.

**Reject:** Duplicates home’s convert hook, leaves `ogg.hook.sh` on a hardcoded project path, and leaves `test_convert_to_wav_hook_resolves` failing in this repo.

---

## Locked intent (as implemented)

| Topic | Intent |
|-------|--------|
| **Entry** | `transcribe/file.sh` → `make transcribe-file` |
| **ASR** | Unchanged `hook_ms -a 'transcribe'` → `transcribe.hook.sh` → `transcribe.py` |
| **Convert** | Core subject `convert` / action `to_wav` under the transcription extension; ffmpeg generic hook (tested on debian-13 only, same comment as the other transcription hooks) |
| **Stem** | `wav_file="${input%.*}.wav"` — works for `.mp4`, `.ogg`, `.mkv`, … |
| **Output** | `agregated_txt="${input%.*}.transcribed.txt"` (as in the stub header). Python still also writes `${stem}.txt`; the hook concatenates that into the `.transcribed.txt` name |
| **ffmpeg** | `-y -vn -i … -acodec pcm_s16le -ar 16000 -ac 1` for all convert-to-wav (Q1 = Whisper flags). |
| **Existing wav** | If sibling `.wav` already exists, skip ffmpeg |
| **VSCodium** | Do not launch (`a_skip_vscodium=1`, and do not copy the `codium data/media` block) |
| **ogg.hook.sh** | Switch from hardcoded `scripts/asc/extend/convert/to_wav.sh` to the same `hook_ms -s convert -a to_wav` contract so ogg and mp4 share one converter |

---

## Architecture

```text
make transcribe-file path/to/clip.mp4
        │
        ▼
transcribe/file.sh
        │  parse CLI, require one existing file
        │  if not *.wav:
        │     export file, wav_file="${file%.*}.wav"
        │     hook_ms -s convert -a to_wav
        │        → convert/to_wav.hook.sh (ffmpeg)
        │  export a_targets=$wav_file
        │         a_input_dir=$(dirname)
        │         agregated_txt=${stem}.transcribed.txt
        │         a_output_lang (optional)
        ▼
hook_ms -a transcribe
        │
        ▼
transcribe.hook.sh          # existing, wav-only a_targets loop
        │
        ▼
python transcribe.py clip.wav
        → clip.txt
        → cat into clip.transcribed.txt
```

### Files to add / change (after accept)

| Path | Role |
|------|------|
| `asc/extensions/transcription/transcribe/file.sh` | Complete the stub: parse, convert, export, `hook_ms -a transcribe` |
| `asc/extensions/transcription/convert/to_wav.sh` | **Create** — abstract `make convert-to-wav` entry (parse path, export `file` / `wav_file`, `hook_ms -s convert -a to_wav`). Same idea as home’s script, but `${a_file%.*}.wav` |
| `asc/extensions/transcription/convert/to_wav.hook.sh` | **Create** — generic ffmpeg implementation |
| `asc/extensions/transcription/transcribe/ogg.hook.sh` | Point conversion at the same convert hook (export `file` / `wav_file`, `hook_ms -s convert`) instead of `scripts/asc/extend/convert/to_wav.sh` |
| `asc/extensions/transcription/transcribe/asc/transcribe.test.sh` | Already asserts convert/to_wav resolves; should start passing once core hook exists. Add resolve/existence checks for `file.sh` if cheap |
| `asc/extensions/README.md` | Mention `transcribe-file` + core convert default |

**Not modified:** `transcribe.hook.sh`, `transcribe.py`, `wav.hook.sh`, `instance/transcribe.sh` (unless a comment `@see transcribe.sh` is corrected to `instance/transcribe.sh` — drive-by, optional).

Placing `convert` **under the transcription extension** (not a new top-level extension) keeps enable/disable with transcription and still registers `$subject=convert` `$action=to_wav` for `hook_ms -s convert -a to_wav` and `make convert-to-wav`.

---

## Implemented `file.sh` body (landed)

CLI matches the other transcribe entries (`-l` / `--output-lang`). One positional file. Unknown options abort (1). Missing/non-file abort (1)/(2). Convert failure abort (3).

```bash
. asc/bootstrap.sh

a_input_dir=""
a_output_lang=""
a_skip_vscodium=1
a_targets=""
input_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -l|--output-lang) a_output_lang="$2"; shift 2;;
    -s|--skip-vsc) a_skip_vscodium=1; shift 1;;
    -*)
      echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2
      exit 1
      ;;
    *)
      if [[ -n "$input_file" ]]; then
        echo "Error in $BASH_SOURCE line $LINENO: extra argument: $1" >&2
        exit 1
      fi
      input_file="$1"
      shift 1
      ;;
  esac
done

if [[ -z "$input_file" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - missing input file." >&2
  echo "Aborting (1)." >&2
  echo >&2
  exit 1
fi

if [[ ! -f "$input_file" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - file '$input_file' does not exist." >&2
  echo "Aborting (2)." >&2
  echo >&2
  exit 2
fi

a_input_dir="$(dirname -- "$input_file")"
stem_path="${input_file%.*}"

case "$input_file" in
  *.wav)
    wav_file="$input_file"
    ;;
  *)
    wav_file="${stem_path}.wav"
    if [[ ! -f "$wav_file" ]]; then
      export file="$input_file"
      export wav_file
      hook_ms -s 'convert' -a 'to_wav' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
    fi
    if [[ ! -f "$wav_file" ]]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO - failed to convert '$input_file' to '$wav_file'." >&2
      echo "Aborting (3)." >&2
      echo >&2
      exit 3
    fi
    ;;
esac

agregated_txt="${stem_path}.transcribed.txt"

if [[ -f "$agregated_txt" ]]; then
  echo '' > "$agregated_txt"
else
  touch "$agregated_txt"
fi

a_targets="$wav_file"

export a_input_dir a_output_lang a_skip_vscodium a_targets agregated_txt

hook_ms -a 'transcribe' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
```

Make extra args (usual ASC wrap): `make transcribe-file -- path/to/file.mp4` and `make transcribe-file -- -l fr path/to/file.mp4`. The stub example omits `--`; confirm against `call_wrap` when implementing.

---

## Implemented core `to_wav` (landed)

### `convert/to_wav.sh`

Same structure as home’s script: require `$1` to exist, skip if wav already exists, else export and `hook_ms -s convert -a to_wav`. Difference: `wav_file="${a_file%.*}.wav"` (not `%.ogg`).

### `convert/to_wav.hook.sh`

```bash
# Generic core default (tested on debian-13 only for now).
# Implements hook_ms -s 'convert' -a 'to_wav' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# Expects exported: file, wav_file

ffmpeg -y -vn -i "$file" -acodec pcm_s16le -ar 16000 -ac 1 "$wav_file" > /dev/null 2>&1

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - non-zero status returned by :" >&2
  echo "  ffmpeg -y -vn -i '$file' -acodec pcm_s16le -ar 16000 -ac 1 '$wav_file'" >&2
  echo "Aborting (1)." >&2
  echo >&2
  exit 1
fi
```

`-vn` drops the video stream (required for a sane MP4 → wav). 16 kHz mono PCM matches what Whisper expects. Home’s current hook is bare `ffmpeg -i "$file" "$wav_file"`; a project `scripts/asc/extend/convert/to_wav*.hook.sh` still wins via most-specific lookup when present.

### `ogg.hook.sh` conversion block (intent)

Replace `scripts/asc/extend/convert/to_wav.sh "$file"` with:

```bash
export file
export wav_file
hook_ms -s 'convert' -a 'to_wav' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
```

(`wav_file` is already computed as `${file%.ogg}.wav` in that loop; equivalent to `%.*` for `.ogg` names.)

---

## Side effects on disk

For `path/to/clip.mp4`:

| File | Who writes it |
|------|----------------|
| `path/to/clip.wav` | ffmpeg (convert hook), unless it already existed |
| `path/to/clip.txt` | `transcribe.py` (unchanged) |
| `path/to/clip.transcribed.txt` | `transcribe.hook.sh` concatenating `clip.txt` into `agregated_txt` |

v1 keeps both `.txt` and `.transcribed.txt` (Q2 = keep both; Python / hook unchanged).

---

## Tests (after accept)

Keep smoke tests cheap (no Whisper model download in CI):

1. Existing `test_convert_to_wav_hook_resolves` — must pass once the core hook is in tree.
2. Existing `test_transcribe_action_hook_resolves` — unchanged.
3. Add `test_transcribe_file_script_exists` (or executable) for `asc/extensions/transcription/transcribe/file.sh`.
4. Manual / local only: a short fixture MP4 → confirm wav + `.transcribed.txt`. Do not add a large media fixture to git.

Run: `asc/extensions/transcription/transcribe/asc/transcribe.test.sh`

---

## Safety

- Conversion writes a sibling `.wav` (long videos can be large). Skip ffmpeg when that wav already exists.
- Do not modify or delete the MP4.
- Truncating an existing `.transcribed.txt` matches `instance/transcribe.sh` truncating `transcribed.txt`.
- ffmpeg / Whisper failures abort; do not treat skip-non-wav in the hook as success if convert failed (`file.sh` abort 3).
- Host needs `ffmpeg` on PATH and the same pipx / faster-whisper setup as `make transcribe` today.

---

## Follow-up (out of this change set)

- Home override `/home/paul/scripts/asc/extend/convert/to_wav.sh` still uses `%.ogg`. When ASC is used from `$HOME`, that more-specific script would recreate `clip.mp4.wav`. Fix home’s stem after core lands, or drop the override so core wins.
- Optional `mp4.hook.sh` + `transcribe-all` directory scan (approach B).
- software-deps installer for ffmpeg / faster-whisper (already noted as future on the transcribe hooks).

---

## Open questions (answered with option A defaults)

1. **ffmpeg flags** — Used `-y -vn -i … -acodec pcm_s16le -ar 16000 -ac 1` for all convert-to-wav. Local smoke: generated 0.2s AAC mp4 → `WAVE audio, Microsoft PCM, 16 bit, mono 16000 Hz`.
2. **Two transcript files** — Kept both `clip.txt` (Python) and `clip.transcribed.txt` (`agregated_txt`). No Python / `transcribe.hook.sh` output-name change.
3. **`ogg.hook.sh`** — Switched onto `hook_ms -s convert -a to_wav` in this change.
4. **`convert` subject location** — `asc/extensions/transcription/convert/` (not a new top-level extension).
5. **`transcribe-all` + MP4** — Out of scope. v1 is `transcribe-file` only (no `mp4.hook.sh`).

---

## Implementation tasks

- [x] Task 1: Add `convert/to_wav.sh` + `to_wav.hook.sh`; `transcribe.test.sh` — `test_convert_to_wav_hook_resolves` and `test_convert_to_wav_entry_requires_file` pass.
- [x] Task 2: Complete `file.sh`; abort (1) missing arg / unknown option, abort (2) missing file. `hook_ms` dry-run still resolves transcribe.
- [x] Task 3: Point `ogg.hook.sh` at the convert hook.
- [x] Task 4: `asc/extensions/README.md` + root README catalog; `@see` on `transcribe.hook.sh`.
- [x] Task 5: Local MP4→wav smoke (not committed). This changelog marked implemented.

### Extra (needed for option A to actually dispatch)

`hook_ms` declared `local most_specific_match`, which hid the dry-run result from callers — including `transcribe.hook.sh` looking up `transcribe.py`. Removed that `local` so dry-run writes the caller-scope variable documented on `hook_ms`. Core `asc/test/core/hook.test.sh`: 6/6 OK.

This instance had `transcription` in `scripts/asc/override/.asc_extensions_ignore`, so hook lookup never saw the extension. Removed that line and regenerated `data/asc/cache/asc.sh` (`TRANSCRIPTION_SUBJECTS='convert instance transcribe '`). After changing ignore lists, run `make cc` (or delete `data/asc/cache`) so primitives refresh.

### Verification (2026-08-18)

```text
bash asc/extensions/transcription/transcribe/asc/transcribe.test.sh
# Ran 9 tests. OK

bash asc/test/core/hook.test.sh
# Ran 6 tests. OK

bash asc/extensions/transcription/convert/to_wav.sh /tmp/…/clip.mp4
# convert_status=0 ; clip.wav = PCM 16-bit mono 16000 Hz
```

Full Whisper on an mp4 (`transcribe-file` end-to-end) was not run here (model download / runtime). Convert + abort + hook resolution are covered.

Make extra args: `file.sh` documents `make transcribe-file -- path/to/file.mp4`. Direct call does not need `--`.

