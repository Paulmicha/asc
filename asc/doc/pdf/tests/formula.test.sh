#!/usr/bin/env bash

##
# ASC doc-pdf formula / KaTeX tests.
#
# @requires asc/vendor/shunit2
# @see asc/doc/pdf.sh
# @see asc/doc/md/md2pdf_asc.py
#
# @example
#   asc/doc/pdf/tests/formula.test.sh
#   PDF_TEST_FILTER=test_name asc/doc/pdf/tests/formula.test.sh
#

. asc/bootstrap.sh
. asc/doc/pdf/tests/common.manual-inc.sh

test_protect_katex_delimiters() {
  "$PDF_PY" - <<'PY'
from katex import protect_katex_math, restore_katex_math, html_has_katex

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
print("ok")
PY
  assertEquals 'katex protect Python assertions failed' 0 $?
}

. asc/vendor/shunit2/shunit2
