# Append file paths without resetting the caller array

| Field | Value |
|-------|--------|
| **Date** | 2026-09-25 |
| **Status** | **done** |
| **Scope** | `f_fs_file_list_append` next to `f_fs_file_list` in `asc/core/utils/fs.manual-inc.sh`. |

`$` in this file is the ASC docs placeholder, not a shell variable.

---

`f_fs_file_list` clears `file_list` and `file_list_arr` on every call. A second pattern replaces the first. Depth greater than 1 fills only the newline string.

`f_fs_file_list_append` takes the same arguments. The caller clears `file_list_arr` once. Each call appends one element per matching path and leaves `file_list` alone. Depth 1 uses bash globbing. A greater depth uses `find -printf '%P\0'` so a path may contain spaces.

`f_fs_file_list` still replaces both variables. Callers that expect a fresh list stay on that function.
