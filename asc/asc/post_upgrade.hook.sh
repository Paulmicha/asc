#!/usr/bin/env bash

. asc/instance/reinit.sh

# Skip auto-commit only when paths outside asc/ are unclean. Dirty asc/ files
# are expected after an upgrade and should still be committed.
non_asc_unclean="$(
  git status --porcelain \
    | while IFS= read -r line; do
        path="${line:3}"
        if [[ "$path" == *' -> '* ]]; then
          path="${path##* -> }"
        fi
        path="${path#\"}"
        path="${path%\"}"
        case "$path" in
          asc|asc/*) ;;
          *) echo "$path" ;;
        esac
      done
)"

if [[ -n "$non_asc_unclean" ]]; then
  echo "Git work tree has unclean files outside asc/ -> skipped auto-commit."
elif [ -z "$(git status --porcelain)" ]; then
  echo "Git work tree is clean -> nothing to auto-commit."
else
  echo "Only asc/ files are unclean -> auto-commit ..."

  git add asc
  git commit -m "chore: update ASC core from upstream repo"
  git push

  echo "Only asc/ files are unclean -> auto-commit : done."
fi
