# A3 landscape PDF export

| Field | Value |
|---|---|
| **Date** | 2026-11-18 |
| **Status** | implemented |
| **Scope** | Print pipeline in this repository: [`asc/doc/pdf_export.sh`](../../../../asc/doc/pdf_export.sh), [`asc/doc/md2pdf_asc.py`](../../../../asc/doc/md2pdf_asc.py), [`asc/doc/print_paginate.py`](../../../../asc/doc/print_paginate.py), [`asc/doc/asc/pdf.test.sh`](../../../../asc/doc/asc/pdf.test.sh). [`asc/doc/pdf_styles.css`](../../../../asc/doc/pdf_styles.css) stays `size: A4`. [`asc/doc/html_preview.sh`](../../../../asc/doc/html_preview.sh), [`asc/doc/print_mermaid.py`](../../../../asc/doc/print_mermaid.py), and the Graphviz helpers stay as they are. |
| **Related** | [2026-09-04 PDF generation improvements](../09/04-pdf-generation-improvements.md) (implemented). That plan locked the print pipeline order and the A4 portrait geometry this plan extends. |
| **Checkout** | Line numbers below are from `add1f6c` on 2026-11-18. |
| **Living docs** | Usage stays in the `pdf_export.sh` header. The README does not document exporter flags. This plan does not add a spec. |

Implemented. Keep as a historical record; do not treat the checklist as unfinished work. Do not commit unless the human asks.

---

# A3 landscape PDF export — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `asc/doc/pdf_export.sh --a3-l docs/foobar.md` writes an A3 landscape PDF (420 mm × 297 mm) beside that markdown file, while the default export stays A4 portrait (210 mm × 297 mm).

**Architecture:** One `PageGeometry` value is chosen before the existing pipeline runs. Playwright `format` / `landscape`, the CSS `@page` size token baked into that export’s HTML, the viewport, Mermaid `pageW` / `pageH`, diagram fitting, and pagination all read that value. The stage order does not change. HTML preview never selects a page, so it keeps today’s A4 stylesheet and A4 Mermaid box.

**Tech stack:** Existing Playwright/Chromium path through `md2pdf_asc.py`, `pdf_styles.css`, poppler `pdfinfo` and `pdftotext`. No new package.

## Global constraints

- Default page is A4 portrait, 210 mm × 297 mm. `--a3-l` is A3 landscape, 420 mm × 297 mm. Those are the only two sizes.
- Output path stays `${markdown%.md}.pdf` from `doc_md_to_pdf` ([`pdf_export.sh`](../../../../asc/doc/pdf_export.sh) lines 136–139). No `-a3` suffix and no second PDF.
- `--force` still means “rebuild even when the PDF is newer than the markdown” and still means A4 portrait unless `--a3-l` is also present.
- `--a3-l` rebuilds even when the PDF timestamp is current. It does not set the `--force` variable.
- Pipeline order stays the header in [`pdf_export.sh`](../../../../asc/doc/pdf_export.sh) lines 20–23 and the module docstring in [`md2pdf_asc.py`](../../../../asc/doc/md2pdf_asc.py) lines 4–8: protect math → Graphviz → markdown → restore math → explode code → inject CSS/boot → fonts → Mermaid → KaTeX → emulate print → mark long paragraphs → paginate → `page.pdf`. Preview stops before paginate.
- Margins stay as they are. CSS `@page` margin is `.75cm .75cm` ([`pdf_styles.css`](../../../../asc/doc/pdf_styles.css) lines 16–19). Playwright margins stay top `0.6cm`, right `0.7cm`, bottom `1.0cm`, left `0.7cm` ([`md2pdf_asc.py`](../../../../asc/doc/md2pdf_asc.py) lines 454–459). Content width keeps using the CSS side margin. Content height keeps using the CSS top margin and the Playwright bottom margin.
- Body type stays 9pt. The 2026-09-04 plan text still mentions 8pt; the shipped pipeline is 9pt (`--asc-font-size: 9pt`). Leave that alone.
- The 108 mm image cap in `pdf_styles.css` stays.
- `html_preview.sh` gains no flag and no pagination. Its path allow-list stays `data/ideas/`, `docs/`, and `asc/doc/fixtures/`.
- No new shell function in `pdf_export.sh`. No new Python dependency. No README edit.
- These Python modules already use 4-space indents. New Python in them stays at 4 spaces so the blocks stay valid. Shell stays at 2 spaces.
- Run PDF tests from the repository root with `bash asc/doc/asc/pdf.test.sh` (full suite) or `PDF_TEST_FILTER='test_name …' bash asc/doc/asc/pdf.test.sh` (selected cases). This suite is not wired into `make test-core`. Passing a test name as a script argument fails: vendored shUnit2 treats `$1` as a standalone script path (`shunit2:FATAL unable to read from …`). Selection uses a `suite()` in `pdf.test.sh` that validates each whitespace-separated name in `PDF_TEST_FILTER` with `declare -F` before `suite_addTest`; an unknown name prints `PDF_TEST_FILTER: unknown test function: …` and exits non-zero. When the variable is unset or empty, discovery runs every `test_*` as today. Verified on this checkout: a valid filter runs one case and exits 0; a misspelled filter exits non-zero. shUnit2 counts assertion failures (`assert*`, `fail`), not the test function’s return status: a body that only `return 1` still reports `OK` and exits 0.
- Do not run `asc/doc/pdf_export.sh --a3-l` with no target against the real `data/ideas` and `docs` trees. That invocation rewrites every PDF there.
- Directory and no-target exports must not report success when any `doc_pdf_export_one` failed. See § Directory and no-target.
- Do not commit unless the human asks.

---

## Current behavior

`asc/doc/pdf_export.sh` accepts `--force` and one optional file or directory. Anything else that starts with `-` is `Unknown option` and exit 1 (lines 68–86). There is no page-size flag.

Freshness is filename-only. `doc_pdf_needs_export` (lines 141–146) rebuilds when the PDF is missing or when the markdown is strictly newer (`-nt`). `doc_pdf_export_one` (lines 148–159) skips with `skip (up to date):` when `--force` is absent and the PDF is current. The script never reads the PDF page size. A current file is skipped whatever paper it contains.

Every export calls the same function:

| Invocation | What runs |
|---|---|
| `pdf_export.sh file.md` | `doc_pdf_export_one` |
| `pdf_export.sh directory` | `doc_pdf_export_tree` → `doc_pdf_export_one` for each `*.md` (lines 161–174, 179–180) |
| `pdf_export.sh` | the `data/ideas` loop and the `docs` loop, each calling `doc_pdf_export_one` (lines 191–211) |

The Python wrapper then hardcodes the paper:

```606:612:asc/doc/md2pdf_asc.py
        result = convert_markdown_to_pdf_html(
            markdown_content,
            str(output_path),
            title=title,
            page_size="A4",
            orientation="portrait",
            enable_mermaid=not args.no_mermaid,
        )
```

`html_to_pdf_playwright` (lines 423–504) passes that `page_size` and `orientation` through to Playwright (`format`, `landscape`). The viewport does not use those arguments. It uses `content_width_px()` and `content_height_px()`, which are fixed to A4 in [`print_paginate.py`](../../../../asc/doc/print_paginate.py) lines 21–23 and 65–74:

- width 210 mm and height 297 mm, at 96 CSS px per inch
- content width subtracts `0.75cm` on both sides
- content height subtracts `0.75cm` on top and `1.0cm` on the bottom

The same two functions are baked into the Mermaid boot from `layout_boot_script` (lines 259–260) via `mermaid_run_js(page_w, page_h)` ([`print_mermaid.py`](../../../../asc/doc/print_mermaid.py) lines 228–236). `scaleToPage` (lines 323–325) uses that box. After print emulation, `FIT_DIAGRAMS_JS` (lines 48–67, called at line 491) shrinks a diagram that is taller than `content_height_px()`. Width follows the viewport because the stylesheet uses `max-width: 100%`.

`build_style_block` (lines 216–218) embeds [`pdf_styles.css`](../../../../asc/doc/pdf_styles.css) unchanged, including:

```16:19:asc/doc/pdf_styles.css
@page {
  size: A4;
  margin: .75cm .75cm;
}
```

Pagination’s probe PDF is the Playwright `pdf_options` of that run (`apply_print_pushes`, lines 756–764; `_measure_content_height`, lines 693–709). The guess height is `content_height_px()`. `parse_pdf_lines` (lines 110–120) drops words below `A4_HEIGHT_PT - 25`, which is the 297 mm page height in points. That cutoff matches A4 portrait. It also matches A3 landscape, because A3 landscape is 420 mm wide and 297 mm tall, so the short side is the same 297 mm. The width is the part that changes.

`html_preview.sh` calls `render_html` and writes `data/tmp/doc-print/*.html` (lines 84–107). It does not call `select_page`, Playwright, or `apply_print_pushes`. `test_pipeline_order_in_driver` already asserts that preview source does not contain `apply_print_pushes`.

`test_page_css_margins_match_pre_plan` asserts the CSS file contains `size: A4` and `margin: .75cm .75cm`. `test_constants_and_content_box` asserts the A4 px constants and the zero-argument content height.

## Proposed behavior

`--a3-l` is a Boolean flag, in any order relative to `--force` and the optional path, same as `--force` today.

| Invocation | Paper | When the PDF is already newer than the markdown |
|---|---|---|
| `pdf_export.sh file.md` | A4 portrait | skip |
| `pdf_export.sh --force file.md` | A4 portrait | rebuild |
| `pdf_export.sh --a3-l file.md` | A3 landscape | rebuild |
| `pdf_export.sh --a3-l --force file.md` | A3 landscape | rebuild |
| markdown newer than the PDF, no flag | A4 portrait | rebuild (already true) |
| markdown newer than the PDF, with `--a3-l` | A3 landscape | rebuild |

`--a3` and `-a3-l` stay unknown and exit 1. The output name does not change.

The flag is process-wide for that invocation. A directory export and a no-target export both call `doc_pdf_export_one`, so every file in that run uses the same paper and the same rebuild rule. There is no per-file size and no size remembered on disk.

### Switching back to A4

The sibling PDF does not record which flag produced it. After `--a3-l`, the PDF is newer than the markdown, so a later default export prints `skip (up to date):` and leaves the A3 file in place.

Return that file to A4 portrait with `--force` and without `--a3-l`:

```bash
asc/doc/pdf_export.sh --force 'docs/foobar.md'
```

A default export also rewrites A4 when the markdown is strictly newer than the PDF, because the existing freshness rule already rebuilds and the default paper is A4.

`--force` on a directory rewrites every markdown file under it to A4. A default directory export skips the files whose PDFs are still newer, so those stay A3. The same split holds for a no-target run: `pdf_export.sh --force` rewrites `data/ideas` and `docs` to A4; `pdf_export.sh` with no flag skips current PDFs and leaves them on whatever paper they already have.

### Directory and no-target

`pdf_export.sh --a3-l some/dir` parses the flag once, then `doc_pdf_export_tree` exports every `*.md` under that directory as A3 landscape, including PDFs whose timestamps are current.

`pdf_export.sh --a3-l` with no path does that for every `*.md` under `data/ideas` and every `*.md` under `docs`. That is a bulk rewrite. The acceptance test does not do it. It checks that both loops call `doc_pdf_export_one` and that the flag is parsed before either branch.

**Failure status (decision):** Today `doc_pdf_export_tree` ignores each `doc_pdf_export_one` status and returns 0 whenever it found at least one Markdown file; the no-target `data/ideas` and `docs` loops do the same. A single-file target already ends on `doc_pdf_export_one`, so that path already surfaces the converter’s exit code. With `--a3-l` able to rewrite a whole tree, a failed conversion that still exits 0 leaves a mix of old and new PDFs while reporting success. This plan changes that: each of those three loops records failures, continues the remaining files, then exits non-zero if any conversion failed. A skip stays success. Finding no Markdown still exits 1 as today. No new shell function; the loops keep a local status variable.

### One geometry for the existing stages

A3 landscape is 420 mm × 297 mm. At 96 px per inch and 72 pt per inch:

| Quantity | A4 portrait | A3 landscape |
|---|---|---|
| Paper | 210 mm × 297 mm | 420 mm × 297 mm |
| CSS `@page size` | `A4` | `A3 landscape` |
| Playwright | `format=A4`, `landscape=False` | `format=A3`, `landscape=True` |
| Content width | `210*96/25.4 - 2*0.75*96/2.54` px | `420*96/25.4 - 2*0.75*96/2.54` px |
| Content height | `297*96/25.4 - 0.75*96/2.54 - 1.0*96/2.54` px | the same height |
| `pdfinfo` (rounded mm) | `210 x 297` | `420 x 297` |

Content height matches because both papers are 297 mm tall and the vertical margins are unchanged. Content width grows by 210 mm. Pagination’s probe still measures the PDF that Playwright just wrote, and the guess height stays in the same 0.75–1.25 band as today.

`select_page(a3_landscape)` stores that geometry on the process. Zero-argument `content_width_px()` and `content_height_px()` read it. Their default, before any call, is A4, so current unit tests keep passing. `build_style_block`, the Playwright options, and `parse_pdf_lines` read the same object. `layout_boot_script`, the viewport, and `FIT_DIAGRAMS_JS` keep their current call shape; the numbers change because the zero-argument helpers follow the selection.

`html_preview.sh` starts a new process and does not call `select_page`. Preview HTML keeps `size: A4` and the A4 Mermaid box. That separate process does not show what a second call does in an interpreter that just ran `main()`. `main()` resets the selection with `select_page(False)` in a `finally` that covers both a finished conversion and a conversion that raises. `test_render_html_same_process_resets_to_a4` calls `main()` with `convert_markdown_to_pdf_html` mocked, including a raised exception and a `success: False` result, then checks `selected_page()` and a following `render_html` in that same process.

The CSS file on disk stays `size: A4`. The export substitutes `A3 landscape` only inside the HTML it writes for that run. The pocket-image comment that mentions A4 stays. If the `@page` rule no longer contains `size: A4`, the A3 export raises `pdf_styles.css is missing @page size: A4` instead of writing an A3 PDF laid out as A4.

## Approaches considered

| | Approach | Why it loses |
|---|---|---|
| A | A second stylesheet and a second driver | The two paths drift. |
| B | Change only Playwright `format` and `landscape` | `@page`, the viewport, Mermaid `pageW`, and the pagination guess stay on the A4 width. |
| C (chosen) | One `PageGeometry` selected before HTML is built; existing call sites read it | Smallest edit that keeps one paper through the stages that already consume a size. |
| D | Store the paper in the PDF and rebuild whenever the flag and the file disagree | Extra format parsing on every skip. The request is that `--a3-l` rebuilds a current file, and that a later default export leaves that current file alone. |

## Files

| File | Change |
|---|---|
| `asc/doc/print_paginate.py` | Add `PageGeometry`, `select_page`, `selected_page`, `css_with_page_size`. Zero-argument content box and the PDF footer cutoff follow the selection. Keep `A4_WIDTH_PX`, `A4_HEIGHT_PX`, `A4_HEIGHT_PT`. |
| `asc/doc/md2pdf_asc.py` | `--a3-l` on the wrapper. Select the page before conversion. Substitute `@page` size. Playwright format and landscape come from the same object. |
| `asc/doc/pdf_export.sh` | Document and parse `--a3-l`. Pass it through. Rebuild a current PDF when the flag is set. Aggregate failure status in `doc_pdf_export_tree` and both no-target loops. |
| `asc/doc/asc/pdf.test.sh` | Validating `PDF_TEST_FILTER` via `suite()`. Geometry unit tests, flag tests, directory failure-propagation test, aggregation source test, real no-target branch under an isolated temp project with a stub converter, isolate `test_graphviz_er_fixture_pdf` onto a temp copy with `print_html_path_for` and shUnit2 assertions, and one live `pdfinfo` acceptance test under `data/tmp/` (Mermaid, tables, and Graphviz). |
| `asc/doc/pdf_styles.css` | Unchanged `size: A4`. |
| `asc/doc/html_preview.sh` | Unchanged. |
| `asc/doc/print_mermaid.py` | Unchanged. It already takes `page_w` and `page_h`. |

Committed fixture PDFs under `asc/doc/fixtures/` stay on their current bytes for the whole suite. Live A3 exports copy `mermaid-dense.md`, `widow-table.md`, and `graphviz-er.md` into a directory created with `tempfile.mkdtemp(prefix="a3-page-size-", dir="data/tmp")`. The existing `test_graphviz_er_fixture_pdf` must stop force-exporting onto the tracked `asc/doc/fixtures/graphviz-er.pdf`; it copies that markdown into `data/tmp/`, exports the copy, and asserts on that PDF and its print HTML. `.gitignore` already ignores `/data/tmp/*` and keeps `data/tmp/README.md`. The A3 live test deletes only that unique directory, the print-HTML files whose paths it computed, and one temporary markdown file it created under `asc/doc/fixtures/` for the preview check. It does not read or write tracked fixture PDFs.

## Implementation checklist

### Task 1: Page geometry

**Files:**

- Modify: `asc/doc/print_paginate.py` (constants around lines 21–74, `parse_pdf_lines` around lines 110–120)
- Modify: `asc/doc/asc/pdf.test.sh` (add `suite()` before the final `. asc/vendor/shunit2/shunit2`; extend `test_constants_and_content_box`; add `test_page_geometry`)

**Interfaces:**

- Produces: `PageGeometry`, `PAGE_A4`, `PAGE_A3_LANDSCAPE`, `select_page(a3_landscape: bool) -> PageGeometry`, `selected_page() -> PageGeometry`, `css_with_page_size(css: str, page: PageGeometry) -> str`
- `content_width_px(page: PageGeometry | None = None) -> float` and `content_height_px(...)` — no argument means `selected_page()`
- `parse_pdf_lines(path, page_height_pt: float | None = None)` — no height means `selected_page().height_pt`

- [x] **Step 0: Add selectable cases via `suite()`.**

Place this immediately above `. asc/vendor/shunit2/shunit2` in `pdf.test.sh`. Do not pass test names as script arguments. Reject unknown names before registering them; a misspelled filter must not report `OK`.

```bash
suite() {
  if [ -n "${PDF_TEST_FILTER:-}" ]; then
    for _pdf_test in $PDF_TEST_FILTER; do
      if ! declare -F "$_pdf_test" >/dev/null 2>&1; then
        echo "PDF_TEST_FILTER: unknown test function: $_pdf_test" >&2
        exit 1
      fi
      suite_addTest "$_pdf_test"
    done
  fi
}
```

When `PDF_TEST_FILTER` is unset or empty, `__shunit_suite` stays empty and shUnit2 discovers every `test_*` as today. Verify both paths from the repository root (capture the script exit code directly; do not pipe into `tail` before reading `$?`):

```bash
PDF_TEST_FILTER=test_constants_and_content_box bash asc/doc/asc/pdf.test.sh
echo $?
# Expected: Ran 1 test. / OK / exit 0

PDF_TEST_FILTER=test_does_not_exist bash asc/doc/asc/pdf.test.sh
echo $?
# Expected: PDF_TEST_FILTER: unknown test function: test_does_not_exist / non-zero exit
```

A bare `bash asc/doc/asc/pdf.test.sh test_constants_and_content_box` must still be treated as unsupported (fatal unable to read). Without `declare -F`, a nonexistent selected name prints `command not found` and still exits 0 with `Ran 1 test. OK`.

- [x] **Step 1: Extend the constants test and add `test_page_geometry`.**

In `test_constants_and_content_box`, add `A4_HEIGHT_PT`, `PAGE_A3_LANDSCAPE`, `PAGE_A4`, `content_width_px`, and `select_page` to the existing `from print_paginate import` block. That block already imports `A4_HEIGHT_PX` and `A4_WIDTH_PX`. The new assertions use `A4_HEIGHT_PT`, and a second import that omits it raises `NameError` before any geometry check runs. Then add:

```python
assert PAGE_A4.format == "A4" and PAGE_A4.orientation == "portrait"
assert PAGE_A4.width_mm == 210.0 and PAGE_A4.height_mm == 297.0
assert PAGE_A4.css_size == "A4"
assert PAGE_A3_LANDSCAPE.format == "A3"
assert PAGE_A3_LANDSCAPE.orientation == "landscape"
assert PAGE_A3_LANDSCAPE.width_mm == 420.0
assert PAGE_A3_LANDSCAPE.height_mm == 297.0
assert PAGE_A3_LANDSCAPE.css_size == "A3 landscape"
assert PAGE_A4.width_px == A4_WIDTH_PX
assert PAGE_A4.height_px == A4_HEIGHT_PX
assert PAGE_A4.height_pt == A4_HEIGHT_PT
assert PAGE_A3_LANDSCAPE.height_pt == A4_HEIGHT_PT
assert abs(
    content_width_px(PAGE_A4)
    - (210.0 * 96.0 / 25.4 - 2 * 0.75 * 96.0 / 2.54)
) < 1e-6
assert abs(
    content_width_px(PAGE_A3_LANDSCAPE)
    - (420.0 * 96.0 / 25.4 - 2 * 0.75 * 96.0 / 2.54)
) < 1e-6
assert abs(content_height_px(PAGE_A3_LANDSCAPE) - content_height_px(PAGE_A4)) < 1e-6
assert content_width_px() == content_width_px(PAGE_A4)
select_page(True)
assert content_width_px() == content_width_px(PAGE_A3_LANDSCAPE)
assert abs(content_height_px() - content_height_px(PAGE_A4)) < 1e-6
select_page(False)
assert content_width_px() == content_width_px(PAGE_A4)
```

Keep every assertion that function already has, including `content_height_px()` against `A4_HEIGHT_PX`.

Add `test_page_geometry` after it:

```bash
test_page_geometry() {
  "$PDF_PY" - <<'PY'
from pathlib import Path
from print_paginate import (
    PAGE_A3_LANDSCAPE,
    PAGE_A4,
    css_with_page_size,
    select_page,
)

css = Path("asc/doc/pdf_styles.css").read_text(encoding="utf-8")
a4 = css_with_page_size(css, PAGE_A4)
a3 = css_with_page_size(css, PAGE_A3_LANDSCAPE)

def at_page(text: str) -> str:
    return text.split("@page", 1)[1].split("}", 1)[0]

assert "size: A4" in at_page(a4)
assert "A3" not in at_page(a4)
assert "size: A3 landscape" in at_page(a3)
assert "size: A4" not in at_page(a3)
assert "margin: .75cm .75cm" in at_page(a3)
assert "A4 (~196mm content)" in a3
select_page(True)
try:
    raised = False
    try:
        css_with_page_size("@page { margin: 1cm; }", PAGE_A3_LANDSCAPE)
    except RuntimeError as exc:
        raised = True
        assert "size: A4" in str(exc)
    assert raised
finally:
    select_page(False)
print("ok")
PY
  assertEquals 'page geometry CSS assertions failed' 0 $?
}
```

Leave `test_page_css_margins_match_pre_plan` asserting `size: A4` in the file on disk.

- [x] **Step 2: Run the new tests and confirm they fail.**

Run from the repository root:

```bash
PDF_TEST_FILTER=test_page_geometry bash asc/doc/asc/pdf.test.sh
```

Expected: FAIL while importing `PAGE_A4` or `css_with_page_size`.

- [x] **Step 3: Add the geometry to `print_paginate.py`.**

Replace the A4 px block (lines 21–23) with:

```python
@dataclass(frozen=True)
class PageGeometry:
    format: str
    orientation: str
    width_mm: float
    height_mm: float

    @property
    def width_px(self) -> float:
        return self.width_mm * 96.0 / 25.4

    @property
    def height_px(self) -> float:
        return self.height_mm * 96.0 / 25.4

    @property
    def height_pt(self) -> float:
        return self.height_mm * 72.0 / 25.4

    @property
    def css_size(self) -> str:
        if self.orientation == "landscape":
            return f"{self.format} landscape"
        return self.format


PAGE_A4 = PageGeometry("A4", "portrait", 210.0, 297.0)
PAGE_A3_LANDSCAPE = PageGeometry("A3", "landscape", 420.0, 297.0)

_SELECTED: PageGeometry = PAGE_A4


def selected_page() -> PageGeometry:
    return _SELECTED


def select_page(a3_landscape: bool) -> PageGeometry:
    global _SELECTED
    _SELECTED = PAGE_A3_LANDSCAPE if a3_landscape else PAGE_A4
    return _SELECTED


A4_WIDTH_PX = PAGE_A4.width_px
A4_HEIGHT_PX = PAGE_A4.height_px
A4_HEIGHT_PT = PAGE_A4.height_pt

_PAGE_SIZE_RE = re.compile(
    r"(@page\s*\{[^}]*?\bsize:\s*)A4\b",
)


def css_with_page_size(css: str, page: PageGeometry) -> str:
    if page.css_size == "A4":
        return css
    updated, n = _PAGE_SIZE_RE.subn(rf"\g<1>{page.css_size}", css, count=1)
    if n != 1:
        raise RuntimeError("pdf_styles.css is missing @page size: A4")
    return updated
```

`dataclass` is already imported. Keep `MARGIN_*` and `CSS_PAGE_MARGIN_CM` as they are.

Change the content box to:

```python
def content_height_px(page: PageGeometry | None = None) -> float:
    """One layout-page height in CSS px. No argument uses the selected page."""
    page = selected_page() if page is None else page
    top = CSS_PAGE_MARGIN_CM * 96.0 / 2.54
    bottom = MARGIN_BOTTOM_CM * 96.0 / 2.54
    return page.height_px - top - bottom


def content_width_px(page: PageGeometry | None = None) -> float:
    """One layout-page width in CSS px. No argument uses the selected page."""
    page = selected_page() if page is None else page
    side = CSS_PAGE_MARGIN_CM * 96.0 / 2.54
    return page.width_px - 2 * side
```

Change `parse_pdf_lines` so the footer cutoff is the selected page height. The rest of the function stays.

```python
def parse_pdf_lines(
    path: str | Path,
    page_height_pt: float | None = None,
) -> list[PdfLine]:
    if page_height_pt is None:
        page_height_pt = selected_page().height_pt
    xml = subprocess.check_output(
        ["pdftotext", "-bbox-layout", str(path), "-"],
        text=True,
    )
    # existing loop, with this comparison:
    #     if y > page_height_pt - 25:
```

`_measure_content_height` can keep calling `parse_pdf_lines(tmp)` and `content_height_px()`. Both follow the selection.

- [x] **Step 4: Re-run the geometry tests.**

```bash
PDF_TEST_FILTER='test_constants_and_content_box test_page_geometry' bash asc/doc/asc/pdf.test.sh
```

Expected: both print `ok` and shunit2 reports success (`Ran 2 tests`).

### Task 2: Feed the selection through the PDF driver

**Files:**

- Modify: `asc/doc/md2pdf_asc.py` (`build_style_block` lines 216–218, `html_to_pdf_playwright` lines 423–460, `main` lines 544–617)
- Test: existing `test_pipeline_order_in_driver`

**Interfaces:**

- Consumes: `select_page`, `selected_page`, `css_with_page_size`, zero-argument `content_width_px` / `content_height_px`
- Produces: `md2pdf_asc.py --a3-l` selects A3 landscape before `convert_markdown_to_pdf_html`. The wrapper’s `page_size` and `orientation` must equal that selection or the driver raises.

Do not insert a stage. Do not mention the literal `page.pdf` in a new comment inside `html_to_pdf_playwright` ahead of the real `page.pdf` call; `test_pipeline_order_in_driver` compares source indexes.

- [x] **Step 1: Import the new helpers** next to the existing `print_paginate` import:

```python
from print_paginate import (
    ASC_MARK_LONG_PARAS_FN,
    MARK_LONG_PARAS_JS,
    apply_print_pushes,
    content_height_px,
    content_width_px,
    css_with_page_size,
    select_page,
    selected_page,
)
```

- [x] **Step 2: Substitute the page size when the style block is built.**

```python
def build_style_block(html_path: Path) -> str:
    css = css_with_page_size(
        STYLE_CSS.read_text(encoding="utf-8"),
        selected_page(),
    )
    return f"<style>\n{font_face_css(html_path)}\n\n{css}\n</style>"
```

Leave the viewport, `FIT_DIAGRAMS_JS`, and `mermaid_run_js(content_width_px(), content_height_px())` calls as they are. They pick up the selection through the zero-argument helpers. `layout_boot_script` runs while the HTML is built, which is after `select_page` and before `main` resets it.

- [x] **Step 3: Make Playwright use the selected paper.** At the start of the `try` inside `html_to_pdf_playwright`, before `pdf_options`:

```python
        geom = selected_page()
        wants_landscape = orientation.lower() == "landscape"
        if page_size != geom.format or wants_landscape != (
            geom.orientation == "landscape"
        ):
            raise RuntimeError(
                f"PDF page {page_size} {orientation} != selected "
                f"{geom.format} {geom.orientation}"
            )
```

Set `"format": geom.format` and `"landscape": geom.orientation == "landscape"` in `pdf_options`. Leave the margin dict, header, footer, viewport call, `emulate_media`, `FIT_DIAGRAMS_JS`, `MARK_LONG_PARAS_JS`, `apply_print_pushes`, and `page.pdf` in that order.

- [x] **Step 4: Select the page in `main` and pass the same value through.**

Add the argument beside `--no-paginate`:

```python
    parser.add_argument(
        "--a3-l",
        action="store_true",
        help="A3 landscape (420 mm × 297 mm). Default is A4 portrait.",
    )
```

After the vendor checks and before the conversion print, and reset in the existing `finally`:

```python
    geom = select_page(bool(args.a3_l))
    try:
        print(
            f"  (ASC style: {FONT_FAMILY} + {MONO_FONT_FAMILY} + 9pt body; "
            f"Mermaid local {display_path(MERMAID_VENDOR, _PROJECT_ROOT, PROJECT_ROOT_DEFAULT)}; "
            f"KaTeX local {display_path(KATEX_VENDOR, _PROJECT_ROOT, PROJECT_ROOT_DEFAULT)}"
            f"{gv_note}; "
            f"page {geom.css_size}; "
            "local images rewritten for print HTML)"
        )
        result = convert_markdown_to_pdf_html(
            markdown_content,
            str(output_path),
            title=title,
            page_size=geom.format,
            orientation=geom.orientation,
            enable_mermaid=not args.no_mermaid,
        )
    finally:
        select_page(False)
        _CURRENT_SOURCE_MD = None
        _PROJECT_ROOT = None
        _PRINT_HTML_PATH = None
```

Keep `from md2pdf.html_renderer import convert_markdown_to_pdf_html` inside `main`, immediately before the conversion. The reset test patches that module attribute, and `main` must bind the patched function when it runs.

Add one usage line to the module docstring:

```text
  asc/doc/md2pdf_asc.py input.md -o output.pdf --a3-l
```

Add one sentence under the pipeline list: page size is chosen before these stages and is not itself a stage. Preview does not select a page.

- [x] **Step 5: Add `test_render_html_same_process_resets_to_a4`.**

`html_preview.sh` is a new process, so it cannot see a selection left behind by `main()`. This test stays in one `PDF_PY` process and calls `main()`. It does not launch Chromium: `main` imports `convert_markdown_to_pdf_html` inside the function, so the test patches `md2pdf.html_renderer.convert_markdown_to_pdf_html` before the call. The mock records `selected_page()` and the `page_size` / `orientation` arguments while the conversion is entered.

`main`'s `finally` must reset to A4 after three `--a3-l` calls on [`asc/doc/fixtures/para-gap.md`](../../../../asc/doc/fixtures/para-gap.md): the mock returns `{"success": True}`, the mock raises `RuntimeError`, and the mock returns `{"success": False}`. The exception must propagate. After each call, `selected_page()` is `PAGE_A4` and a following `render_html` embeds `size: A4`. A reset that is only a string in some `finally`, or that does not run when conversion raises, fails this test.

```bash
test_render_html_same_process_resets_to_a4() {
  "$PDF_PY" - <<'PY'
import shutil
import sys
import tempfile
from pathlib import Path
from unittest.mock import patch

import md2pdf.html_renderer
from md2pdf_asc import main, render_html
from print_paginate import PAGE_A3_LANDSCAPE, PAGE_A4, selected_page

def at_page(html: str) -> str:
    return html.split("@page", 1)[1].split("}", 1)[0]

def assert_a4_after(src: Path) -> None:
    assert selected_page() == PAGE_A4, selected_page()
    page = at_page(render_html(src))
    assert "size: A4" in page, page
    assert "A3" not in page, page

src = Path("asc/doc/fixtures/para-gap.md")
work = Path(tempfile.mkdtemp(prefix="a3-main-reset-", dir=Path("data/tmp")))
out_pdf = work / "out.pdf"
argv = ["md2pdf_asc.py", "--a3-l", str(src), "-o", str(out_pdf)]
old_argv = sys.argv
try:
    def fake_ok(markdown, output, title, page_size, orientation, enable_mermaid):
        assert selected_page() == PAGE_A3_LANDSCAPE, selected_page()
        assert page_size == "A3" and orientation == "landscape", (page_size, orientation)
        Path(output).write_bytes(b"%PDF-1.4 mock\n")
        return {"success": True}

    def fake_boom(*_args, **_kwargs):
        assert selected_page() == PAGE_A3_LANDSCAPE, selected_page()
        raise RuntimeError("convert failed")

    def fake_fail(*_args, **_kwargs):
        assert selected_page() == PAGE_A3_LANDSCAPE, selected_page()
        return {"success": False, "error": "mocked"}

    sys.argv = argv
    with patch("md2pdf.html_renderer.convert_markdown_to_pdf_html", fake_ok):
        assert main() == 0
    assert_a4_after(src)

    sys.argv = argv
    raised = False
    try:
        with patch("md2pdf.html_renderer.convert_markdown_to_pdf_html", fake_boom):
            main()
    except RuntimeError as exc:
        raised = True
        assert str(exc) == "convert failed"
    assert raised
    assert_a4_after(src)

    sys.argv = argv
    with patch("md2pdf.html_renderer.convert_markdown_to_pdf_html", fake_fail):
        assert main() == 1
    assert_a4_after(src)
    print("ok")
finally:
    sys.argv = old_argv
    shutil.rmtree(work)
PY
  assertEquals 'same-process A4 reset assertions failed' 0 $?
}
```

Until `main` selects A3 for `--a3-l`, passes that geometry into `convert_markdown_to_pdf_html`, and resets with `select_page(False)` on both the success path and the exception path, this test fails. `build_style_block` must read `selected_page()` so the follow-up `render_html` sees the reset.

- [x] **Step 6: Run the driver tests.**

```bash
PDF_TEST_FILTER='test_pipeline_order_in_driver test_page_css_margins_match_pre_plan test_page_geometry test_render_html_same_process_resets_to_a4' bash asc/doc/asc/pdf.test.sh
```

Expected: PASS. `test_pipeline_order_in_driver` still requires `__ascLayoutReady` before `emulate_media`, then `MARK_LONG_PARAS_JS`, then `apply_print_pushes`, then `page.pdf`, and preview source still has no `apply_print_pushes`.

### Task 3: Shell flag

**Files:**

- Modify: `asc/doc/pdf_export.sh` (header examples, the option loop lines 65–87, `doc_pdf_export_one` lines 148–159)
- Test: `asc/doc/asc/pdf.test.sh` (`test_a3_l_option`)

The action already has its own header and `. asc/bootstrap.sh`. Keep that shape. Do not add a shell function. The new array is local to `doc_pdf_export_one`.

`pdf_playwright_prepare` calls `command -v md2pdf` before the option loop. The unknown-flag command exits from that loop, which is before the later `md2pdf` gate. A known `--a3-l` continues into that gate, the `asc/vendor/mermaid.esm.min.mjs` check, and the `asc/vendor/katex/katex.min.js` check, and only then reaches `Path not found`. The unknown-flag command is the parser test. The missing-path command is skipped unless those three prerequisites are present. The source test starts at `while [[ $# -gt 0 ]]; do`. It does not split on the first `command -v md2pdf`.

- [x] **Step 1: Add `test_a3_l_option`.**

```bash
test_a3_l_option() {
  local out status
  out="$(./asc/doc/pdf_export.sh --a3 'docs/foobar.md' 2>&1)"
  status=$?
  assertEquals 'short flag stays unknown' 1 "$status"
  assertTrue 'unknown --a3' "echo \"$out\" | grep -q 'Unknown option: --a3'"

  if command -v md2pdf >/dev/null 2>&1 &&
    [[ -f asc/vendor/mermaid.esm.min.mjs && -f asc/vendor/katex/katex.min.js ]]; then
    out="$(./asc/doc/pdf_export.sh --a3-l 'docs/no-such-a3-flag.md' 2>&1)"
    status=$?
    assertEquals 'known flag reaches path check' 1 "$status"
    assertTrue 'missing path' "echo \"$out\" | grep -q 'Path not found: docs/no-such-a3-flag.md'"
  else
    echo "skip --a3-l path check (md2pdf or asc/vendor mermaid/katex missing)"
  fi

  "$PDF_PY" - <<'PY'
from pathlib import Path
sh = Path("asc/doc/pdf_export.sh").read_text(encoding="utf-8")
preview = Path("asc/doc/html_preview.sh").read_text(encoding="utf-8")
# pdf_playwright_prepare contains an earlier "command -v md2pdf".
after_loop_start = sh.split("while [[ $# -gt 0 ]]; do", 1)[1]
parser = after_loop_start.split("\ndone\n", 1)[0]
after_loop = after_loop_start.split("\ndone\n", 1)[1]
assert "--a3-l)" in parser
assert "-*)" in parser
assert after_loop.index("command -v md2pdf") < after_loop.index("Path not found:")
after_vendors = sh.split("asc/vendor/katex/katex.min.js", 1)[1]
assert "Path not found:" in after_vendors
force = sh.split("--force)", 1)[1].split(";;", 1)[0]
a3 = sh.split("--a3-l)", 1)[1].split(";;", 1)[0]
assert "p_all=1" in force
assert "p_a3_l" not in force
assert "p_a3_l=1" in a3
assert "p_all" not in a3
assert 'p_all" -eq 0 && "$p_a3_l" -eq 0' in sh
assert "${p_md%.md}.pdf" in sh
assert sh.count("doc_pdf_export_one ") >= 4
assert "--a3-l" in sh.split("doc_pdf_export_one()", 1)[1]
assert "--a3-l" not in preview
assert "select_page" not in preview
assert "render_html" in preview
print("ok")
PY
  assertEquals 'A3 flag wiring assertions failed' 0 $?
}
```

`doc_pdf_export_one ` with a trailing space counts the four call sites (tree, single file, `data/ideas`, `docs`) and not the definition. The definition line is `doc_pdf_export_one()`. Failure-aggregation source checks live in `test_export_failure_aggregation_source` (Step 6), not here, so this case can go green after the flag wiring in Step 3–4.

- [x] **Step 2: Run it and confirm failure.**

```bash
PDF_TEST_FILTER=test_a3_l_option bash asc/doc/asc/pdf.test.sh
```

Expected: the Python source assertions fail because `--a3-l)` is not in the parser yet. `--a3` already exits from the option loop. When `md2pdf` and both vendor files are present, `--a3-l` on the missing path still prints `Unknown option` rather than `Path not found`.

- [x] **Step 3: Update the header and the parser.**

Replace the `@param n` block with named options. Keep the pipeline comment. Add this sentence after it:

```text
# Page size is chosen before that pipeline. --a3-l selects A3 landscape.
# The default is A4 portrait. Page size is not a pipeline stage.
```

```text
# @param n [optional] String : markdown file or directory to export.
#   Defaults to every *.md under data/ideas and under docs.
#
# @param --force Boolean (flag) : rebuild each PDF even when it is newer than
#   its markdown source.
#   Defaults to compiling a missing PDF or a PDF older than the source.
#
# @param --a3-l Boolean (flag) : write A3 landscape (420 mm wide, 297 mm tall).
#   Defaults to A4 portrait (210 mm wide, 297 mm tall).
#   Also rebuilds when the PDF is already newer than the source.
```

Add examples next to the existing ones:

```text
#   # A3 landscape for one file (rebuilds a current PDF too) :
#   asc/doc/pdf_export.sh --a3-l 'docs/foobar.md'
#
#   # A3 landscape for every markdown file under a directory :
#   asc/doc/pdf_export.sh --a3-l docs/asc
#
#   # A3 landscape for data/ideas and docs :
#   asc/doc/pdf_export.sh --a3-l
#
#   # Write that one file back to A4 portrait :
#   asc/doc/pdf_export.sh --force 'docs/foobar.md'
```

Initialize `p_a3_l=0` beside `p_all=0`. Parse the flag in the existing loop. Leave the unknown-option text as the current `echo "Unknown option: $1"` and `exit 1`. Put a blank line between these multiline arms:

```bash
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      p_all=1
      shift
      ;;

    --a3-l)
      p_a3_l=1
      shift
      ;;

    -*)
      echo "Unknown option: $1"
      exit 1
      ;;

    *)
      if [[ -n "$p_target" ]]; then
        echo "Unexpected extra argument: $1"
        exit 1
      fi
      p_target="$1"
      shift
      ;;
  esac
done
```

Replace the body of `doc_pdf_export_one` with:

```bash
doc_pdf_export_one() {
  local p_md="$1"
  local pdf cmd
  pdf="$(doc_md_to_pdf "$p_md")"

  # The sibling PDF does not record its paper, so --a3-l rebuilds a current file.
  if [[ "$p_all" -eq 0 && "$p_a3_l" -eq 0 ]] && ! doc_pdf_needs_export "$p_md"; then
    echo "skip (up to date): $p_md"
    return 0
  fi

  mkdir -p "$(dirname "$pdf")"
  echo "$p_md -> $pdf"
  cmd=("$PDF_MD2PDF_PY" "$PDF_ASC_WRAPPER" "$p_md" -o "$pdf")

  if [[ "$p_a3_l" -eq 1 ]]; then
    cmd+=(--a3-l)
  fi

  "${cmd[@]}"
}
```

`doc_md_to_pdf` stays a caller of this function and does not grow a page-size argument. `doc_pdf_export_tree` and both no-target loops stay callers too, but they gain failure aggregation in the next steps.

- [x] **Step 4: Re-run the flag test.**

```bash
PDF_TEST_FILTER=test_a3_l_option bash asc/doc/asc/pdf.test.sh
```

Expected: PASS. The source assertions find `--a3-l)` inside the body that starts at `while [[ $# -gt 0 ]]; do` and ends at that loop's `done`. The `command -v md2pdf` after that `done` is before `Path not found:`. When `md2pdf`, `asc/vendor/mermaid.esm.min.mjs`, and `asc/vendor/katex/katex.min.js` are all present, `--a3-l` on the missing path prints `Path not found: docs/no-such-a3-flag.md` and does not print `Unknown option`. When any of those three is missing, that command is skipped and the source assertions still run. This checkpoint does not require failure aggregation yet.

- [x] **Step 5: Add `test_export_tree_propagates_failure`.**

Place it near `test_a3_l_option`. It must not depend on Chromium succeeding for every file. Under a unique `data/tmp` directory, write two exportable markdown files, make the sibling path of the lexicographically first one a directory so the converter cannot overwrite it, export that tree with `--force`, and assert a non-zero exit while the second file still produces a PDF. Use shUnit2 assertions only (not a bare `return 1`).

```bash
test_export_tree_propagates_failure() {
  if ! command -v md2pdf >/dev/null 2>&1; then
    echo "skip tree failure propagation (md2pdf not on PATH)"
    return 0
  fi
  if [[ ! -f asc/vendor/mermaid.esm.min.mjs || ! -f asc/vendor/katex/katex.min.js ]]; then
    echo "skip tree failure propagation (asc/vendor mermaid/katex missing)"
    return 0
  fi
  local tmp status
  tmp="$(mktemp -d --tmpdir="${PWD}/data/tmp" tree-fail-XXXXXX)"
  trap 'rm -rf "$tmp"' RETURN
  printf '# Bad\n\nHello.\n' >"$tmp/a-bad.md"
  printf '# Ok\n\nHello.\n' >"$tmp/b-ok.md"
  mkdir "$tmp/a-bad.pdf"
  ./asc/doc/pdf_export.sh --force "$tmp" >/dev/null 2>&1
  status=$?
  assertNotEquals 'tree export must fail when one conversion fails' 0 "$status"
  assertTrue 'successful sibling still exported' "[ -f \"$tmp/b-ok.pdf\" ]"
}
```

Until the tree helper aggregates status, this fails: the script exits 0 after writing `b-ok.pdf` even though `a-bad.pdf` could not be written.

- [x] **Step 6: Add aggregation source checks and a real no-target branch test.**

**6a. `test_export_failure_aggregation_source`** — source-only; can stay red until Step 7.

```bash
test_export_failure_aggregation_source() {
  "$PDF_PY" - <<'PY'
from pathlib import Path
sh = Path("asc/doc/pdf_export.sh").read_text(encoding="utf-8")
tree = sh.split("doc_pdf_export_tree()", 1)[1].split("\n}\n", 1)[0]
assert 'doc_pdf_export_one "$md" || rc=1' in tree
assert 'return "$rc"' in tree
# Keep the delimiter in the extracted text; splitting it away drops local_found=0.
marker = "else\n  local_found=0\n"
assert marker in sh
no_target = marker + sh.split(marker, 1)[1]
assert no_target.count('doc_pdf_export_one "$md" || rc=1') == 2
assert 'exit "$rc"' in no_target
# One rc for the whole no-target branch: must not reset between the two trees.
ideas, docs = no_target.split("if [[ -d docs ]];", 1)
assert "rc=0" in ideas
assert ideas.index("local_found=0") < ideas.index("rc=0")
assert "rc=0" not in docs.split("done", 1)[0]
print("ok")
PY
  assertEquals 'export failure aggregation source assertions failed' 0 $?
}
```

Re-attaching `marker` keeps `local_found=0` in `no_target` / `ideas`. Checking `rc=0` in that already-extracted `ideas` portion (and its order relative to `local_found=0`) avoids a second split that would raise `IndexError`. The docs-side check still rejects a script that clears status between the trees while still containing two `|| rc=1` strings and an `exit "$rc"`.

**6b. `test_no_target_loops_propagate_failure`** — runs the **real** no-target branch of a copied `pdf_export.sh` inside an isolated temporary project. Do not invoke no-target against this repository’s `data/ideas` or `docs`. Verified shape on this checkout: overlay `asc/` with symlinks, copy only `pdf_export.sh`, replace only `md2pdf_asc.py` with a controlled converter, put a fake `md2pdf` (and a `python` next to it) on `PATH`, `cd` into the temp project, and run `./asc/doc/pdf_export.sh --force` with no path argument.

The decisive fixture fails only under `data/ideas` and lets every `docs` conversion succeed. A bug that resets `rc=0` before the docs loop would then exit 0 while still continuing; a fail-in-each-tree fixture would hide that by setting `rc` again from docs.

```bash
test_no_target_loops_propagate_failure() {
  local root tmp item base status call_log
  root="$(pwd -P)"
  tmp="$(mktemp -d --tmpdir="${root}/data/tmp" no-target-fail-XXXXXX)"
  call_log="$tmp/calls"
  trap 'rm -rf "$tmp"' RETURN

  mkdir -p "$tmp/data/ideas" "$tmp/docs" "$tmp/bin" "$tmp/asc/doc"
  for item in "$root/asc"/*; do
    base="$(basename "$item")"
    [[ "$base" == doc ]] && continue
    ln -s "$item" "$tmp/asc/$base"
  done
  for item in "$root/asc/doc"/*; do
    base="$(basename "$item")"
    [[ "$base" == md2pdf_asc.py || "$base" == pdf_export.sh ]] && continue
    ln -s "$item" "$tmp/asc/doc/$base"
  done
  cp "$root/asc/doc/pdf_export.sh" "$tmp/asc/doc/pdf_export.sh"
  cat >"$tmp/asc/doc/md2pdf_asc.py" <<'PY'
import os
import sys
from pathlib import Path

md = Path(sys.argv[1])
out = Path(sys.argv[sys.argv.index("-o") + 1])
with Path(os.environ["EXPORT_CALL_LOG"]).open("a", encoding="utf-8") as fh:
    fh.write(f"{md.as_posix()}\n")
if "fail" in md.name:
    sys.exit(1)
out.write_text("%PDF-stub\n", encoding="utf-8")
PY
  printf '#!/bin/bash\nexit 0\n' >"$tmp/bin/md2pdf"
  chmod +x "$tmp/bin/md2pdf"
  ln -s "$(command -v python3)" "$tmp/bin/python"

  # ideas fails once then succeeds; every docs file succeeds.
  printf '# fail\n' >"$tmp/data/ideas/a-fail.md"
  printf '# ok\n' >"$tmp/data/ideas/b-ok.md"
  printf '# ok\n' >"$tmp/docs/a-ok.md"
  printf '# ok\n' >"$tmp/docs/b-ok.md"
  : >"$call_log"

  (
    cd "$tmp" || exit 1
    export EXPORT_CALL_LOG="$call_log"
    export PATH="$tmp/bin:$PATH"
    ./asc/doc/pdf_export.sh --force
  )
  status=$?

  assertNotEquals 'ideas failure must keep no-target exit non-zero' 0 "$status"
  assertTrue 'ideas failure attempted' "grep -qx 'data/ideas/a-fail.md' \"$call_log\""
  assertTrue 'ideas success after failure' "grep -qx 'data/ideas/b-ok.md' \"$call_log\""
  assertTrue 'docs first success ran' "grep -qx 'docs/a-ok.md' \"$call_log\""
  assertTrue 'docs second success ran' "grep -qx 'docs/b-ok.md' \"$call_log\""
  assertEquals 'four converter calls' 4 "$(wc -l <"$call_log")"
  assertTrue 'ideas success PDF written' "[ -f \"$tmp/data/ideas/b-ok.pdf\" ]"
  assertTrue 'docs a-ok PDF written' "[ -f \"$tmp/docs/a-ok.pdf\" ]"
  assertTrue 'docs b-ok PDF written' "[ -f \"$tmp/docs/b-ok.pdf\" ]"
  assertFalse 'ideas failure PDF must not appear' "[ -f \"$tmp/data/ideas/a-fail.pdf\" ]"
}
```

`pdf_export.sh` must be a real copy under the temp tree so `BASH_SOURCE` resolves the stub wrapper there; a symlink would keep the real `md2pdf_asc.py`. Until Step 7 aggregates status, this case fails with exit 0 after four converter calls (observed on this checkout before the change). Continuation inside one tree remains covered by `test_export_tree_propagates_failure`.

- [x] **Step 7: Aggregate failures in the three multi-file loops.**

In `doc_pdf_export_tree` and in each no-target loop, keep a local status (for example `rc=0`), run `doc_pdf_export_one "$md" || rc=1`, finish the find loop, then return or exit with that status after the existing “no markdown found” checks. Continue after a failure so later files still run. Do not wrap this in a new shell function. Spell the status return exactly as `return "$rc"` in the tree helper and `exit "$rc"` at the end of the no-target branch (the source test requires those quoted forms). Initialize `rc=0` once for the whole no-target branch before the `data/ideas` loop; do not set `rc=0` again before the `docs` loop.

Example for the tree helper:

```bash
doc_pdf_export_tree() {
  local root="$1"
  local found=0
  local rc=0
  while IFS= read -r -d '' md; do
    md="${md#./}"
    found=1
    doc_pdf_export_one "$md" || rc=1
  done < <(find "$root" -type f -name '*.md' -print0 | sort -z)
  if [[ "$found" -eq 0 ]]; then
    echo "No *.md files under: $root"
    return 1
  fi
  return "$rc"
}
```

Example for the no-target branch (replace the current `else` … `fi` that ends the script):

```bash
else
  local_found=0
  rc=0
  if [[ -d data/ideas ]]; then
    while IFS= read -r -d '' md; do
      md="${md#./}"
      local_found=1
      doc_pdf_export_one "$md" || rc=1
    done < <(find data/ideas -type f -name '*.md' -print0 | sort -z)
  fi
  if [[ -d docs ]]; then
    while IFS= read -r -d '' md; do
      md="${md#./}"
      local_found=1
      doc_pdf_export_one "$md" || rc=1
    done < <(find docs -type f -name '*.md' -print0 | sort -z)
  fi
  if [[ "$local_found" -eq 0 ]]; then
    echo "No *.md files found under data/ideas or docs"
    exit 1
  fi
  exit "$rc"
fi
```

The single-file branch stays a direct `doc_pdf_export_one` call.

- [x] **Step 8: Green checkpoint for aggregation.**

```bash
PDF_TEST_FILTER='test_a3_l_option test_export_failure_aggregation_source test_export_tree_propagates_failure test_no_target_loops_propagate_failure' bash asc/doc/asc/pdf.test.sh
```

Expected: PASS when prerequisites for the live tree case are present. A skip of `test_export_tree_propagates_failure` is not a pass of directory aggregation. `test_export_failure_aggregation_source` and `test_no_target_loops_propagate_failure` do not need Chromium; the no-target case needs only `python3` on `PATH` for the fake `md2pdf` neighbor.

### Task 4: Isolate the Graphviz fixture export

**Files:**

- Modify: `asc/doc/asc/pdf.test.sh` (`test_graphviz_er_fixture_pdf`)

The current case runs `./asc/doc/pdf_export.sh --force 'asc/doc/fixtures/graphviz-er.md'`, which overwrites the tracked `asc/doc/fixtures/graphviz-er.pdf` whenever `dot` is on `PATH`. That conflicts with the fixture-byte preservation rule above. Move the export onto an isolated copy.

- [x] **Step 1: Rewrite the fixture case to use `data/tmp`.**

Derive the print-HTML path with [`print_html_path_for`](../../../../asc/doc/md2pdf_asc.py) (lines 304–313) for the temp markdown and the project root. Do not `ls`/`head` a glob of `*graphviz-er.html`; that can match a stale file from another run. Clean up that exact HTML path in the same `trap` as the temp directory. Use shUnit2 `assertTrue` / `assertFalse` / `fail` on every error path: a lone `return 1` still reports `OK` and exits 0 under this runner.

```bash
test_graphviz_er_fixture_pdf() {
  if ! command -v dot >/dev/null 2>&1; then
    echo "skip graphviz fixture (dot not on PATH)"
    return 0
  fi
  local tmp html text status
  tmp="$(mktemp -d --tmpdir="${PWD}/data/tmp" graphviz-er-XXXXXX)"
  html="$("$PDF_PY" - <<PY
from pathlib import Path
from md2pdf_asc import find_project_root, print_html_path_for
md = Path("$tmp/graphviz-er.md")
root = find_project_root(md.resolve())
print(print_html_path_for(md, root))
PY
)"
  trap 'rm -rf "$tmp"; rm -f "$html"' RETURN
  cp asc/doc/fixtures/graphviz-er.md "$tmp/graphviz-er.md"
  ./asc/doc/pdf_export.sh --force "$tmp/graphviz-er.md"
  status=$?
  assertEquals 'graphviz temp export failed' 0 "$status"
  assertTrue "print HTML missing: $html" "[ -f \"$html\" ]"
  assertTrue 'graphviz-wrap missing' "grep -q 'class=\"graphviz-wrap\"' \"$html\""
  assertTrue 'svg missing' "grep -q '<svg' \"$html\""
  grep -q 'fill="#ffffcc"' "$html" || true
  assertFalse 'raw digraph in HTML' "grep -q 'digraph' \"$html\""
  assertFalse 'raw fillcolor in HTML' "grep -q 'fillcolor' \"$html\""
  assertFalse 'raw fence in HTML' "grep -q '\`\`\`dot' \"$html\""
  text="$(pdftotext -layout "$tmp/graphviz-er.pdf" -)"
  assertTrue 'Article label missing' "echo \"$text\" | grep -q 'Article'"
  assertTrue 'Article category missing' "echo \"$text\" | grep -q 'Article category'"
  assertTrue 'Author label missing' "echo \"$text\" | grep -q 'Author'"
  assertFalse 'raw digraph in PDF text' "echo \"$text\" | grep -q 'digraph'"
  assertFalse 'raw fillcolor in PDF text' "echo \"$text\" | grep -q 'fillcolor'"
  assertFalse 'raw fence in PDF text' "echo \"$text\" | grep -q '\`\`\`dot'"
}
```

Do not write under `asc/doc/fixtures/` in this case. After a green run, `git status --short asc/doc/fixtures/graphviz-er.pdf` must stay clean.

- [x] **Step 2: Prove a deliberate assertion failure exits non-zero, then run the isolated case.**

Temporarily change one assertion to a guaranteed failure (for example `assertTrue 'deliberate' "false"`), run:

```bash
PDF_TEST_FILTER=test_graphviz_er_fixture_pdf bash asc/doc/asc/pdf.test.sh
echo $?
```

Expected while the deliberate failure is present: `FAILED` and a non-zero exit. A body that only `return 1` is not enough. Restore the real assertion, then re-run the same filter command.

Expected after restore: PASS when `dot` is present, otherwise the existing skip message. Tracked fixture PDF bytes unchanged. The print HTML for that temp markdown is removed by the trap.

### Task 5: Live page size, switch-back, diagram, table, and Graphviz

**Files:**

- Test: `asc/doc/asc/pdf.test.sh` (new `test_a3_landscape_page_and_rebuild`, placed after `test_diagrams_fit_print_page`)

Copies go to a unique directory from `tempfile.mkdtemp(prefix="a3-page-size-", dir=data/tmp)`. Cleanup is `shutil.rmtree` on that directory only, inside `finally`, including when an assertion fails. Print HTML is written under `data/tmp/doc-print/`, outside that directory. The test unlinks only the HTML paths it computed for this run. It does not remove `data/tmp/doc-print/` or any other temporary directory. Preview cannot read `data/tmp/`, so the test writes one markdown file under `asc/doc/fixtures/` whose name includes the unique directory name, previews that file, and unlinks that markdown file and its print HTML in the same `finally`. It does not read or write tracked fixture markdown or PDF under `asc/doc/fixtures/` except that one temporary preview markdown it creates and deletes.

- [x] **Step 1: Add the live test.**

```bash
test_a3_landscape_page_and_rebuild() {
  if ! command -v pdfinfo >/dev/null 2>&1; then
    echo "skip A3 page size (pdfinfo not on PATH)"
    return 0
  fi
  if ! command -v pdftotext >/dev/null 2>&1; then
    echo "skip A3 page size (pdftotext not on PATH)"
    return 0
  fi
    if ! command -v md2pdf >/dev/null 2>&1; then
    echo "skip A3 page size (md2pdf not on PATH)"
    return 0
  fi
  "$PDF_PY" - <<'PY'
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

from print_paginate import (
    MIN_TABLE_ROWS,
    PAGE_A3_LANDSCAPE,
    content_height_px,
    content_width_px,
    parse_pdf_lines,
)

ROOT = Path(".").resolve()
A4_MEDIA_WIDTH_PT = 210.0 * 72.0 / 25.4
# Playwright's bottom margin is 1.0cm (about 28 pt). 36 pt clears the footer.
FOOTER_BAND_PT = 36.0
_WORD_RE = re.compile(
    r'<word xMin="([0-9.]+)" yMin="([0-9.]+)" xMax="([0-9.]+)" '
    r'yMax="([0-9.]+)">(.*?)</word>'
)

tmp = Path(tempfile.mkdtemp(prefix="a3-page-size-", dir=ROOT / "data" / "tmp"))
written_html: list[Path] = []
extra_paths: list[Path] = []
try:
    (tmp / "dir").mkdir()
    (tmp / "wide").mkdir()
    (tmp / "flow").mkdir()
    (tmp / "gv").mkdir()
    (tmp / "dir" / "one.md").write_text("# One\n\nHello one.\n", encoding="utf-8")
    (tmp / "dir" / "two.md").write_text("# Two\n\nHello two.\n", encoding="utf-8")
    shutil.copy("asc/doc/fixtures/mermaid-dense.md", tmp / "wide" / "diagram.md")
    shutil.copy("asc/doc/fixtures/widow-table.md", tmp / "flow" / "table.md")
    shutil.copy("asc/doc/fixtures/graphviz-er.md", tmp / "gv" / "graphviz-er.md")

    def export(*args: str) -> str:
        proc = subprocess.run(
            ["./asc/doc/pdf_export.sh", *args],
            check=True,
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        return proc.stdout

    def pdfinfo_text(pdf: Path) -> str:
        proc = subprocess.run(
            ["pdfinfo", str(pdf)],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
        )
        return proc.stdout

    def page_mm(pdf: Path) -> str:
        line = next(
            row for row in pdfinfo_text(pdf).splitlines() if row.startswith("Page size:")
        )
        parts = line.split()
        width = round(float(parts[2]) * 25.4 / 72)
        height = round(float(parts[4]) * 25.4 / 72)
        return f"{width} x {height}"

    def page_pts(pdf: Path) -> tuple[float, float]:
        line = next(
            row for row in pdfinfo_text(pdf).splitlines() if row.startswith("Page size:")
        )
        parts = line.split()
        return float(parts[2]), float(parts[4])

    def page_count(pdf: Path) -> int:
        line = next(
            row for row in pdfinfo_text(pdf).splitlines() if row.startswith("Pages:")
        )
        return int(line.split()[1])

    def print_html_for(md: Path) -> Path:
        rel = md.resolve().relative_to(ROOT).as_posix()
        safe = rel.replace("/", "__").replace(" ", "_")
        if safe.endswith(".md"):
            safe = safe[: -len(".md")]
        path = ROOT / "data" / "tmp" / "doc-print" / f"{safe}.html"
        written_html.append(path)
        return path

    def word_boxes(pdf: Path) -> list[tuple[float, float, float, float, str]]:
        xml = subprocess.check_output(
            ["pdftotext", "-bbox-layout", str(pdf), "-"],
            text=True,
        )
        boxes = [
            (float(xmin), float(ymin), float(xmax), float(ymax), raw)
            for xmin, ymin, xmax, ymax, raw in _WORD_RE.findall(xml)
        ]
        assert boxes, pdf
        return boxes

    def assert_inside_media_box(pdf: Path) -> None:
        # Words pdftotext omitted cannot fail this loop. Survival of a
        # clipped-away label is checked by requiring that label's text.
        width_pt, height_pt = page_pts(pdf)
        for xmin, ymin, xmax, ymax, _raw in word_boxes(pdf):
            assert -1.0 <= xmin <= xmax <= width_pt + 1.0, (pdf, xmin, xmax, width_pt)
            assert -1.0 <= ymin <= ymax <= height_pt + 1.0, (pdf, ymin, ymax, height_pt)

    def word_named(pdf: Path, label: str) -> tuple[float, float, float, float]:
        hits = [
            (xmin, ymin, xmax, ymax)
            for xmin, ymin, xmax, ymax, raw in word_boxes(pdf)
            if raw.strip() == label
        ]
        assert len(hits) == 1, (label, hits)
        return hits[0]

    def content_max_xmax(pdf: Path) -> float:
        _width_pt, height_pt = page_pts(pdf)
        xs = [
            xmax
            for _xmin, ymin, xmax, _ymax, _raw in word_boxes(pdf)
            if ymin <= height_pt - FOOTER_BAND_PT
        ]
        assert xs, pdf
        return max(xs)

    one = tmp / "dir" / "one.md"
    one_pdf = tmp / "dir" / "one.pdf"
    two = tmp / "dir" / "two.md"
    two_pdf = tmp / "dir" / "two.pdf"
    rel_one = str(one.relative_to(ROOT))
    rel_dir = str((tmp / "dir").relative_to(ROOT))
    print_html_for(one)
    print_html_for(two)

    out = export("--force", rel_one)
    assert "skip (up to date)" not in out, out
    assert page_mm(one_pdf) == "210 x 297"
    assert one_pdf.is_file()
    assert not (tmp / "dir" / "one-a3.pdf").exists()

    out = export(rel_one)
    assert f"skip (up to date): {rel_one}" in out, out
    assert page_mm(one_pdf) == "210 x 297"

    out = export("--a3-l", rel_one)
    assert "skip (up to date)" not in out, out
    assert page_mm(one_pdf) == "420 x 297"

    out = export(rel_one)
    assert f"skip (up to date): {rel_one}" in out, out
    assert page_mm(one_pdf) == "420 x 297"

    out = export("--force", rel_one)
    assert page_mm(one_pdf) == "210 x 297", out

    out = export("--a3-l", rel_dir)
    assert "skip (up to date)" not in out, out
    assert page_mm(one_pdf) == "420 x 297"
    assert page_mm(two_pdf) == "420 x 297"

    out = export("--force", rel_dir)
    assert page_mm(one_pdf) == "210 x 297"
    assert page_mm(two_pdf) == "210 x 297"

    diagram = tmp / "wide" / "diagram.md"
    diagram_pdf = tmp / "wide" / "diagram.pdf"
    rel_diagram = str(diagram.relative_to(ROOT))
    diagram_html = print_html_for(diagram)
    a4_diagram_out = export("--force", rel_diagram)
    assert "left as source" not in a4_diagram_out, a4_diagram_out
    assert page_mm(diagram_pdf) == "210 x 297"
    a4_content_xmax = content_max_xmax(diagram_pdf)
    diagram_out = export("--a3-l", rel_diagram)
    assert "left as source" not in diagram_out, diagram_out
    assert "Syntax error" not in diagram_out, diagram_out
    assert page_mm(diagram_pdf) == "420 x 297"
    diagram_text = subprocess.check_output(
        ["pdftotext", "-layout", str(diagram_pdf), "-"],
        text=True,
    )
    assert "The house" in diagram_text
    assert "extract-once" in diagram_text
    assert "the world" in diagram_text
    folded = diagram_text.casefold()
    assert "flowchart" not in folded, diagram_text
    assert "subgraph" not in folded, diagram_text
    assert_inside_media_box(diagram_pdf)
    a3_content_xmax = content_max_xmax(diagram_pdf)
    assert a3_content_xmax > a4_content_xmax, (a3_content_xmax, a4_content_xmax)
    assert a3_content_xmax > A4_MEDIA_WIDTH_PT, (a3_content_xmax, A4_MEDIA_WIDTH_PT)
    diagram_body = diagram_html.read_text(encoding="utf-8")
    assert "size: A3 landscape" in diagram_body.split("@page", 1)[1].split("}", 1)[0]
    assert f"const pageW = {content_width_px(PAGE_A3_LANDSCAPE)};" in diagram_body
    assert f"const pageH = {content_height_px(PAGE_A3_LANDSCAPE)};" in diagram_body

    clip = tmp / "wide" / "clip.md"
    clip_pdf = tmp / "wide" / "clip.pdf"
    clip.write_text(
        "# Clip probe\n\n```mermaid\nflowchart LR\n"
        '  L["CLIPLEFT"] --> R["CLIPRIGHT"]\n```\n',
        encoding="utf-8",
    )
    print_html_for(clip)
    clip_out = export("--a3-l", str(clip.relative_to(ROOT)))
    assert "left as source" not in clip_out, clip_out
    assert "Syntax error" not in clip_out, clip_out
    clip_text = subprocess.check_output(
        ["pdftotext", "-layout", str(clip_pdf), "-"],
        text=True,
    )
    assert "CLIPLEFT" in clip_text
    assert "CLIPRIGHT" in clip_text
    assert "flowchart" not in clip_text.casefold(), clip_text
    left = word_named(clip_pdf, "CLIPLEFT")
    right = word_named(clip_pdf, "CLIPRIGHT")
    clip_width, clip_height = page_pts(clip_pdf)
    for xmin, ymin, xmax, ymax in (left, right):
        assert -1.0 <= xmin <= xmax <= clip_width + 1.0, (xmin, xmax, clip_width)
        assert -1.0 <= ymin <= ymax <= clip_height + 1.0, (ymin, ymax, clip_height)
    assert right[0] > left[2], (left, right)

    table = tmp / "flow" / "table.md"
    table_pdf = tmp / "flow" / "table.pdf"
    rel_table = str(table.relative_to(ROOT))
    print_html_for(table)
    export("--force", rel_table)
    assert page_mm(table_pdf) == "210 x 297"
    assert page_count(table_pdf) >= 2
    export("--a3-l", rel_table)
    assert page_mm(table_pdf) == "420 x 297"
    assert page_count(table_pdf) >= 2
    assert_inside_media_box(table_pdf)
    table_lines = parse_pdf_lines(table_pdf)
    alpha_names = ("Alpha", "Bravo", "Charlie", "Delta", "Echo")
    expected_rows = [f"Observation for {name}" for name in alpha_names]
    expected_rows += [f"Observation for R{number:02d}" for number in range(1, 46)]
    joined = "\n".join(line.text for line in table_lines)
    missing = [label for label in expected_rows if label not in joined]
    assert not missing, missing
    alpha = [
        line for line in table_lines
        if any(f"Observation for {name}" in line.text for name in alpha_names)
    ]
    assert len(alpha) >= 5, [line.text for line in alpha]
    assert {line.page for line in alpha} == {alpha[0].page}, alpha
    r_lines = [line for line in table_lines if "Observation for R" in line.text]
    first_page = min(line.page for line in r_lines)
    on_first = [line for line in r_lines if line.page == first_page]
    later = [line for line in r_lines if line.page > first_page]
    assert later, "tall table should continue past its first page"
    assert len(on_first) >= MIN_TABLE_ROWS, [line.text for line in on_first]
    r01 = next(line for line in r_lines if "Observation for R01" in line.text)
    assert any(
        line.page == r01.page and line.y <= r01.y and "Source" in line.text
        for line in table_lines
    ), r01

    if shutil.which("dot") is None:
        print("skip A3 Graphviz (dot not on PATH)")
    else:
        gv = tmp / "gv" / "graphviz-er.md"
        gv_pdf = tmp / "gv" / "graphviz-er.pdf"
        rel_gv = str(gv.relative_to(ROOT))
        gv_html = print_html_for(gv)
        gv_out = export("--a3-l", rel_gv)
        assert page_mm(gv_pdf) == "420 x 297", gv_out
        gv_body = gv_html.read_text(encoding="utf-8")
        assert 'class="graphviz-wrap"' in gv_body
        assert "<svg" in gv_body
        assert "digraph" not in gv_body
        assert "```dot" not in gv_body
        gv_text = subprocess.check_output(
            ["pdftotext", "-layout", str(gv_pdf), "-"],
            text=True,
        )
        assert "Article" in gv_text
        assert "Article category" in gv_text
        assert "Author" in gv_text
        folded_gv = gv_text.casefold()
        assert "digraph" not in folded_gv, gv_text
        assert "fillcolor" not in folded_gv, gv_text
        assert "```dot" not in gv_text
        assert_inside_media_box(gv_pdf)

    preview_md = ROOT / "asc" / "doc" / "fixtures" / f"a3-preview-{tmp.name}.md"
    extra_paths.append(preview_md)
    preview_md.write_text("# Preview probe\n\nOne paragraph.\n", encoding="utf-8")
    preview_html = print_html_for(preview_md)
    subprocess.run(
        ["./asc/doc/html_preview.sh", str(preview_md.relative_to(ROOT))],
        check=True,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    preview_page = preview_html.read_text(encoding="utf-8").split("@page", 1)[1].split("}", 1)[0]
    assert "size: A4" in preview_page
    assert "A3" not in preview_page
    assert page_mm(diagram_pdf) == "420 x 297"
    print("ok")
finally:
    shutil.rmtree(tmp)
    for html_path in written_html:
        html_path.unlink(missing_ok=True)
    for path in extra_paths:
        path.unlink(missing_ok=True)
PY
  assertEquals 'A3 landscape export assertions failed' 0 $?
}
```

The diagram fixture is the wide flowchart (`flowchart LR`, subgraph "The house") in [`asc/doc/fixtures/mermaid-dense.md`](../../../../asc/doc/fixtures/mermaid-dense.md). Finding `The house` in extracted text is not enough: a failed Mermaid render keeps the fence source, which also contains that label, and the exporter then warns `Mermaid diagram(s) left as source`. The A3 PDF must contain the node labels `The house`, `extract-once`, and `the world`, must not contain the source words `flowchart` and `subgraph`, and the export log must not contain `left as source`. The footer band is the bottom 36 pt, so a centered page number on A3 paper is not mistaken for diagram ink. Outside that band, the rightmost word on the A3 export must pass both the A4 export's rightmost content word and the A4 page width. That is the wide flowchart using the landscape sheet.

A word-box loop cannot prove that clipped content survived, because `pdftotext` does not return words Chromium dropped. The clip probe is a separate one-diagram file, `flowchart LR` with the single words `CLIPLEFT` and `CLIPRIGHT`. Both words must be present, `CLIPRIGHT` must sit to the right of `CLIPLEFT`, and both boxes must lie inside the A3 media box. A right edge that was clipped away fails because `CLIPRIGHT` is missing.

The table fixture is [`asc/doc/fixtures/widow-table.md`](../../../../asc/doc/fixtures/widow-table.md): filler paragraphs, the five-row Alpha–Echo table, then one table whose rows run from R01 through R45. The A3 text must contain every `Observation for Alpha` … `Observation for Echo` and every `Observation for R01` … `Observation for R45`. Alpha through Echo share one page. The R table continues onto a later page, its first page holds at least `MIN_TABLE_ROWS` (3) of those rows, and `Source` sits on that page at or above R01. The media-box loop still checks extracted ink. It is not the row-survival check. A4 portrait height matches A3 landscape height, so `parse_pdf_lines` with the default selected page still drops the footer. Heading-orphan rules stay on `test_page_review_heading_orphan` and [`asc/doc/fixtures/orphan-heading.md`](../../../../asc/doc/fixtures/orphan-heading.md). `test_diagrams_fit_print_page` still passes a height into `FIT_DIAGRAMS_JS` and stays as it is.

The Graphviz fixture is a temp copy of [`asc/doc/fixtures/graphviz-er.md`](../../../../asc/doc/fixtures/graphviz-er.md). Shared fitting already covers Mermaid and Graphviz wraps, but this live export proves an A3 landscape run renders the SVG and keeps the labels `Article`, `Article category`, and `Author` in the PDF text. Print HTML must contain `graphviz-wrap` and an `<svg>`, and must not retain `digraph` or a raw Graphviz fence. Tracked `graphviz-er.pdf` is not used. When `dot` is missing, the live test prints `skip A3 Graphviz` and still runs the Mermaid and table checks.

- [x] **Step 2: Run the full PDF suite from the repository root.**

```bash
bash asc/doc/asc/pdf.test.sh
```

Expected: existing cases pass, including `test_page_css_margins_match_pre_plan`, `test_constants_and_content_box`, `test_pipeline_order_in_driver`, `test_diagrams_fit_print_page`, the isolated `test_graphviz_er_fixture_pdf`, `test_export_failure_aggregation_source`, `test_export_tree_propagates_failure`, and `test_no_target_loops_propagate_failure`. The new live test passes, or it prints `skip A3 page size` when `pdfinfo`, `pdftotext`, or `md2pdf` is absent. A skip is not a pass of the page-size or Graphviz checks. On this host, poppler, `md2pdf`, and `dot` are required before calling the task done, so the Graphviz block must run rather than print `skip A3 Graphviz`. After the suite, `git status --short -- asc/doc/fixtures/*.pdf` stays clean.

The live test launches Chromium several times (probe file, directory pair, Mermaid at both sizes, clip probe, table at both sizes, Graphviz A3). That runtime is the acceptance cost.

## Acceptance checks

| Check | Expected |
|---|---|
| Default and `--force` on a current file | `pdfinfo` rounds to `210 x 297`. A second default run prints `skip (up to date):`. |
| `--a3-l` on that same current file, without `--force` | Does not skip. `pdfinfo` rounds to `420 x 297`. Output path is the same `*.pdf`. |
| Default run after that A3 file | Skips. `pdfinfo` stays `420 x 297`. |
| `--force` without `--a3-l` | `pdfinfo` returns to `210 x 297`. |
| `--a3-l` on a directory of two files | Both PDFs are `420 x 297`, including the file that was already a current A4. |
| `--force` on that directory | Both PDFs are `210 x 297`. |
| Copied `mermaid-dense.md` | A4 export is `210 x 297`. Later `--a3-l` is `420 x 297`. The export log has no `left as source` warning. A3 PDF text contains `The house`, `extract-once`, and `the world`, and does not contain `flowchart` or `subgraph`. Ignoring the bottom 36 pt, the widest content word on the A3 PDF is to the right of both the A4 export’s widest content word and the A4 media width (`210 * 72 / 25.4` pt). Print HTML has `@page` size `A3 landscape` and Mermaid `pageW` / `pageH` equal to `content_width_px(PAGE_A3_LANDSCAPE)` and `content_height_px(PAGE_A3_LANDSCAPE)`. |
| Clip probe | One `flowchart LR` with `CLIPLEFT` and `CLIPRIGHT`. Both words are in the A3 PDF, `CLIPRIGHT` is to the right of `CLIPLEFT`, and both boxes lie inside the A3 media box. The export log has no `left as source` warning. |
| Copied `widow-table.md` | Both A4 and A3 exports report `Pages:` of at least 2. A3 is `420 x 297`. The A3 text contains `Observation for Alpha` through `Observation for Echo` and `Observation for R01` through `Observation for R45`. Alpha through Echo share one page. The R table continues onto a later page, its first page contains at least `MIN_TABLE_ROWS` (3) of those rows, and `Source` is on that page at or above R01. |
| Copied `graphviz-er.md` | `--a3-l` yields `420 x 297`. Print HTML has `graphviz-wrap` and `<svg>`, without `digraph` or a raw fence. PDF text contains `Article`, `Article category`, and `Author`, and does not contain `digraph` or `fillcolor`. Words lie inside the A3 media box. |
| Directory with one blocked PDF path | `--force` on a temp tree exits non-zero; the sibling markdown still produces a PDF (`test_export_tree_propagates_failure`). |
| No-target branch (isolated project) | Temp project with its own `data/ideas` and `docs`, copied `pdf_export.sh`, stub `md2pdf_asc.py`: ideas fails once then succeeds, every docs file succeeds; no-target `--force` still exits non-zero, records four converter calls including both docs successes, and writes only the success PDFs (`test_no_target_loops_propagate_failure`). That fixture detects an `rc` reset before `docs`. Source test requires `|| rc=1`, `return "$rc"` / `exit "$rc"`, and a single no-target `rc=0` after `local_found=0` before the ideas loop (`test_export_failure_aggregation_source`). |
| Preview | A new `asc/doc/fixtures/a3-preview-<unique>.md` is previewed and then deleted, along with its print HTML. That HTML `@page` block contains `size: A4` and does not contain `A3`. Tracked fixture markdown/PDF under `asc/doc/fixtures/` are not used as export targets. The A3 Mermaid PDF from the temp copy is still `420 x 297`. |
| `pdf_export.sh --a3-l` with no path | Not run. Source test shows both tree loops call `doc_pdf_export_one`. |
| Fixture PDF bytes | Full suite leaves `asc/doc/fixtures/*.pdf` unchanged (`test_graphviz_er_fixture_pdf` exports a `data/tmp` copy). |
| Full suite | `bash asc/doc/asc/pdf.test.sh` from the repository root. Targeted red/green uses `PDF_TEST_FILTER=… bash asc/doc/asc/pdf.test.sh`. |

`pdfinfo` on this poppler build prints a dot decimal, for example `595.28 x 841.89 pts` for A4 and `1190.55 x 841.89 pts` for A3 landscape. Rounding each side with `pts * 25.4 / 72` yields the millimetre checks above. A parenthetical `(A3)` or `(landscape)` on that line does not change the field positions.

## Out of scope

- A general `--page-size` value, A3 portrait, and other ISO sizes.
- Recording the paper inside the PDF so a default export can detect an A3 file.
- Changing margins, 9pt body type, pipeline order, Mermaid candidate scoring, or the 108 mm image cap.
- Giving `html_preview.sh` a page-size flag or adding `data/tmp/` to its path allow-list.
- Editing the README.
- Running a no-target export against `data/ideas` and `docs`.
