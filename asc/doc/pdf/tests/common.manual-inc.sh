#!/usr/bin/env bash

##
# Shared setup for asc/doc/pdf/tests/*.test.sh (PYTHONPATH, PDF_PY, suite filter).
#
# Sourced after asc/bootstrap.sh by each suite file.
#

export PYTHONPATH="asc/doc/md:asc/doc/pdf:asc/doc/formula:asc/doc/diagram:asc/doc/graph${PYTHONPATH:+:$PYTHONPATH}"

PDF_PY=''
if command -v md2pdf >/dev/null 2>&1; then
  for candidate in \
    "$(dirname "$(command -v md2pdf)")/python" \
    "$(dirname "$(command -v md2pdf)")/python3"; do
    if [ -x "$candidate" ]; then
      PDF_PY="$candidate"
      break
    fi
  done
fi
if [ -z "$PDF_PY" ] &&
  [ -x "$HOME/.local/share/pipx/venvs/md2pdf-mermaid/bin/python" ]; then
  PDF_PY="$HOME/.local/share/pipx/venvs/md2pdf-mermaid/bin/python"
fi
PDF_PY="${PDF_PY:-$(command -v python3)}"

##
# Optional PDF_TEST_FILTER=test_a test_b — unknown names exit non-zero.
#
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
