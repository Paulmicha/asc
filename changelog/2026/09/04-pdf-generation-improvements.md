# PDF generation: orphan headings/tables, KaTeX, Mermaid, long code blocks

| Field | Value |
|-------|--------|
| **Date** | 2026-09-04 |
| **Status** | implemented (uncommitted) |
| **Scope** | ASC repo `/home/paul/Documents/asc` — print pipeline only: `asc/doc/md2pdf_asc.py`, `asc/doc/pdf_styles.css`, `asc/doc/pdf_export.sh`, `asc/doc/html_preview.sh`, plus new helpers under `asc/doc/`. Not the Nextcloud markdown sources. |
| **Related** | `1ca680d` (exporter + Mermaid), `070d013` / `426d3a5` / `0d0e66c` (KaTeX), md2pdf-mermaid 1.4.3, Mermaid 11.16.1 (`asc/vendor/mermaid.esm.min.mjs`), KaTeX 0.16.11 (`asc/vendor/katex/`) |
| **Lifecycle** | Implemented in this session. Do not treat this file as permission to edit the AI Reviews `.md` files. |
| **Living docs** | `asc/doc/pdf_export.sh` header (usage). No living `docs/asc/` page for print yet; add a short pointer only if the README catalog already lists the exporter. |
| **Shipped notes** | `@page` margins stay `.75cm .75cm`. Body type is **9pt** Spectral (`html` font-size); headings, code, and Mermaid labels use rem/em so they track that root. Pagination still walks layout pages (orphan table fragment first, then orphan heading); “already at the top” is `0.75em`. Mermaid `initialize` uses official `fontSize` / `flowchart.padding` / `nodeSpacing` / `wrappingWidth` derived at run time from `getComputedStyle(html).fontSize` (Mermaid’s API is pixels; 1em at 9pt = 12px). A measure-time stylesheet sets `.nodeLabel` to that same px so `foreignObject` HTML is not measured at the 16px browser default. After render, `ascFitViewBox` sets the SVG `viewBox` from `getBBox()` and `width: min(100%, <viewBox-width>px)` so a diagram never stretches past its intrinsic width (HTML preview and print). Candidate scoring still treats scale as `min(..., 1)`. Flowchart source is not rewritten (`[rect]` stays `[rect]`). Heading `id`s longer than 120 characters are shortened so Chromium PDF dest names stay within the 127-byte PDF name limit. Sequence diagrams always initialize with official `wrap: true` and `wrapPadding: 3` so long arrow labels wrap; messages that contain `;` / `--` / extra `:` are still quoted as a retry candidate. Probe heading matching prefers the PDF line whose Y matches the live layout, so a table of contents does not steal the keep-list. Failed Mermaid candidate renders leave `#dascMmd*` error SVGs in the document; those are removed so they do not print as a last-page “Syntax error in text”. Exploded `.code-line` spans no longer keep a `\n` between block lines (that doubled every tree/code line). A table spacer is not inserted when a heading plus a short intro owns that table (that was splitting §2.3). The probe keep-list counts PDF lines after a table header even when wide cells do not match full DOM row strings, so a heading that already has a full table on the probe page is not pushed. Orphan prevention includes `h1` (same 4-line rule as `h2`–`h6`). A push that overshoots the next page top no longer floors leftover spacer at one `<br>` (that printed as a blank line above the heading); `.asc-print-push + heading` also drops the extra `margin-top`. **Failed pushes clear the spacer** instead of restoring `minHeight` on the source page (that left ~8 blank lines before the Gazit preprocessing table in file 08 §13.1). |

---

# PDF rendering improvements — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make ASC Markdown→PDF output readable: no orphan headings or tiny table fragments at page bottoms, working math, readable Mermaid, long code blocks that split across pages, and a one-line gap only between two long consecutive paragraphs.

**Architecture:** Keep the existing Playwright/Chromium path (`md2pdf_asc.py` wrapping md2pdf-mermaid). Every fix that changes box heights runs in a **fixed pipeline** (Locked design § pipeline order). Heading/table `<br>` pagination is the last mutation before `page.pdf()`. Nothing that changes layout may run after it.

**Tech stack:** Python 3.13 (md2pdf-mermaid pipx venv), Playwright/Chromium, vendored Mermaid 11.16.1, vendored KaTeX 0.16.11, `pdf_styles.css`, poppler `pdftotext` for verification.

## Global constraints

- Engine stays Playwright/Chromium via `asc/doc/md2pdf_asc.py`. No WeasyPrint, Paged.js, or ReportLab switch.
- Do **not** edit the Nextcloud AI Reviews markdown. Fixes belong in the print pipeline so every export benefits.
- Offline only: keep `asc/vendor/mermaid.esm.min.mjs` and `asc/vendor/katex/`. Upgrade a vendor bundle only if a named bug in this plan requires it, and record the version.
- Pagination must **never** push an element whose rendered height exceeds one page’s content box (that recreates issue 5).
- **Pipeline order is locked** (Locked design § pipeline order). Orphan/widow pagination runs **last**. Do not reorder stages to “simplify” a task.
- In changelog/docs prose, `$` prefixes remain ASC placeholders only. Math delimiters are written in backticks.
- `html_preview.sh` shares every stage **except** pagination (string transforms + Mermaid + KaTeX + long-paragraph mark). The `<br>` loop is PDF-only.
- Do not commit unless the user asks. Task “Commit” steps are checkpoints for the implementing session.

---

## Context (what the pipeline does today)

`asc/doc/pdf_export.sh` calls `md2pdf_asc.py`. **Today** that is: protect dollars → Markdown → restore math → inject CSS/fonts/Mermaid+KaTeX boots → write HTML → Playwright wait on `__ascMermaidDone` / `__ascKatexDone` → `page.pdf()`. Independent boot flags are how the stages race. The new pipeline replaces that with one ordered boot plus a PDF-only last stage (Locked design § pipeline order).

Print geometry: A4, Playwright margins `top 0.6cm / right 0.7cm / bottom 1.0cm / left 0.7cm`, plus `@page { margin: .75cm }` in CSS. Body is 8pt Spectral, `line-height: 1.45` → **one line ≈ 11.6pt ≈ 4.1 mm**. Four lines ≈ 16.4 mm.

Chromium’s CSS `break-after: avoid` / `break-inside: avoid` on headings is **not** reliable enough to fix the reported orphans. That is why this plan uses measured `<br>` insertion, as requested, rather than CSS alone.

---

## Evidence from the reported files

### Issue 1 — orphan headings

File: `01-harness-doctrine-hooks-tools-skills-mcp.pdf`

- **Page 2** ends with `3. PER-SOURCE ROWS` and no body. The following paragraph starts on page 3. Zero lines after the heading on that page.
- **Page 15** ends with `18. CROSSWALK — INDUSTRY TERM → V5 TERM` plus one subtitle line (“For reading vendor documentation…”). The table starts on page 16.

Rule to implement: a heading near the bottom, with following content in the document, that has **fewer than 4 lines of that content on the same page**, must be pushed so the heading sits at the **top of the next page**.

**Stacked headings** (`h2` then `h3` with no body between them) are one keep-together **cluster**. Pushing only the inner heading orphans the outer one. Insert a single spacer **before the first heading of the cluster**. Multiple passes are still required: moving a cluster can leave an earlier heading newly in the bottom band. See Locked design § heading clusters.

### Issue 2 — tables split with a tiny first fragment

Same measurement loop, applied to `<table>`: if the fragment at the bottom of a page has **fewer than 3 rows** and those rows’ total height is **≤ 4 line-equivalents**, push the **whole table** so it starts at the top of the next page — but only if the table itself fits on one page. Tall tables must still be allowed to split (issue 5).

### Issue 3 — KaTeX failures

File: `05-routing-cascading-local-inference-modest-hardware.pdf` page 20 (also pages 18–19).

Two separate bugs, both visible on that spread:

1. **LaTeX delimiters are not in the pipeline.** The source uses `\(...\)` and `\[...\]` in §§1–2 and 22, and `` `$$...$$` `` in §22. `protect_katex_math()` and auto-render only know dollar delimiters. Markdown then turns `_T1_` inside `\(...\)` into `<em>`, so page 20 reads `with (p^{0}{T1} = 0.5), (p^{0} = 0.05) … Labels are } = 0.25), (p^{0}_{T3coarsened`. Table cells on the same page still show raw `(\hat p(\ell, t) \le \tau_{start})`.
2. **Display math that *does* run (dollar delimiters) explodes vertically** in Chromium PDF: the Beta prior formula on page 20 occupies a huge empty band (KaTeX vlist/struts). `0d0e66c` already set `.katex { display: inline-block }` and `output: 'html'`; that is not enough for `\frac` in display mode.

`html_has_katex()` also only looks for dollar signs, so a file that used only `\(...\)` would not even load KaTeX.

### Issue 4 — Mermaid

Vendored Mermaid 11.16.1, `htmlLabels: true`, `useMaxWidth: true`, `fontSize` 8pt / 11px, **plus** CSS `font-size: 8pt !important` on `.mermaid foreignObject`, `text`, `.nodeLabel`, `.edgeLabel`. Mermaid sizes nodes at one font, then CSS shrinks the ink inside those boxes (or the SVG is scaled down on top). That is the overlap / microscopic-type failure on dense `flowchart LR` graphs such as “The house” in `07-injection-redaction-anonymization-at-the-llm-boundary.md`.

`pdf_styles.css` also sets mermaid `font-family: var(--pico-font-family-sans-serif)`, a variable that **does not exist** (the real token is `--pico-font-family-sans`). Boot JS uses Spectral serif. Diagrams do not share one type path.

Specific diagrams:

| Diagram | Source | Failure |
|---------|--------|---------|
| `flowchart LR` triage/router | `05-…modest-hardware.md` §1.3 | Readable (keep this quality) |
| `stateDiagram-v2` draft/pair | `06-…cli-ergonomics.md` | Readable (keep) |
| `flowchart LR` subgraph `house` | `07-…llm-boundary.md` §1 | Overlapping labels, tiny type |
| `stateDiagram-v2` Suspended/Waking | `02-…local-models-sync.md` §4.5 | Floating nonsense text at the top (long transition labels drawn outside the viewBox / leftover parse text) |
| `gantt` tracer order | `10-…staged-roadmap.md` §5.8 | Overlapping axis/section/bar labels |

Simple LR flowcharts already work. Do not regress them.

### Issue 5 — long code blocks leave blank pages

File: `04-security-and-privacy-operations-secrets-keys-container-hardening-supply-chain-gdpr-lgpd.pdf`

- Page 9: `3.1 From requirements to a file` + the intro paragraph, then empty paper.
- **Page 10 is blank** (footer `10 / 30` only).
- Page 11: the `compose.worker.yml` fence starts.

Cause: `pre { overflow-x: auto }` plus `pre code { display: inline-block; width: 100% }` makes an unbreakable box. Chromium cannot fit it in the leftover space on page 9, skips page 10 still looking for a hole tall enough, then paints on page 11. `white-space: pre-wrap` is already set and is **not** enough while the inner `code` is `inline-block`.

Chromium also does not reliably fragment a real `<pre>` even with `break-inside: auto`. The robust fix is to **turn each source line into a block box** so fragmentation behaves like paragraphs.

### Issue 6 — blank lines between paragraphs disappear

File: `04-…gdpr-lgpd.pdf` §4.2 (page 15). Source has a blank line between the intro paragraph, `**Keep (20):**`, and `**Noise (for this household):**`. The PDF runs them together with no gap.

Markdown already turned those blank lines into adjacent `<p>` tags. `pdf_styles.css` then sets `p { margin-bottom: 0 }`, so consecutive paragraphs have no separation. Extra blank lines beyond the first are discarded by Markdown itself (they never reach HTML).

A blanket `p + p { margin-top: … }` is **too generic**: short paragraphs (one or two rendered lines — titles of a thought, a single-sentence note) must stay tight. The gap is only for **two long paragraphs in a row**. In §4.2 that means Keep (20) / Noise (both wrap to many lines) get a gap; a 2-line intro against Keep stays compact.

---

## Goals

1. Headings (`h2`–`h6`) that would sit at the bottom with fewer than 4 lines of following **body** on that page start at the top of the next page. Consecutive headings with no body between them move together.
2. Tables whose first page fragment is fewer than 3 rows and ≤ 4 line-equivalents start on the next page, unless the table is taller than one page (then it splits).
3. `\(...\)`, `\[...\]`, `` `$...$` ``, and `` `$$...$$` `` all typeset; no Markdown-eaten underscores; display fractions no longer explode; `.katex-error` is logged.
4. Dense flowcharts, long-label state diagrams, and gantt charts are readable: no overlapping labels, no stray text, no microscopic type. The pipeline may apply **meaning-preserving** layout retries (including `LR` → `TD`) and keep the author’s version when it already scores as well.
5. A 100-line fence (the worker Compose file) flows page-to-page with **no blank pages** before or inside it.
6. Two consecutive `<p>` elements each ≥ 3 **rendered** lines get a one-line gap (the Markdown blank line). Pairs where either paragraph is shorter stay tight (`p { margin-bottom: 0 }`).

## Non-goals

- Rewriting Mermaid (or any review) source **on disk**. In-memory layout retries at print/preview time are in scope.
- Changing body type size, Spectral, or Pico colors.
- Tagged-PDF / accessibility tree.
- Perfect CSS fragmentation of nested tables inside code.

---

## Approaches considered

### Orphan headings / widow tables (issues 1–2)

| | Approach | Trade-off |
|---|---|---|
| A | CSS only (`break-after: avoid` on headings, `break-inside: avoid` on small tables) | Cheap; Chromium print ignores it often enough that page 2 / page 15 already exist |
| **B (chosen)** | **Measure, then insert as many `<br>` as needed before the heading/table** so it lands at the top of the next page | Matches the requested technique; needs a loop; leftover empty space on the previous page is intentional |
| C | One `page-break-before: always` class when an orphan is detected | Same visual; fewer DOM nodes; not what was asked |

**Choice: B.** Implement the spacer as a `<div class="asc-print-push">` containing **N `<br>` tags**, with N computed from remaining space on the current page (so we do not guess 1, 2, 3… blindly). Operate on **heading clusters**, not isolated tags. Re-measure; add more `<br>` if the cluster is still not at the top; cap passes at 8.

### KaTeX (issue 3)

| | Approach | Trade-off |
|---|---|---|
| **A (chosen)** | **Protect and auto-render `\(...\)` / `\[...\]` as well as dollar delimiters**; then flatten display-math layout for Chromium | Fixes all reviews without editing them |
| B | Convert every review to dollar delimiters | Out of scope (source edits) |
| C | Replace KaTeX with MathJax | Large vendor change; not needed |

### Mermaid (issue 4)

| | Approach | Trade-off |
|---|---|---|
| A | Stop the 8pt `!important` fight, scale the SVG, viewBox repair only | Fixes some overlap; a wide `flowchart LR` still shrinks to unreadability |
| **B (chosen)** | **A, then score meaning-preserving layout candidates and keep the most legible** (`LR`↔`TD`, spacing, label wrap). Prefer the original on a tie | Extra `mermaid.render` calls (capped); topology and wording stay identical |
| C | Always force `TD` | Punishes diagrams that are already clear as `LR` (the triage/router chart) |

**Choice: B.** Do not edit the `.md` files. Mutate only the in-memory diagram text inside the print HTML / live page.

### Long code (issue 5)

| | Approach | Trade-off |
|---|---|---|
| A | CSS only (`overflow: visible`, `break-inside: auto`, `pre code { display: block }`) | Necessary, not sufficient on Chromium |
| **B (chosen)** | **A, plus explode each fence into per-line block elements** | Page breaks like paragraphs; keeps monospace styling |
| C | Split fences in Markdown to 40-line chunks | Edits sources; ugly |

### Paragraph gaps (issue 6)

| | Approach | Trade-off |
|---|---|---|
| A | CSS `p + p { margin-top: 1em }` | Matches every Markdown paragraph break, including short `<p>` the compact theme currently glues |
| **B (chosen)** | **Measure rendered line count; add a gap only when both adjacent `<p>` have ≥ 3 lines** | Needs a layout pass (not possible in CSS). Short pairs stay tight |
| C | Fence-aware Markdown preprocessor that injects `<br>` for blank lines between “long” source paragraphs | Character-count ≠ rendered lines at 8pt / A4; must reimplement Markdown block rules |

**Choice: B.** Do not insert extra nodes for every blank line in the file. Keep `p { margin-bottom: 0 }`. After fonts/KaTeX/Mermaid, classify each `p`, then CSS:

```css
p.asc-para-long + p.asc-para-long {
  margin-top: 1em; /* one body line-height at 8pt */
}
```

---

## Locked design

### Pipeline order (do not reorder)

These fixes change **height and wrapping**. Running them in the wrong order undoes earlier work: pagination spacers are computed from page bottoms; anything that later grows or shrinks a box makes those spacers wrong (orphan headings return, or blank bands appear).

**Coding order ≠ runtime order.** Tasks may be implemented as unit-tested helpers in any sequence. The orchestrator (`md2pdf_asc.py` + one boot function) must call them in the stages below. Pagination is wired last (Task 6) because it is the last **runtime** stage, not because it is the first thing to code.

#### Stages

| # | Stage | When | Issue | Mutates |
|---|--------|------|-------|---------|
| 1 | Protect math (dollars + `\(`/`\[`) | Python, before Markdown | 3 | source string |
| 2 | Markdown → HTML | existing md2pdf | — | HTML |
| 3 | Restore math + wrap display | Python | 3 | HTML |
| 4 | Explode fence lines (`.code-line`) | Python, after HTML exists | 5 | HTML (not `pre.mermaid`) |
| 5 | Inject CSS, fonts, **single** boot script | Python | — | HTML |
| 6 | Write `data/tmp/doc-print/*.html` | existing | — | disk |
| 7 | Playwright `goto` + `document.fonts.ready` | browser | — | layout |
| 8 | Mermaid: candidates, pick, viewBox fit | browser (boot) | 4 | diagram boxes |
| 9 | KaTeX: auto-render + display flatten | browser (boot), after 8 | 3 | math boxes; may rewrap inline `<p>` |
| 10 | `emulateMedia('print')` | Playwright, PDF only | — | used metrics |
| 11 | Mark `p.asc-para-long` | browser, after 8–10 | 6 | `margin-top` on long+long pairs (shifts y below) |
| 12 | Heading/table `<br>` pagination | Playwright, **last mutation** | 1–2 | inserts `.asc-print-push` |
| 13 | `page.pdf()` | Playwright | — | none |

Preview (`html_preview.sh`) runs **1–9 and 11** (skip 10/12/13). It still marks long paragraphs so the HTML preview matches PDF rhythm.

`--no-paginate` skips **only** stage 12. It must not skip 4–11: those are what pagination measures.

#### One boot, one ready flag

Do **not** wait on independent `__ascMermaidDone` / `__ascKatexDone` and then PDF. Those can finish in either order, and paragraph marking would race them.

Inject **one** async boot (preview and PDF share it):

```javascript
async function ascLayoutBoot() {
  await document.fonts.ready;
  await ascRunMermaid();   // stage 8; may no-op if no diagrams
  await ascRunKatex();     // stage 9; skip .mermaid / pre / code; flatten display
  // Preview: mark paragraphs here. PDF: Playwright re-runs mark after emulateMedia.
  if (!window.__ascPdfDriver) {
    ascMarkLongParagraphs();
  }
  window.__ascLayoutReady = true;
}
ascLayoutBoot();
```

Playwright driver (PDF only):

```python
# PIPELINE PDF: wait layout → emulate print → mark paras → paginate → pdf
await page.add_init_script("window.__ascPdfDriver = true")
await page.goto(html_url)
await page.wait_for_function("window.__ascLayoutReady === true")
await page.emulate_media(media="print")           # stage 10
await page.evaluate(MARK_LONG_PARAS_JS)           # stage 11 (print metrics)
inserted = await apply_print_pushes(page)         # stage 12 LAST
await page.pdf(**pdf_options)                     # stage 13
```

Set `window.__ascPdfDriver = true` from Playwright **before** the boot finishes (add it as an init script, or a tiny inline `true` in the PDF HTML only) so the boot does not mark paragraphs on screen metrics and then skip the print re-mark. If the init script is missing, still re-run `MARK_LONG_PARAS_JS` after `emulateMedia` (idempotent: class add only).

**Forbidden after stage 12:** re-running Mermaid, KaTeX, display flatten, code explode, paragraph marking, CSS injection, or font swaps. Pagination’s own inner passes (up to `MAX_PASSES`) are still stage 12.

#### Why this order (interference)

| Swap | What breaks |
|------|-------------|
| Explode code (4) after pagination (12) | Unbreakable `<pre>` returns; spacers measured on a box taller than a page; issue 5 blank leaves come back |
| Mermaid (8) after pagination (12) | `LR`↔`TD` / scale changes diagram height; pushed headings are no longer at the top of the next page |
| KaTeX flatten (9) after pagination (12) | Display `\frac` shrinks; leftover empty band **or** a new orphan in the space that opened |
| Para-mark (11) after pagination (12) | Long+long `margin-top: 1em` shifts every following y; spacers no longer fill to the page break |
| Pagination (12) before `emulateMedia('print')` (10) | Measures screen layout, writes a PDF with different wrapping |
| KaTeX (9) after para-mark (11) | Inline math changes `<p>` wrap; `asc-para-long` is stale; gaps and later page bottoms are wrong |
| Mermaid (8) after KaTeX (9) | Usually OK (KaTeX skips `pre.mermaid`), but if a diagram is already an SVG, a second mermaid pass replaces it and shifts y. Keep Mermaid **before** KaTeX so math never sees half-rendered diagrams |
| Pagination before explode / mermaid / katex / para-mark | Measures a document that is about to change height. **Orphans must run last.** |

Paragraph marking is **not** pagination. It only classifies heights. It must still finish before spacers, because the 1em gap is real height.

Put this numbered list in the `md2pdf_asc.py` module docstring and in `pdf_export.sh`’s header so later edits cannot “just move the wait”.

### Print spacer (issues 1–2)

Inserted immediately before the heading or table:

```html
<div class="asc-print-push" data-asc-push="heading|table" aria-hidden="true"><br><br><!-- N --></div>
```

CSS:

```css
.asc-print-push {
  margin: 0;
  padding: 0;
  line-height: var(--pico-line-height);
  font-size: var(--asc-font-size);
}
```

**Heading clusters (not isolated tags):**

A **cluster** is a maximal run of consecutive `h2`–`h6` with nothing between them except whitespace, empty nodes, and existing `.asc-print-push` spacers. Skip `h1`. Examples:

| DOM | Cluster(s) |
|-----|------------|
| `h2, p, h3, p` | `[h2]` then `[h3]` |
| `h2, h3, p` | `[h2, h3]` |
| `h2, h3, h4, table` | `[h2, h3, h4]` |
| `h2, p (10 lines), h3` | `[h2]` then `[h3]` |

The keep-together unit is **the whole cluster plus the first 4 line-equivalents of the following non-heading body** (paragraph, list, table, …). An inner heading is **not** “following text” for the outer one.

**Push target:** one spacer **before the first heading of the cluster**. Never insert a spacer between two headings of the same cluster (that would send `h3` to the page *after* `h2`).

**Cluster push rule:**

- There is following **body** after the cluster (not only more headings at end of document).
- On the current page, body lines after the cluster are **&lt; 4** (zero counts).
- Remaining space from the first heading’s top is less than `cluster_height + MIN_FOLLOWING_LINES * line_height` (bottom band, using `PUSH_BAND_LINES` as the conservative threshold).
- `cluster_height ≤` one content box (otherwise leave it; same guard as tall tables).

Then `N = ceil(remaining_px / br_height_px)` `<br>` before the first heading.

**Why one pass is not enough even with clusters:** pushing `[h2, h3]` at the bottom of page N can leave an earlier `h2` (with a 2-line paragraph) newly sitting in the bottom band of page N. Pass 2 measures again and may push that earlier cluster. Stop when a pass inserts/extends nothing, or after `MAX_PASSES`.

**Why “push each heading, then loop” is the wrong multi-pass:**

1. Pass 1 inserts `<br>` before `h3` → `h2` stays at the bottom of page N (new orphan).
2. Pass 2 inserts `<br>` before `h2` → `h2` starts page N+1, but the spacer **between** `h2` and `h3` is still there, so `h3` can start page N+2.

Repair if that ever happens: if a spacer sits *inside* a cluster, move it before the first heading and delete the inner one. The primary algorithm must not create that spacer.

**Table rule interaction:** do not insert a table spacer immediately after a heading. If the cluster’s following sibling is a table, pushing the cluster already takes the table with it. Table-only push applies when the previous non-spacer sibling is not a heading.

**Table rule:**

- Table starts on page P and continues on page P+1 (or the first fragment is only at the bottom of P).
- Rows whose boxes lie on P: **count &lt; 3** and **sum(height) ≤ 4 line-heights**.
- **Whole table height ≤ one content box** (otherwise leave it splitting; issue 5).

Then the same `<br>` push **before the `<table>`** (not in the middle).

**Where it runs:** pipeline **stage 12 only** — last DOM mutation in `html_to_pdf_playwright`, after print media + long-paragraph mark, immediately before `page.pdf()`. New module: `asc/doc/print_paginate.py`. Never call `apply_print_pushes` from the shared HTML boot (preview must not paginate).

**How it measures:** Playwright `page.evaluate` after `emulateMedia({ media: "print" })`, using a CSS-pixel page model:

- Page width/height from A4 at 96 px/in (794 × 1123).
- Margins from the Playwright `pdf()` options (those are what Chromium uses; `preferCSSPageSize` stays false). Treat `@page { margin }` as non-authoritative unless we later set `preferCSSPageSize: true` — do **not** double-count. Sub-task: set `@page { margin: 0 }` so only Playwright margins apply (today both are set and the footer needs the 1.0 cm bottom).
- `y_document` = element `getBoundingClientRect().top + window.scrollY` (walk from `body`).
- `page_index = floor(y_document / content_height)`.
- `y_on_page = y_document % content_height`.
- Line height = computed `line-height` of `body` in px.
- Collect clusters first (walk headings in document order; absorb an immediately following heading into the current run).
- Following body lines for a cluster: walk siblings **after the last heading of the run**, skip `.asc-print-push`, measure non-heading height / line-height, stop at the next heading, after 4 line-equivalents, or at page end.

This model is an approximation of Chromium’s print fragmentainer. Compensate with a slightly conservative band (push if remaining &lt; **4.5** lines). After the loop, verify fixtures with `pdftotext -bbox-layout`. If a named review PDF still orphans, add a second pass that reads word `yMin`/`yMax` from `pdftotext -bbox` and drives the same `<br>` inserter (heading text matched in document order, case-folded; `h2` is `text-transform: uppercase` in CSS so PDF text is uppercase).

**Safety:** skip `pre`, `.mermaid-wrap`, `.katex-display` as push *targets* (they have their own rules). Do not push if doing so would leave the previous page with **only** the spacer and a heading that still does not fit (should not happen if height ≤ content box).

### Paragraph gaps (issue 6)

Keep `p { margin-bottom: 0 }`. Do **not** use `p + p`.

Pipeline **stage 11**. Shared function `ascMarkLongParagraphs` / `MARK_LONG_PARAS_JS`. Preview: run at the end of `ascLayoutBoot`. PDF: run again after `emulateMedia('print')` so line counts match the PDF, **then** paginate. Do not run it after spacers exist.

```javascript
() => {
  const lineH = parseFloat(getComputedStyle(document.body).lineHeight);
  document.querySelectorAll('p').forEach((p) => {
    if (p.closest('table, pre, .mermaid, .mermaid-wrap')) return;
    const lines = p.getBoundingClientRect().height / lineH;
    if (lines >= 3) p.classList.add('asc-para-long');
  });
  window.__ascParaMarked = true;
}
```

CSS:

```css
p.asc-para-long + p.asc-para-long {
  margin-top: 1em;
}
```

Rules:

- Gap only when **both** adjacent siblings are long (`≥ 3` rendered lines).
- Short + short, short + long, long + short: still no margin.
- Not inside tables, code, or Mermaid.
- One pass is enough (margin does not change line count).
- Must run **before** heading/table pagination (gaps change where page bottoms fall). Must run **after** fonts, Mermaid, KaTeX flatten, and (PDF) print media.

This is the HTML equivalent of “a Markdown blank line between two substantial paragraphs”. A 2-line intro still sits tight against a following long paragraph; two long paragraphs (Keep / Noise in §4.2) open a one-line gap.

### KaTeX (issue 3)

Extend `protect_katex_math` / `restore_katex_math` / `html_has_katex` / auto-render delimiters together.

Protection order, fenced-code split first (already done):

1. `` `$$...$$` `` → display placeholder, wrapped in `<div class="asc-math-display">`
2. `\[...\]` → same display wrap
3. `` `$...$` `` (existing inline regex)
4. `\(...\)` → inline placeholder

Auto-render `delimiters` (order matters — longer first):

```javascript
[
  {left: '$$', right: '$$', display: true},
  {left: '\\[', right: '\\]', display: true},
  {left: '$', right: '$', display: false},
  {left: '\\(', right: '\\)', display: false}
]
```

Keep `throwOnError: false`, `output: 'html'`, skip `.mermaid` / `pre` / `code`. After render:

- Remove `.katex-mathml` (already).
- Log every `.katex-error` to stderr with its `title` (KaTeX puts the parse error there) so exports of file 05 fail loudly in the log even if the PDF still ships.
- **Display flatten:** for each `.katex-display`, if `offsetHeight > 4 * bodyLineHeight`, apply a print-only fix: `.katex-display, .katex-display .katex, .katex-display .katex-html { line-height: 1; overflow: hidden; }` and force `.vlist-t { height: auto !important; }` / clip struts. If a single formula still paints a band taller than ~6 lines, scale that display box with `transform: scale(s)` (`s = max_height / offsetHeight`) and set an explicit `height`. Do not scale inline math.

Do not change the reviews’ mix of dollar vs LaTeX delimiters.

Pipeline **stage 9**: `ascRunKatex()` from `ascLayoutBoot`, **after** Mermaid. Flatten is part of this stage, not a later pass.

### Mermaid (issue 4)

**Root fix:** delete the global `font-size: … !important` rules on `.mermaid text / foreignObject / .nodeLabel / …` in both `pdf_styles.css` and `mermaid_boot_script()`. Those rules are why dense graphs overlap.

Keep `max-width: 100%; height: auto` on `svg`. Initialize at 13px (layout size), `useMaxWidth: false`, Source Sans 3, gantt paddings as below. Then **fit + score candidates**.

**Meaning-preserving = same graph, same words.** Allowed in-memory only:

| Kind | Allowed retries | Forbidden |
|------|-----------------|-----------|
| `flowchart` / `graph` | Header rank `LR`↔`TD` (and `RL`↔`BT`; `TD`/`TB` are the same axis). Extra `nodeSpacing` / `rankSpacing` / `wrappingWidth`. Wrap long node or edge labels at existing spaces / `<br>` (same tokens, same order). Leave inner `subgraph` `direction …` as authored | Dropping nodes/edges, changing labels, flattening subgraphs, changing solid/dotted/link text |
| `stateDiagram-v2` | Wrap long transition labels at spaces; `direction LR` vs default if the header allows it | Removing states or renaming transitions |
| `gantt` | `leftPadding`, `barHeight`, `barGap`, `topPadding`, font size (still scaled as a whole) | Reordering tasks, changing dates or `after` deps |
| All | `getBBox()` viewBox expansion; uniform scale to the page content box | CSS that shrinks type inside already-laid-out nodes |

Cap **4 candidates** per diagram, original first. If the original already has 0 text overlaps, scale-to-page ≥ 0.70, and min glyph size ≥ 10 px, **skip retries**.

**Score (lower penalty wins):**

```
penalty =
  100 * overlapping_text_pairs +
   80 * labels_clipped_outside_viewBox +
   40 * labels_overflowing_their_node +
   50 * (1 - scale_to_fit_page) +
   20 * max(0, 11 - min_font_px_after_scale)
```

On a penalty tie (or within 5 points), keep the **original** source. Log the pick: `mermaid[3]: LR → TD (80 → 12)`.

`scale_to_fit_page` is `min(contentW / bbox.w, contentH / bbox.h, 1)`.

**Where it runs:** pipeline **stage 8**, inside `ascRunMermaid()` called from `ascLayoutBoot` (preview and PDF share it). Completes **before** KaTeX and before any measurement. Playwright waits on `__ascLayoutReady`, not a standalone `__ascMermaidDone`.

Sketch:

```javascript
async function ascPickMermaid(m, pre, pageW, pageH) {
  const original = pre.textContent;
  const cands = ascMermaidCandidates(original); // original first
  let best = null;
  for (const c of cands) {
    const id = 'ascMmd' + (ascPickMermaid._n = (ascPickMermaid._n || 0) + 1);
    const { svg } = await m.render(id, c.code);
    const host = document.createElement('div');
    host.innerHTML = svg;
    const svgEl = host.querySelector('svg');
    const penalty = ascScoreMermaid(svgEl, pageW, pageH) + (c.original ? 0 : 0.1);
    if (!best || penalty < best.penalty) best = { svgEl, penalty, code: c.code };
  }
  pre.replaceChildren(best.svgEl);
  ascFitViewBox(best.svgEl, pageW, pageH);
}
```

Python (unit-tested, no browser) builds the candidate list so the JS stays thin:

```python
RANK_FLIP = {"LR": "TD", "RL": "BT", "TD": "LR", "TB": "LR", "BT": "RL"}

def mermaid_kind(src: str) -> str: ...  # flowchart|state|gantt|other

def flowchart_set_rank(src: str, rank: str) -> str:
    """Replace only the diagram header rank (flowchart|graph|flowchart-elk)."""

def wrap_long_labels(src: str, max_chars: int = 42) -> str:
    """Insert <br> at the last space before max_chars in quoted node/edge labels. Idempotent."""

def mermaid_candidates(src: str) -> list[tuple[str, bool]]:
    """Up to 4 items: (code, is_original). Original first."""
```

Do not force 8pt on diagram text. A 13px layout scaled to the page will land around 8–11pt when the graph is wide; if scale would drop min type below 10px, a `TD` candidate that is taller and narrower will win on penalty.

Unify font to **Source Sans 3** (fix `--pico-font-family-sans-serif` → `--pico-font-family-sans`).

### Code blocks (issue 5)

CSS (`pdf_styles.css`):

```css
pre,
pre.codehilite,
.codehilite {
  overflow: visible;
  page-break-inside: auto;
  break-inside: auto;
}
pre code,
pre samp {
  display: block;
  width: auto;
  white-space: pre-wrap;
  word-break: break-word;
}
.code-line {
  display: block;
  page-break-inside: avoid; /* one source line stays together */
  break-inside: avoid;
}
```

HTML transform (Python, on the HTML string after Markdown, shared with preview): wrap each line of `pre.codehilite > code` (and plain `pre > code`) in `<span class="code-line">…</span>`. Preserve highlighting spans *inside* a line. Trailing blank lines stay as empty `.code-line`s so vertical rhythm matches the source.

Do **not** wrap Mermaid’s `<pre class="mermaid">`.

Pipeline **stage 4**: run this on the HTML string after Markdown restore, **before** injecting the boot script and before Playwright. Pagination must never see an unexploded fence.

---

## File map

| File | Role |
|------|------|
| `asc/doc/md2pdf_asc.py` | Orchestrator: stages 1–13 in docstring order; `ascLayoutBoot` + Playwright driver; pagination is the last call before `page.pdf()` |
| `asc/doc/print_katex.py` | Extract + extend protect/restore/`html_has_katex`; `ascRunKatex()` (stage 9, after Mermaid) |
| `asc/doc/print_mermaid.py` | `ascRunMermaid()` (stage 8); candidate list (`flowchart_set_rank`, `wrap_long_labels`, `mermaid_candidates`); `FIT`/`SCORE` JS |
| `asc/doc/print_code.py` | `explode_pre_code_lines(html) -> html` (stage 4, string-time) |
| `asc/doc/print_paginate.py` | `MARK_LONG_PARAS_JS` (stage 11); `apply_print_pushes` (stage 12, PDF only) |
| `asc/doc/pdf_styles.css` | Code fragmentation, `.asc-print-push`, `p.asc-para-long + p.asc-para-long`, Mermaid, KaTeX, `@page` margin 0 |
| `asc/doc/html_preview.sh` | Stages 1–9 and 11; **no** stage 12 |
| `asc/doc/fixtures/para-gap.md` | Issue 6: two long paras, then a 2-line para against a long para |
| `asc/doc/fixtures/orphan-heading.md` | Issue 1: lone `h2` at page bottom |
| `asc/doc/fixtures/orphan-heading-stack.md` | Issue 1: `h2` then `h3` then short body at page bottom |
| `asc/doc/fixtures/widow-table.md` | Issue 2 fixture |
| `asc/doc/fixtures/katex-delimiters.md` | Issue 3 fixture (`\(`, `\[`, dollar, table cell, `\frac`) |
| `asc/doc/fixtures/mermaid-dense.md` | Issue 4: house flowchart + long-label state + gantt (copies of the reported diagrams) |
| `asc/doc/fixtures/long-code.md` | Issue 5: heading + short intro + 80-line fence |
| `asc/doc/asc/pdf.test.sh` | shunit2: Python unit tests + optional Playwright fixture exports |

`md2pdf_asc.py` is already ~690 lines. Split is part of the work, not a drive-by refactor: move KaTeX/Mermaid functions out when those tasks touch them.

---

## Constants (single source in `print_paginate.py`)

```python
MIN_FOLLOWING_LINES = 4
MIN_TABLE_ROWS = 3
MAX_WIDOW_LINE_EQUIV = 4.0
PUSH_BAND_LINES = 4.5          # conservative vs Chromium print
TOP_EPSILON_PX = 8.0
MAX_PASSES = 8
A4_WIDTH_PX = 210.0 * 96.0 / 25.4   # 793.7
A4_HEIGHT_PX = 297.0 * 96.0 / 25.4  # 1122.5
# Match html_to_pdf_playwright pdf_options["margin"]
MARGIN_TOP_CM = 0.6
MARGIN_RIGHT_CM = 0.7
MARGIN_BOTTOM_CM = 1.0
MARGIN_LEFT_CM = 0.7
PARA_LONG_MIN_LINES = 3
MERMAID_MAX_CANDIDATES = 4
MERMAID_SKIP_RETRY_SCALE = 0.70
MERMAID_MIN_FONT_PX = 10
MERMAID_LABEL_WRAP_CHARS = 42
MERMAID_TIE_EPS = 5.0

# Runtime order in md2pdf_asc.py (coding tasks may land earlier; this is call order):
# protect → markdown → restore → explode_code → inject → fonts → mermaid →
# katex → emulate_print → mark_long_paragraphs → paginate_orphans → page.pdf
# paginate_orphans is LAST. Preview stops before paginate_orphans.
```

Every task’s requirements include these values.

---

### Task 1: Fixtures and pagination decision helpers

Pure Python geometry tests only. Do **not** call `apply_print_pushes` from the exporter in this task (that is Task 6, runtime last).

**Files:**

- Create: `asc/doc/print_paginate.py` (pure Python first: geometry + clusters + `should_push_cluster` / `should_push_table`)
- Create: `asc/doc/fixtures/*.md` (five files listed above)
- Create: `asc/doc/asc/pdf.test.sh`
- Test: `asc/doc/asc/pdf.test.sh`

**Interfaces:**

- Consumes: nothing
- Produces:

```python
@dataclass(frozen=True)
class Box:
    y: float
    height: float
    page: int
    y_on_page: float

@dataclass(frozen=True)
class HeadingCluster:
    headings: tuple[Box, ...]          # document order; spacer goes before headings[0]
    cluster_height: float              # first.y to last.y+last.height
    following_lines_on_page: float
    has_following_body: bool

def content_box(page_h: float, margin_top: float, margin_bottom: float) -> float:
    return page_h - margin_top - margin_bottom

def should_push_cluster(cluster: HeadingCluster, content_h: float, line_h: float) -> bool:
    ...  # full body in Step 3

def should_push_table(...) -> bool:
    ...

def br_count(remaining_px: float, br_height_px: float) -> int:
    if br_height_px <= 0:
        raise ValueError("br_height_px must be positive")
    return max(1, math.ceil(remaining_px / br_height_px))

def merge_inner_spacers_needed(prev_is_heading: bool, spacer_between: bool) -> bool:
    """True when a spacer sits inside a cluster and must move before the first heading."""
    return prev_is_heading and spacer_between
```

`pdf.test.sh` lives at `asc/doc/asc/pdf.test.sh`. It sets `PYTHONPATH` to `asc/doc` and `PDF_PY` to the same interpreter `pdf_export.sh` uses.

- [ ] **Step 1: Write failing tests** in `pdf.test.sh` that call that Python:

```bash
test_should_push_cluster_zero_following_lines() {
  "$PDF_PY" - <<'PY'
from print_paginate import Box, HeadingCluster, should_push_cluster
h = Box(y=1000, height=16, page=0, y_on_page=1000)
c = HeadingCluster(headings=(h,), cluster_height=16, following_lines_on_page=0, has_following_body=True)
assert should_push_cluster(c, content_h=1062, line_h=15.5)
print("ok")
PY
}

test_should_push_stacked_h2_h3() {
  "$PDF_PY" - <<'PY'
from print_paginate import Box, HeadingCluster, should_push_cluster
h2 = Box(y=980, height=18, page=0, y_on_page=980)
h3 = Box(y=1000, height=16, page=0, y_on_page=1000)
c = HeadingCluster(
    headings=(h2, h3),
    cluster_height=36,
    following_lines_on_page=1,
    has_following_body=True,
)
assert should_push_cluster(c, content_h=1062, line_h=15.5)
# A mid-page h2+h3 with a full page of remaining space must not push:
h2b = Box(y=40, height=18, page=0, y_on_page=40)
h3b = Box(y=60, height=16, page=0, y_on_page=60)
mid = HeadingCluster(headings=(h2b, h3b), cluster_height=36, following_lines_on_page=1, has_following_body=True)
assert not should_push_cluster(mid, content_h=1062, line_h=15.5)
print("ok")
PY
}
```

Cases that must pass once implemented:

- cluster of one heading at bottom, 0 following body lines, has later body → push (page 2)
- cluster of one heading at bottom, 1 following line → push (page 15)
- cluster at bottom, 4 following body lines → no push
- cluster at top of page, 1 following line, lots of space below → no push (stacked `h2`+`h3` mid-page must not jump)
- cluster with no following body (end of doc) → no push
- cluster `[h2, h3]` at bottom, 1 body line → push **once**, target is `h2` (not `h3` alone)
- `merge_inner_spacers_needed(True, True)` is True
- table first fragment 2 rows, 30 px, table 200 px, content 1062 → push
- table first fragment 2 rows, table height 2000 px &gt; content → **no** push
- table first fragment 8 rows → no push
- `br_count(62, 15.5) == 4`

- [ ] **Step 2: Run tests; expect fail** (`print_paginate` missing)

Run: `bash asc/doc/asc/pdf.test.sh` from the repo root (bootstrap like other ASC tests, or `PYTHONPATH=asc/doc`).

Expected: FAIL import / assert

- [ ] **Step 3: Implement the helpers** in `print_paginate.py` with the constants above:

```python
def should_push_cluster(cluster, content_h, line_h):
    if not cluster.has_following_body:
        return False
    if cluster.cluster_height > content_h:
        return False
    if cluster.following_lines_on_page >= MIN_FOLLOWING_LINES:
        return False
    first = cluster.headings[0]
    remaining = content_h - first.y_on_page
    needed = cluster.cluster_height + PUSH_BAND_LINES * line_h
    return remaining < needed

def should_push_table(table_height, first_fragment_rows, first_fragment_height, content_h, line_h):
    if table_height > content_h:
        return False
    if first_fragment_rows >= MIN_TABLE_ROWS:
        return False
    return first_fragment_height <= MAX_WIDOW_LINE_EQUIV * line_h
```

- [ ] **Step 4: Re-run tests; expect pass**

- [ ] **Step 5: Write the fixture markdown files** (short; copy the reported Mermaid sources verbatim into `mermaid-dense.md`; `long-code.md` = `### 3.1 From requirements to a file` + two-sentence intro + 80 lines of YAML). `orphan-heading-stack.md` = filler until near page end, then `## 2. Parent` immediately followed by `### 2.1 Child` and two short sentences. `para-gap.md` = two 5-line paragraphs, then a 2-line paragraph plus a 5-line paragraph.

- [ ] **Step 6: Commit** (when asked)

```bash
git add asc/doc/print_paginate.py asc/doc/fixtures asc/doc/asc/pdf.test.sh
git commit -m "$(cat <<'EOF'
Add PDF pagination decision helpers and print fixtures.

EOF
)"
```

---

### Task 2: Explode code fences and allow page breaks (issue 5)

**Files:**

- Create: `asc/doc/print_code.py`
- Modify: `asc/doc/pdf_styles.css` (`pre` / `pre code` / `.code-line`; `@page { margin: 0; }` to match Playwright margins)
- Modify: `asc/doc/md2pdf_asc.py` (`markdown_to_html` wrapper calls `explode_pre_code_lines` as pipeline **stage 4**, before any Playwright work)
- Test: `asc/doc/asc/pdf.test.sh`

**Interfaces:**

- Consumes: HTML from md2pdf
- Produces: `explode_pre_code_lines(html: str) -> str`

- [ ] **Step 1: Failing test** in `pdf.test.sh`:

```python
from print_code import explode_pre_code_lines

html = '<pre class="codehilite"><code>a\nb\nc</code></pre>'
out = explode_pre_code_lines(html)
assert out.count('class="code-line"') == 3
assert "<span class=\"code-line\">a</span>" in out

mm = '<pre class="mermaid">flowchart LR\nA-->B</pre>'
assert explode_pre_code_lines(mm) == mm
```

- [ ] **Step 2: Run; expect fail**

- [ ] **Step 3: Implement `explode_pre_code_lines`** with stdlib `html.parser` (no BeautifulSoup). Skip `pre.mermaid`. Split on `\n` at the text-node level; keep inner highlight tags inside the line. Apply CSS as in Locked design.

- [ ] **Step 4: Unit tests pass**

- [ ] **Step 5: Export fixture** (needs Playwright):

```bash
asc/doc/pdf_export.sh --force 'asc/doc/fixtures/long-code.md'
python3 - <<'PY'
import subprocess
pdf = "asc/doc/fixtures/long-code.pdf"
text = subprocess.check_output(["pdftotext","-layout",pdf,"-"], text=True)
pages = text.split("\f")
blank = 0
for i,p in enumerate(pages,1):
    nonempty = [
        ln for ln in p.splitlines()
        if ln.strip() and not ln.strip().replace(" ", "").endswith(f"/{len(pages)}")
    ]
    if len(nonempty) == 0:
        blank += 1
        print("blank page", i)
assert blank == 0, blank
print("pages", len(pages), "ok")
PY
```

Expected: the fence starts on the same page as §3.1 or the immediately following page; **zero** fully blank pages; code continues onto later pages (page count ≥ 2 for an 80-line fence at 6pt).

- [ ] **Step 6: Re-export the reported security PDF** (read-only check, path outside the repo):

`asc/doc/pdf_export.sh --force '/mnt/78D4D83ED4D7FBF6/Nextcloud/AI Reviews/devops, linux, servers, networking, hosting, security, privacy/04-security-and-privacy-operations-secrets-keys-container-hardening-supply-chain-gdpr-lgpd.md'`

Confirm page 10 is no longer empty and the Compose fence starts without a blank leaf.

- [ ] **Step 7: Commit** (when asked)

---

### Task 3: KaTeX delimiters + Markdown protection (issue 3, bug 1)

**Files:**

- Create: `asc/doc/print_katex.py` (move `protect_katex_math`, `restore_katex_math`, `html_has_katex`; add `ascRunKatex` used by `ascLayoutBoot`)
- Modify: `asc/doc/md2pdf_asc.py` (import from `print_katex`; stages 1 and 3; start `ascLayoutBoot` — `ascRunMermaid` may be a no-op stub until Task 5)
- Test: `asc/doc/asc/pdf.test.sh`

**Interfaces:**

- Consumes: Markdown string
- Produces: same function names as today, plus LaTeX delimiters

- [ ] **Step 1: Failing tests**

```python
from print_katex import protect_katex_math, restore_katex_math, html_has_katex

md = r"Let \(\ell\) and \[ \frac{a}{b} \] and $x_1$ and $$y_2$$."
protected, placeholders = protect_katex_math(md)
assert len(placeholders) == 4
assert "@@ASC_MATH_0@@" in protected
assert r"\ell" not in protected
assert r"\frac" not in protected
assert html_has_katex(r"\(\ell\)") is True
assert html_has_katex(r"\[ a \]") is True
assert html_has_katex("no math here") is False
restored = restore_katex_math(protected, placeholders)
assert restored.replace("\n", "") == md.replace("\n", "") or all(
    tok in restored for tok in (r"\(\ell\)", r"\frac{a}{b}", "$x_1$", "$$y_2$$")
)

fenced = "```bash\nnvidia-smi > /tmp/gpu_w.$$ &\nrm -f /tmp/gpu_w.$$\n```\n"
protected_fenced, ph_fenced = protect_katex_math(fenced)
assert ph_fenced == []
assert "/tmp/gpu_w.$$" in protected_fenced
```

- [ ] **Step 2: Run; expect fail** (only 2 placeholders today)

- [ ] **Step 3: Implement delimiter protection and auto-render list** as in Locked design. `html_has_katex` must match dollar **or** `\\(` **or** `\\[`. Wire `ascLayoutBoot`: `fonts.ready` → `await ascRunMermaid()` → `await ascRunKatex()` → `__ascLayoutReady`. Do **not** restore independent `__ascKatexDone` as the PDF wait.

- [ ] **Step 4: Unit tests pass**

- [ ] **Step 5: Export `asc/doc/fixtures/katex-delimiters.md`** and `pdftotext` it. Must **not** contain raw `\hat p` or broken `p^{0}{T1}`. Must **not** contain `coarsened` glued to `T3`.

- [ ] **Step 6: Re-export file 05** (Nextcloud path) and inspect page 20: inline `\(\hat p(\ell)\)` typeset; table cells typeset.

- [ ] **Step 7: Commit** (when asked)

---

### Task 4: KaTeX display-math Chromium flatten (issue 3, bug 2)

**Files:**

- Modify: `asc/doc/print_katex.py` (`ascRunKatex` CSS + flatten; still **stage 9**, after Mermaid)
- Modify: `asc/doc/pdf_styles.css` (display-math rules)
- Test: fixture PDF from Task 3

**Interfaces:**

- Consumes: rendered `.katex-display` nodes
- Produces: flatten inside `ascRunKatex` (before `__ascLayoutReady`); `.katex-error` logged via `console.error` (Playwright already prints)

- [ ] **Step 1: Add a display `\frac` / `\qquad` pair to `katex-delimiters.md`** matching file 05 §22.2 (the Beta prior formula).

- [ ] **Step 2: Export; measure** with `pdftotext -bbox` the y-span of that formula. Fail the test if the formula’s bbox height &gt; 6 line-heights at 8pt (~70 pt).

- [ ] **Step 3: Implement flatten CSS + optional scale** as in Locked design. Log `.katex-error` count in `html_to_pdf_playwright`:

```python
err_n = await page.evaluate("() => document.querySelectorAll('.katex-error').length")
if err_n:
    print(f"warning: {err_n} KaTeX error span(s)", file=sys.stderr)
```

- [ ] **Step 4: Re-export file 05.** Page 20 formula occupies a normal display band, not a half-page gap. Surrounding sentence is typeset.

- [ ] **Step 5: Commit** (when asked)

---

### Task 5: Mermaid layout, fit, and scored retries (issue 4)

**Files:**

- Create: `asc/doc/print_mermaid.py` (move `mermaid_boot_script`, `patch_mermaid_as_html`; add candidate helpers + score/pick JS)
- Modify: `asc/doc/pdf_styles.css` (drop 8pt `!important` on mermaid internals; fix `--pico-font-family-sans-serif`; keep `svg { max-width: 100%; height: auto }`)
- Modify: `asc/doc/md2pdf_asc.py` (import boot from `print_mermaid`)
- Test: `asc/doc/asc/pdf.test.sh` (pure Python candidates) + `asc/doc/fixtures/mermaid-dense.md` (house + WoL state + gantt + the file 05 triage/router flowchart as control)

**Interfaces:**

- Consumes: mermaid source string from `<pre class="mermaid">`
- Produces:

```python
RANK_FLIP = {"LR": "TD", "RL": "BT", "TD": "LR", "TB": "LR", "BT": "RL"}

def mermaid_kind(src: str) -> str:
    """flowchart | state | gantt | other — from the first non-comment, non-init line."""

def flowchart_set_rank(src: str, rank: str) -> str:
    """Replace only the header token after flowchart|graph|flowchart-elk. Leave subgraph direction lines untouched."""

def wrap_long_labels(src: str, max_chars: int = MERMAID_LABEL_WRAP_CHARS) -> str:
    """In double-quoted labels and in `A --> B : rest-of-line` state labels, insert <br> at the last space before max_chars. Do not change unquoted ids. Idempotent."""

def mermaid_candidates(src: str) -> list[tuple[str, bool]]:
    """Up to MERMAID_MAX_CANDIDATES items: (code, is_original). Original first. Flowchart: original, flipped rank, wrapped, flipped+wrapped (skip duplicates). Gantt/state: original, wrapped, plus one `%%{init: ...}%%` spacious variant. Other: original only."""
```

- [ ] **Step 1: Failing Python tests**

```python
from print_mermaid import flowchart_set_rank, wrap_long_labels, mermaid_candidates, mermaid_kind

src = "flowchart LR\n  A[\"hello world this is a long node label here\"] --> B\n"
assert mermaid_kind(src) == "flowchart"
td = flowchart_set_rank(src, "TD")
assert td.startswith("flowchart TD")
assert "A[" in td and "--> B" in td
assert "subgraph" not in td or "direction LR" in src  # no subgraph in this fixture
wrapped = wrap_long_labels(src, max_chars=20)
assert "<br>" in wrapped
assert "hello" in wrapped and "world" in wrapped
cands = mermaid_candidates(src)
assert cands[0][1] is True
assert any(c[0].startswith("flowchart TD") for c in cands)
assert len(cands) <= 4

inner = "flowchart LR\n  subgraph house[\"The house\"]\n    direction TB\n    A-->B\n  end\n"
flipped = flowchart_set_rank(inner, "TD")
assert "direction TB" in flipped
assert flipped.splitlines()[0].startswith("flowchart TD")
```

- [ ] **Step 2: Run; expect fail**

- [ ] **Step 3: Implement helpers** as specified. Header regex: `^(flowchart(?:-elk)?|graph)\s+(LR|RL|TB|TD|BT)\b`. If the header has no rank, do not invent one.

- [ ] **Step 4: Boot — `ascRunMermaid()`** (pipeline stage 8). 13px init, `useMaxWidth: false`, no 8pt `!important`. After `m.initialize`, for each `pre.mermaid`: if original render scores under the skip threshold, keep it; else `m.render` each candidate, pick min penalty, `replaceChildren` with the winning SVG, then `ascFitViewBox`. On failure, leave original + `console.error`. `ascLayoutBoot` must `await ascRunMermaid()` **before** `await ascRunKatex()`. Do not set a standalone `__ascMermaidDone` that the PDF driver waits on.

`ascScoreMermaid(svg, pageW, pageH)` implements the penalty formula. Overlap: every pair of `text, .edgeLabel, .nodeLabel, foreignObject` boxes whose intersection area &gt; 2 px². `min_font_px_after_scale` = smallest computed `font-size` of those nodes × `scale_to_fit_page`.

- [ ] **Step 5: Export `mermaid-dense.md`.** Checks:

- House flowchart: labels such as `① content → model` readable; no stacked overlapping words. A `TD` pick is acceptable if that is what wins; topology (same nodes, edges, subgraph `house`) must match the source.
- Control triage/router `flowchart LR`: still readable; **prefer staying `LR`** if its penalty is within `MERMAID_TIE_EPS` of `TD`.
- State diagram: no stray tokens at the top; long WoL labels may wrap; transitions still connect the same states.
- Gantt: section names do not sit on bar labels.

Export log should mention a pick when a non-original candidate wins.

- [ ] **Step 6: Re-export files 05, 07, 02, 10** (Nextcloud) and spot-check those four diagrams.

- [ ] **Step 7: Commit** (when asked)

---

### Task 6: `<br>` pagination loop (issues 1–2) — **runtime last**

This task **wires** pagination. It must not run earlier in the export. Helpers from Task 1 are fine; calling `apply_print_pushes` before layout boot is not.

**Files:**

- Modify: `asc/doc/print_paginate.py` (add `MARK_LONG_PARAS_JS`, `PAGINATE_JS`, `async def apply_print_pushes(page) -> int`)
- Modify: `asc/doc/md2pdf_asc.py` (`html_to_pdf_playwright` follows Locked design § pipeline order stages 10–13 only)
- Modify: `asc/doc/pdf_styles.css` (`.asc-print-push`)
- Test: fixtures `orphan-heading.md`, `orphan-heading-stack.md`, `widow-table.md`, `para-gap.md`; driver source-order test

**Interfaces:**

- Consumes: Task 1 helpers; Playwright `Page` **after** stages 1–11 (`__ascLayoutReady`, print media, long-paragraph mark)
- Produces: `async def apply_print_pushes(page) -> int`  # number of spacers inserted; last DOM mutation before `page.pdf()`

Playwright snippet (stored as `PAGINATE_JS` in `print_paginate.py`). Each pass: **collect clusters**, then one spacer per cluster that fails the fit test; then tables (skip if previous non-spacer sibling is a heading). After inserts, if a spacer sits between two headings of the same cluster, move it before the first heading.

```javascript
({ contentH, lineH, minFollow, minRows, maxWidowLines, pushBandLines, topEps, maxPasses }) => {
  const brH = (() => {
    const d = document.createElement('div');
    d.className = 'asc-print-push';
    d.innerHTML = '<br>';
    document.body.appendChild(d);
    const h = d.getBoundingClientRect().height || lineH;
    d.remove();
    return h;
  })();

  const isHeading = (el) => el && /^H[2-6]$/.test(el.tagName);
  const isPush = (el) => el && el.classList && el.classList.contains('asc-print-push');
  const yOf = (el) => el.getBoundingClientRect().top + window.scrollY;
  const pageOf = (y) => Math.floor(y / contentH);
  const yOn = (y) => y - pageOf(y) * contentH;

  const nextReal = (el) => {
    let n = el.nextElementSibling;
    while (n && (isPush(n) || n.getBoundingClientRect().height === 0)) n = n.nextElementSibling;
    return n;
  };

  const collectClusters = () => {
    const heads = [...document.querySelectorAll('h2,h3,h4,h5,h6')];
    const clusters = [];
    let i = 0;
    while (i < heads.length) {
      const run = [heads[i]];
      let j = i + 1;
      while (j < heads.length && nextReal(run[run.length - 1]) === heads[j]) {
        run.push(heads[j]);
        j += 1;
      }
      clusters.push(run);
      i = j;
    }
    return clusters;
  };

  const followingBodyLines = (lastHeading) => {
    let acc = 0;
    let n = nextReal(lastHeading);
    const startPage = pageOf(yOf(lastHeading));
    const hasBody = !!(n && !isHeading(n));
    while (n && !isHeading(n)) {
      if (pageOf(yOf(n)) !== startPage) break;
      acc += n.getBoundingClientRect().height / lineH;
      if (acc >= minFollow) break;
      n = nextReal(n);
    }
    return { lines: acc, hasBody };
  };

  const repairInnerSpacers = () => {
    let moved = false;
    for (const run of collectClusters()) {
      if (run.length < 2) continue;
      for (let k = 1; k < run.length; k++) {
        const inner = run[k].previousElementSibling;
        if (!isPush(inner)) continue;
        inner.remove();
        const first = run[0];
        if (!(first.previousElementSibling && isPush(first.previousElementSibling))) {
          first.parentNode.insertBefore(inner, first);
        }
        moved = true;
      }
    }
    return moved;
  };

  let inserted = 0;
  for (let pass = 0; pass < maxPasses; pass++) {
    let changed = repairInnerSpacers();
    for (const run of collectClusters()) {
      const first = run[0];
      const last = run[run.length - 1];
      const y = yOf(first);
      const clusterH = (yOf(last) + last.getBoundingClientRect().height) - y;
      if (clusterH > contentH) continue;
      const { lines: fl, hasBody } = followingBodyLines(last);
      if (!hasBody) continue;
      if (fl >= minFollow) continue;
      const remaining = contentH - yOn(y);
      const needed = clusterH + pushBandLines * lineH;
      if (remaining >= needed) continue;
      const prev = first.previousElementSibling;
      const nBr = Math.max(1, Math.ceil(remaining / brH));
      if (isPush(prev)) {
        if (yOn(y) <= topEps) continue;
        prev.insertAdjacentHTML('beforeend', '<br>'.repeat(nBr));
      } else {
        const push = document.createElement('div');
        push.className = 'asc-print-push';
        push.setAttribute('data-asc-push', 'heading');
        push.setAttribute('aria-hidden', 'true');
        push.innerHTML = '<br>'.repeat(nBr);
        first.parentNode.insertBefore(push, first);
      }
      inserted += 1;
      changed = true;
    }
    const tables = [...document.querySelectorAll('table')];
    for (const t of tables) {
      let prevReal = t.previousElementSibling;
      while (prevReal && (isPush(prevReal) || prevReal.getBoundingClientRect().height === 0)) {
        prevReal = prevReal.previousElementSibling;
      }
      if (isHeading(prevReal)) continue;
      const tTop = yOf(t);
      const prev = t.previousElementSibling;
      const already = prev && prev.classList.contains('asc-print-push');
      if (already && yOn(tTop) <= topEps) continue;
      if (already) {
        prev.insertAdjacentHTML('beforeend', '<br>'.repeat(Math.max(1, Math.ceil((contentH - yOn(tTop)) / brH))));
        inserted += 1;
        changed = true;
        continue;
      }
      const th = t.getBoundingClientRect().height;
      if (th > contentH) continue;
      const rows = [...t.querySelectorAll('tr')];
      const startPage = pageOf(tTop);
      const onFirst = rows.filter((tr) => pageOf(yOf(tr)) === startPage);
      const fragH = onFirst.reduce((s, tr) => s + tr.getBoundingClientRect().height, 0);
      const splits = rows.some((tr) => pageOf(yOf(tr)) > startPage);
      if (!splits && yOn(tTop) + th <= contentH) continue;
      if (onFirst.length >= minRows) continue;
      if (fragH > maxWidowLines * lineH) continue;
      const remainingToEnd = contentH - yOn(tTop);
      const n = Math.max(1, Math.ceil(remainingToEnd / brH));
      const push = document.createElement('div');
      push.className = 'asc-print-push';
      push.setAttribute('data-asc-push', 'table');
      push.setAttribute('aria-hidden', 'true');
      push.innerHTML = '<br>'.repeat(n);
      t.parentNode.insertBefore(push, t);
      inserted += 1;
      changed = true;
    }
    if (!changed) break;
  }
  return inserted;
}
```

Wire-up in `html_to_pdf_playwright` — **this block is the SoT for PDF stages 7–13**. Do not insert Mermaid, KaTeX, explode, or paragraph work after `apply_print_pushes`.

```python
# PIPELINE PDF: wait layout → emulate print → mark paras → paginate → pdf
await page.add_init_script("window.__ascPdfDriver = true")
await page.goto(html_url)
await page.wait_for_function("window.__ascLayoutReady === true")
await page.emulate_media(media="print")
await page.evaluate(MARK_LONG_PARAS_JS)
if not no_paginate:
    inserted = await apply_print_pushes(page)
    print(f"  print pushes: {inserted}")
await page.pdf(**pdf_options)
```

- [ ] **Step 0: Driver order test** (no browser). Read `md2pdf_asc.py` and the injected boot. Assert this substring order in `html_to_pdf_playwright`: `__ascLayoutReady`, `emulate_media`, `MARK_LONG_PARAS_JS` (or `ascMarkLongParagraphs`), `apply_print_pushes`, `page.pdf`. Assert the boot contains `await ascRunMermaid()` before `await ascRunKatex()`. Assert `html_preview.sh` / preview HTML does not call `apply_print_pushes`.

- [ ] **Step 1: Fixture `orphan-heading.md`** — enough filler paragraphs (8pt) that `## 3. Per-source rows` would land at the bottom of page 1 without the loop, followed by a 12-line section. Export **without** pagination once (`--no-paginate`, skips **only** stage 12) to confirm the orphan exists; then enable pagination.

- [ ] **Step 2: Implement `--no-paginate`** (debug only) and the loop.

- [ ] **Step 3: Export with pagination.** `pdftotext -layout -f 1 -l 1` of `orphan-heading.md` must **not** end with the bare heading. The heading starts page 2 (or the next page) as the first body line (after any empty spacer). At least 4 lines of the section share that page **or** the whole remaining section fits.

- [ ] **Step 3b: Export `orphan-heading-stack.md`.** A page must not end on `## 2. Parent` alone, nor on `## 2. Parent` plus `### 2.1 Child` with no body. Both headings start the next page together, followed by the two sentences.

- [ ] **Step 4: Fixture `widow-table.md`** — filler + a 5-row table that would otherwise leave 1–2 rows at the bottom. After pagination the table starts at the top of a page. A second table in the same fixture with 20 rows must still **split** (no full-table push).

- [ ] **Step 4b: Fixture `para-gap.md`.** Two consecutive 5-line paragraphs must show a visible gap (bbox y-gap ≥ one line). A 2-line paragraph immediately followed by a 5-line paragraph must stay tight (gap &lt; 0.4 line). Run once with `--no-paginate` (proves the gap is stage 11, not a spacer) and once with pagination (spacers must not eat the gap). Re-export file 04 §4.2: Keep / Noise separated; a short intro against Keep stays compact.

- [ ] **Step 5: Re-export file 01.** Page 2 must not end on `3. PER-SOURCE ROWS`. Page 15 must not end on `18. CROSSWALK…` plus a single line; the crosswalk heading and its table start together on the next page.

- [ ] **Step 6: Confirm issue 5 still holds** on the security PDF (pagination must not re-introduce blank pages). If it does, either explode (stage 4) was skipped or a push targeted a box taller than a page; fix before closing the task. Do **not** “fix” it by running pagination earlier.

- [ ] **Step 7: If file 01 still orphans** after 8 passes, add the `pdftotext -bbox` verification pass described in Locked design (same `<br>` inserter, PDF coordinates as SoT). Do not add this pass unless the DOM model fails on file 01.

- [ ] **Step 8: Commit** (when asked)

---

### Task 7: Preview, exporter comments, and regression command

**Files:**

- Modify: `asc/doc/html_preview.sh` (still `render_html()`; stages 1–9 and 11; **no** `apply_print_pushes`)
- Modify: `asc/doc/pdf_export.sh` (header: paste the 13-stage list)
- Modify: `asc/doc/md2pdf_asc.py` (module docstring: same 13-stage list)

- [ ] **Step 1: `html_preview.sh` on `katex-delimiters.md` and `mermaid-dense.md`** — grep the HTML for `asc-math-display`, `code-line`, `ascLayoutBoot`, and the new mermaid `fontSize: 13`. Must contain `await ascRunMermaid` before `await ascRunKatex`. Must **not** contain `apply_print_pushes` / `asc-print-push` insertion.

- [ ] **Step 2: Document the regression set** in `pdf_export.sh`:

```text
# Visual / text regression (after --force):
#   .../01-harness-doctrine-hooks-tools-skills-mcp.md
#   .../05-routing-cascading-local-inference-modest-hardware.md
#   .../07-injection-redaction-anonymization-at-the-llm-boundary.md
#   .../02-debian-13-workstation-and-lan-inference-box-systemd-jobs-local-models-sync.md
#   .../10-synthesis-v6-delta-strategy-and-staged-roadmap.md
#   .../04-security-and-privacy-operations-secrets-keys-container-hardening-supply-chain-gdpr-lgpd.md
```

- [ ] **Step 3: Run `asc/doc/asc/pdf.test.sh` in full** (unit + fixture exports if Playwright browsers are present; skip Playwright tests with a message if `PLAYWRIGHT_BROWSERS_PATH` is empty).

- [ ] **Step 4: Commit** (when asked)

---

## Acceptance (the five reports)

| # | File | Pass when |
|---|------|-----------|
| 1 | `01-…mcp.pdf` | `3. Per-source rows` is not the last line of a page; at least 4 lines of §3 (or the whole remaining section) follow it on that page. Same for `18. Crosswalk` and its table. |
| 2 | same + other tables | No table begins with 1–2 short rows at the bottom if the full table fits on the next page. Tall tables still split. |
| 3 | `05-…hardware.pdf` p.18–20 | No raw `(\hat p(\ell))` in body or tables; no `p^{0}{T1}` wreckage; Beta formula is a normal display, not a blank band. |
| 4 | `07` house, `02` WoL state, `10` gantt, `05` router flowchart | House/gantt/state readable; router flowchart not regressed. |
| 5 | `04-…gdpr-lgpd.pdf` §3.1 | No blank page before `compose.worker.yml`; fence continues across pages like body text. |

---

## Safety / locks

- Nextcloud paths are inputs to `pdf_export.sh`, not files to rewrite.
- Footer page numbers stay; spacers must not cover them (bottom margin 1.0 cm unchanged).
- `securityLevel: 'loose'` stays (needed for `<br>` inside Mermaid node labels). Do not widen it.
- Pagination can add passes (up to 8 PDF layouts). On a 30-page review that is still seconds, not minutes; if a pass inserts 0 spacers, stop.
- Do not enable `page-break-inside: avoid` on `pre` or on tables taller than one page.
- After `apply_print_pushes`, do not re-run Mermaid, KaTeX, explode, or paragraph marking. `--no-paginate` skips only that call.

---

## Spec coverage (self-review)

| Requirement | Task |
|-------------|------|
| Heading near bottom, &lt; 4 following body lines → `<br>` until top of next page | 1, 6 |
| Stacked `h2`+`h3` (no body between) move as one cluster; spacer never sits between them | 1, 6 |
| Extra passes after a cluster push (knock-on orphans earlier on the page) | 6 |
| Table widow &lt; 3 rows and ≤ 4 line-equivalents → same `<br>` push | 1, 6 |
| KaTeX failures (file 05 p.20 and elsewhere) | 3, 4 |
| Mermaid overlap / tiny type / floating text / gantt | 5 |
| Meaning-preserving layout retries (`LR`↔`TD`, wrap, spacing); original on a tie | 5 |
| Long code blank pages / split like paragraphs | 2 |
| Gap only between two `<p>` that each have ≥ 3 rendered lines; short paras stay tight | 6 (stage 11, before pagination) |
| Post-process immediately before writing the PDF | 6 (stage 12 last, then `page.pdf`) |
| Fixed pipeline; orphan/widow pagination last; no layout mutation after spacers | Locked design § pipeline order; Task 6 Step 0; Task 7 docstring |

No placeholders left: delimiter lists, CSS, JS loop, constants, fixture names, verification commands, and **pipeline stage order** are specified.
