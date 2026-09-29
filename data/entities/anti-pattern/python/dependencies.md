---
description: Python scripting cannot approach dependencies the same way. The purpose of using Python determines which applies. This anti-pattern entry aims at avoiding wrong choices of tools like pipx and uv.
globs: '*.py'
---

The consensus is governed by [PEP 668](https://peps.python.org/pep-0668). Debian marks the system-wide Python interpreter as an externally managed environment, completely blocking traditional global installations via pip install to protect essential system packages from breaking. The recommendations to follow are :

- For Command-Line Tools & Applications: use `pipx`. Typical use cases : install a finished application distributed via PyPI that you intend to use primarily from the terminal (e.g. black, yt-dlp).
- For Python Development & Projects: use `uv`. Typical use cases : writing your own code or deploying a microservice/application (like Django or Flask). Create a standard, localized virtual environment per subject.

# Anti-pattern example (don't)

## Host-level (global) dependencies

```sh
pip install black
```

## Custom script(s) (local) dependencies

Do not run uv python pin --global. That would change the default for every uv project on the machine.

```sh
python path/to/subject/script.py
```

# Correct example (do)

## Host-level (global) dependencies

```sh
pipx install black
```

## Custom script(s) (local) dependencies

The first uv add or uv run downloads CPython 3.12 under `~/.local/share/uv/python/` and creates `.venv` there. `uv run` uses that venv, so *you do not activate it* and you do *not* call `python3`.

```sh
uv init --app --python 3.12 --vcs none --no-readme path/to/subject
uv add --project path/to/subject faster-whisper
uv run python path/to/subject/script.py
```

It is also possible to reuse the same venv as any installed `pipx` dependency :

```sh
~/.local/share/pipx/venvs/foobar/bin/python path/to/custom/script.py
```
