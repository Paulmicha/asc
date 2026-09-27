---
description: Every rule contained in the $PROJECT_DOCROOT .editorconfig file must be honored.
globs: '*.*'
---

The ASC mother repo contains the shared rules applied across ASC project instances.

Here are the current defaults :

```ini
# Editor configuration normalization.
# @see http://editorconfig.org/

# This is the top-most .editorconfig file; do not search in parent directories.
root = true

# All files.
[*]
end_of_line = LF
indent_style = space
indent_size = 2
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[composer.json]
indent_size = 4

[*.{md,markdown}]
trim_trailing_whitespace = false

[{Makefile,*.mk}]
indent_style = tab
```

# Anti-pattern example (don't)

- Trim trailing whitespaces in markdown files
- Leave trailing whitespaces in other files
- Indent 4 spaces in Python or shell scripts
- Indent using spaces in makefiles
- Leave any file without an empty line as the last line

# Correct example (do)

- respect the rules expressed in `.editorconfig`
