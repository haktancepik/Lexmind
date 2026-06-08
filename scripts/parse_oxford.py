#!/usr/bin/env python3
"""
American_Oxford_5000.pdf -> oxford5000_starter.json

Outputs one entry per (term, partOfSpeech, level) row from the PDF.
The PDF actually contains the Oxford 5000 *minus* the Oxford 3000, so the
result is ~1988 B2/C1 entries. Some terms appear with multiple POS+levels.

The starter JSON feeds enrich_oxford.py to be expanded with definitions,
Turkish meanings, examples and topics via Anthropic's batch API.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PDF = ROOT / "American_Oxford_5000.pdf"
OUT = Path(__file__).resolve().parent / "oxford5000_starter.json"

# Extracts the text via Swift PDFKit so the script does not require poppler.
PDF_EXTRACT_SWIFT = r"""
import Foundation
import PDFKit
let url = URL(fileURLWithPath: CommandLine.arguments[1])
guard let doc = PDFDocument(url: url) else { exit(1) }
for i in 0..<doc.pageCount {
    if let p = doc.page(at: i), let s = p.string { print(s) }
}
"""

POS_MAP = {
    "v.": "verb",
    "n.": "noun",
    "adj.": "adjective",
    "adv.": "adverb",
    "prep.": "preposition",
    "pron.": "pronoun",
    "conj.": "conjunction",
    "det.": "determiner",
    "exclam.": "exclamation",
    "abbr.": "abbreviation",
    "number": "number",
    "modal": "modal verb",
    "auxiliary": "auxiliary verb",
}

LEVEL_RE = re.compile(r"\b(A1|A2|B1|B2|C1|C2)\b")
ENTRY_RE = re.compile(
    r"^(?P<term>[a-zA-Z][a-zA-Z'\- ]*?)\s+"
    r"(?P<rest>(?:v|n|adj|adv|prep|pron|conj|det|exclam|abbr)\.\s*"
    r"(?:[A-C][12])(?:\s*,\s*(?:v|n|adj|adv|prep|pron|conj|det|exclam|abbr)\.\s*[A-C][12])*)"
    r"\s*$"
)


def extract_pdf_text(pdf_path: Path) -> str:
    swift_file = Path("/tmp/_extract_pdf_for_oxford.swift")
    swift_file.write_text(PDF_EXTRACT_SWIFT)
    res = subprocess.run(
        ["swift", str(swift_file), str(pdf_path)],
        capture_output=True, text=True, check=True,
    )
    return res.stdout


def parse_lines(text: str) -> list[dict]:
    entries: list[dict] = []
    seen: set[tuple[str, str, str]] = set()
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("©") or "Oxford 5000" in line:
            continue
        m = ENTRY_RE.match(line)
        if not m:
            # fall back: split "term ... pos. LEVEL[, pos. LEVEL]"
            level_match = LEVEL_RE.search(line)
            if not level_match:
                continue
            # try lax parsing
            head, _, tail = line.partition(" ")
            term = head.strip().lower()
            rest = tail.strip()
        else:
            term = m["term"].strip().lower()
            rest = m["rest"].strip()

        # Some terms have a trailing digit like "bass1" — drop it.
        term = re.sub(r"\d+$", "", term)

        # rest looks like "v. C1" or "n. B2, adj. C1"
        for piece in rest.split(","):
            piece = piece.strip()
            if not piece:
                continue
            mm = re.match(r"(?P<pos>[a-z]+)\.\s*(?P<lvl>[A-C][12])", piece)
            if not mm:
                continue
            pos_raw = mm["pos"] + "."
            level = mm["lvl"]
            pos = POS_MAP.get(pos_raw, pos_raw.rstrip("."))
            key = (term, pos, level)
            if key in seen:
                continue
            seen.add(key)
            entries.append({"term": term, "partOfSpeech": pos, "level": level})
    return entries


def main() -> int:
    if not PDF.exists():
        sys.stderr.write(f"PDF not found: {PDF}\n")
        return 1
    text = extract_pdf_text(PDF)
    entries = parse_lines(text)
    OUT.write_text(json.dumps(entries, ensure_ascii=False, indent=2))
    # Quick summary
    levels: dict[str, int] = {}
    for e in entries:
        levels[e["level"]] = levels.get(e["level"], 0) + 1
    terms = {e["term"] for e in entries}
    print(f"wrote {len(entries)} entries ({len(terms)} unique terms) -> {OUT}")
    print("by level:", levels)
    return 0


if __name__ == "__main__":
    sys.exit(main())
