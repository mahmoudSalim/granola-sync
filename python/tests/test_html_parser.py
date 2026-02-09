"""Tests for HTML parser module."""

from granola_sync.html_parser import parse_html_to_elements


def test_simple_paragraph():
    elements = parse_html_to_elements("<p>Hello world</p>")
    assert elements == [("paragraph", "Hello world", 0)]


def test_heading():
    elements = parse_html_to_elements("<h2>My Heading</h2>")
    assert elements == [("heading", "My Heading", 2)]


def test_nested_list():
    html = "<ul><li>Item 1</li><li>Item 2</li></ul>"
    elements = parse_html_to_elements(html)
    assert len(elements) == 2
    assert elements[0] == ("bullet", "Item 1", 1)
    assert elements[1] == ("bullet", "Item 2", 1)


def test_nested_list_depth():
    html = "<ul><li>Outer</li><ul><li>Inner</li></ul></ul>"
    elements = parse_html_to_elements(html)
    depths = [e[2] for e in elements if e[0] == "bullet"]
    assert depths == [1, 2]


def test_skips_chat_link():
    html = "<p>Chat with meeting transcript</p>"
    elements = parse_html_to_elements(html)
    assert elements == []


def test_mixed_content():
    html = "<h2>Summary</h2><p>Overview text</p><ul><li>Point 1</li></ul>"
    elements = parse_html_to_elements(html)
    assert len(elements) == 3
    assert elements[0][0] == "heading"
    assert elements[1][0] == "paragraph"
    assert elements[2][0] == "bullet"


def test_empty_html():
    assert parse_html_to_elements("") == []
    assert parse_html_to_elements("<p></p>") == []
