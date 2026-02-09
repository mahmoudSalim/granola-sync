"""Parse Granola's HTML summaries into structured elements for docx generation."""

from html.parser import HTMLParser


class HTMLToDocxElements(HTMLParser):
    """Parse Granola's HTML summary into structured elements for docx."""

    def __init__(self):
        super().__init__()
        self.elements: list[tuple[str, str, int]] = []
        self._list_depth = 0
        self._current_text = ""
        self._current_tag: str | None = None

    def handle_starttag(self, tag, attrs):
        if tag in ("h1", "h2", "h3", "h4", "h5"):
            self._flush()
            self._current_tag = tag
        elif tag == "ul":
            self._flush()
            self._list_depth += 1
        elif tag == "li":
            self._flush()
            self._current_tag = "li"
        elif tag == "p":
            self._flush()
            self._current_tag = "p"
        elif tag == "br":
            self._current_text += "\n"

    def handle_endtag(self, tag):
        if tag in ("h1", "h2", "h3", "h4", "h5"):
            self._flush()
        elif tag == "ul":
            self._flush()
            self._list_depth = max(0, self._list_depth - 1)
        elif tag == "li":
            self._flush()
        elif tag == "p":
            self._flush()

    def handle_data(self, data):
        self._current_text += data

    def _flush(self):
        text = self._current_text.strip()
        if not text:
            self._current_text = ""
            self._current_tag = None
            return
        if text.startswith("Chat with meeting transcript"):
            self._current_text = ""
            self._current_tag = None
            return
        if self._current_tag in ("h1", "h2", "h3", "h4", "h5"):
            self.elements.append(("heading", text, int(self._current_tag[1])))
        elif self._current_tag == "li":
            self.elements.append(("bullet", text, self._list_depth))
        else:
            self.elements.append(("paragraph", text, 0))
        self._current_text = ""
        self._current_tag = None


def parse_html_to_elements(html_str: str) -> list[tuple[str, str, int]]:
    parser = HTMLToDocxElements()
    parser.feed(html_str)
    parser._flush()
    return parser.elements
