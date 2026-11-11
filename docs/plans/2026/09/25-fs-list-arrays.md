# File and directory lists share one array walk

| Field | Value |
|-------|--------|
| **Date** | 2026-09-25 |
| **Status** | **done** |
| **Scope** | `f_fs_list_append`, `f_fs_dir_list`, `f_fs_file_list`, `f_fs_file_list_append`, and their callers. |

`$` in this file is the ASC docs placeholder, not a shell variable.

---

`dir_list` and `file_list` were newline strings. Callers split them on spaces. A depth greater than 1 stored `find` output in that string.

`f_fs_list_append` is the only walk. Depth 1 globs in-process. A greater depth uses `find -printf '%P\0'` and `mapfile`. `f_fs_dir_list` replaces `dir_list_arr`. `f_fs_file_list` clears `file_list_arr` and calls `f_fs_file_list_append`. Callers loop the array. Two file patterns append. A directory result that must survive the next listing is copied first.
