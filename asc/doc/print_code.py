"""Prepare fenced code blocks for Chromium print pagination."""

from __future__ import annotations

import re
from html.parser import HTMLParser


def _classes(attrs: list[tuple[str, str | None]]) -> set[str]:
    for name, value in attrs:
        if name.lower() == "class" and value:
            return set(value.split())
    return set()


class _CodeLineExploder(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=False)
        self.output: list[str] = []
        self.elements: list[set[str]] = []
        self.in_pre = False
        self.skip_pre = False
        self.line_open = False
        self.inline_tags: list[tuple[str, str]] = []
        self.container_tags: list[str] = []

    def _write_start_tag(self, tag: str) -> str:
        source = self.get_starttag_text() or f"<{tag}>"
        self.output.append(source)
        return source

    def _open_line(self) -> None:
        if self.line_open:
            return
        self.output.append('<span class="code-line">')
        self.line_open = True
        for _tag, source in self.inline_tags:
            self.output.append(source)

    def _close_line(self) -> None:
        if not self.line_open:
            return
        for tag, _source in reversed(self.inline_tags):
            self.output.append(f"</{tag}>")
        self.output.append("</span>")
        self.line_open = False

    def handle_starttag(
        self, tag: str, attrs: list[tuple[str, str | None]]
    ) -> None:
        classes = _classes(attrs)
        ancestor_is_mermaid = any("mermaid-wrap" in item for item in self.elements)
        self.elements.append(classes)

        if not self.in_pre and tag.lower() == "pre":
            self.in_pre = True
            self.skip_pre = "mermaid" in classes or ancestor_is_mermaid
            self._write_start_tag(tag)
            return

        if not self.in_pre or self.skip_pre:
            self._write_start_tag(tag)
            return

        if tag.lower() in {"code", "samp"} and not self.line_open:
            self.container_tags.append(tag)
            self._write_start_tag(tag)
            return

        self._open_line()
        source = self._write_start_tag(tag)
        self.inline_tags.append((tag, source))

    def handle_startendtag(
        self, tag: str, attrs: list[tuple[str, str | None]]
    ) -> None:
        if self.in_pre and not self.skip_pre:
            self._open_line()
        self._write_start_tag(tag)

    def handle_endtag(self, tag: str) -> None:
        if self.in_pre and tag.lower() == "pre":
            self._close_line()
            self.output.append(f"</{tag}>")
            self.in_pre = False
            self.skip_pre = False
            self.container_tags.clear()
            self.inline_tags.clear()
            if self.elements:
                self.elements.pop()
            return

        if not self.in_pre or self.skip_pre:
            self.output.append(f"</{tag}>")
        elif self.container_tags and tag == self.container_tags[-1]:
            self._close_line()
            self.container_tags.pop()
            self.output.append(f"</{tag}>")
        else:
            self.output.append(f"</{tag}>")
            if self.inline_tags and tag == self.inline_tags[-1][0]:
                self.inline_tags.pop()
        if self.elements:
            self.elements.pop()

    def handle_data(self, data: str) -> None:
        if not self.in_pre or self.skip_pre:
            self.output.append(data)
            return
        parts = data.split("\n")
        for index, part in enumerate(parts):
            self._open_line()
            self.output.append(part)
            if index < len(parts) - 1:
                self._close_line()

    def handle_entityref(self, name: str) -> None:
        self.handle_data(f"&{name};")

    def handle_charref(self, name: str) -> None:
        self.handle_data(f"&#{name};")

    def handle_comment(self, data: str) -> None:
        if self.in_pre and not self.skip_pre:
            self._open_line()
        self.output.append(f"<!--{data}-->")

    def handle_decl(self, decl: str) -> None:
        self.output.append(f"<!{decl}>")


def explode_pre_code_lines(html: str) -> str:
    """Wrap each non-Mermaid ``pre`` line in a printable block span."""
    parser = _CodeLineExploder()
    parser.feed(html)
    parser.close()
    out = "".join(parser.output)
    return re.sub(
        r'(?:<span class="code-line"></span>\n?)+</code>',
        "</code>",
        out,
    )
