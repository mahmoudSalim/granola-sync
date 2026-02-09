"""Tests for utils module."""

import os
import tempfile

from granola_sync.utils import safe_filename, unique_filename


def test_safe_filename_removes_bad_chars():
    assert safe_filename('Meeting: "Q1 Review" | 2026') == "Meeting Q1 Review 2026"


def test_safe_filename_collapses_whitespace():
    assert safe_filename("Too   many   spaces") == "Too many spaces"


def test_safe_filename_truncates():
    long_name = "A" * 200
    assert len(safe_filename(long_name)) == 80


def test_safe_filename_empty():
    assert safe_filename("") == "Untitled"
    assert safe_filename(":::") == "Untitled"


def test_unique_filename_no_conflict():
    with tempfile.TemporaryDirectory() as d:
        result = unique_filename(d, "test", ".docx")
        assert result == "test.docx"


def test_unique_filename_with_conflict():
    with tempfile.TemporaryDirectory() as d:
        open(os.path.join(d, "test.docx"), "w").close()
        result = unique_filename(d, "test", ".docx")
        assert result == "test (2).docx"


def test_unique_filename_multiple_conflicts():
    with tempfile.TemporaryDirectory() as d:
        open(os.path.join(d, "test.docx"), "w").close()
        open(os.path.join(d, "test (2).docx"), "w").close()
        result = unique_filename(d, "test", ".docx")
        assert result == "test (3).docx"
