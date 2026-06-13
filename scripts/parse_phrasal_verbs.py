#!/usr/bin/env python3
"""
phrasal-verbs-detayli-anlamlari-tablosu.pdf (AKIN, ~220 entries with full
    Turkish meaning + English definition + example sentences)
1522587882-283621.pdf (YDS, 149 numbered entries with Turkish meaning only)
    -> Lexmind/Lexmind/Resources/phrasalverbs.json

Schema matches OxfordWordsLibrary's OxfordWordEntry decoder so the loader can
be a near-clone. Default level B2, topic [general], partOfSpeech "phrasal
verb". Entries from PDF1 supply definition + examples; PDF2-only entries get
empty definition/examples (the in-app lazy enrichment will fill them later).
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PDF_AKIN = ROOT / "phrasal-verbs-detayli-anlamlari-tablosu.pdf"
PDF_YDS = ROOT / "1522587882-283621.pdf"
OUT = ROOT / "Lexmind" / "Resources" / "phrasalverbs.json"

PDF_EXTRACT_SWIFT = r"""
import Foundation
import PDFKit
let url = URL(fileURLWithPath: CommandLine.arguments[1])
guard let doc = PDFDocument(url: url) else { exit(1) }
for i in 0..<doc.pageCount {
    if let p = doc.page(at: i), let s = p.string { print(s) }
}
"""

# Lines that are page headers/footers (PDF1 + PDF2) and must be discarded.
NOISE_SUBSTRINGS = (
    "YDS.NET ONLINE DERSLER",
    "AKIN DİL EĞİTİM MERKEZİ",
    "Atatürk Bulvarı",
    "WWW.AKINDIL.COM",
    "PHRASAL VERBS ve ANLAMLARI TABLOSU",
    "ÖNEMLİ PHRASAL VERBS",
    "İngilizce Türkçe Tür",
    "Bu dosyada sık kullanılan",
    "kitaplarımızı kullanmanızı",
    "Bu liste YDS için",
    "Bu doküman, YDS",
    "Toplam 149 adet",
    "P. Verb 149 adet",
    "bir listedir",
)

# Particles & known multi-word constituents that may follow the head verb in
# a phrasal verb (used to detect where the English term ends and the Turkish
# meaning begins).
PARTICLES = {
    "in", "out", "up", "down", "on", "off", "for", "to", "with", "into",
    "onto", "over", "under", "away", "back", "by", "from", "of", "across",
    "after", "around", "behind", "forward", "through", "together", "upon",
    "about", "ahead", "along", "apart", "aside", "between", "throughout",
    # Non-particle constituents that appear inside common phrasal verbs.
    "rise", "place", "care", "do", "fed", "track", "ward",
}


def extract_pdf_text(pdf_path: Path) -> str:
    swift_file = Path("/tmp/_extract_pdf_for_phrasal.swift")
    swift_file.write_text(PDF_EXTRACT_SWIFT)
    res = subprocess.run(
        ["swift", str(swift_file), str(pdf_path)],
        capture_output=True, text=True, check=True,
    )
    return res.stdout


def is_noise(line: str) -> bool:
    return any(sub in line for sub in NOISE_SUBSTRINGS)


def clean_lines(text: str) -> list[str]:
    out = []
    for raw in text.splitlines():
        s = raw.strip()
        if not s:
            continue
        if is_noise(s):
            continue
        out.append(s)
    return out


def split_term_and_rest(text: str) -> tuple[str, str]:
    """Walk word-by-word: the first word is the verb, then consume known
    particles; the remainder is Turkish content."""
    words = text.split()
    if not words:
        return "", ""
    term_words = [words[0]]
    i = 1
    while i < len(words):
        w = words[i].lower().rstrip(".,;:")
        if w in PARTICLES:
            term_words.append(words[i])
            i += 1
            if len(term_words) >= 4:  # cap to avoid runaway
                break
        else:
            break
    return " ".join(term_words).strip(), " ".join(words[i:]).strip()


# ---------------------------------------------------------------------------
# PDF 2 (YDS, numbered)
# ---------------------------------------------------------------------------

NUM_RE = re.compile(r"^(\d+)\.\s*(.*)$")


def parse_yds(text: str) -> dict[str, dict]:
    lines = clean_lines(text)
    # Pre-collect numbered entry indices
    starts: list[tuple[int, int, str]] = []  # (line_idx, num, head)
    for i, ln in enumerate(lines):
        m = NUM_RE.match(ln)
        if m:
            starts.append((i, int(m.group(1)), m.group(2)))

    entries: dict[str, dict] = {}
    for idx, (start_i, num, head) in enumerate(starts):
        end_i = starts[idx + 1][0] if idx + 1 < len(starts) else len(lines)
        block = [head] if head else []
        for j in range(start_i + 1, end_i):
            ln = lines[j]
            if ln == "Eş Anlamlılar":
                break
            block.append(ln)
        # Combine, drop "P. Verb" markers
        raw = " ".join(block)
        raw = re.sub(r"\bP\.\s*Verb\b", " ", raw)
        raw = re.sub(r"\s+", " ", raw).strip()
        if not raw:
            continue
        term, turkish = split_term_and_rest(raw)
        if not term:
            continue
        term = term.lower()
        # Normalize Turkish: clean commas/repeated whitespace
        turkish = re.sub(r"\s+", " ", turkish).strip().rstrip(",")
        key = term
        if key in entries:
            existing = entries[key]["turkishMeaning"]
            if turkish and turkish not in existing:
                entries[key]["turkishMeaning"] = (
                    f"{existing}; {turkish}" if existing else turkish
                )
        else:
            entries[key] = {
                "term": term,
                "partOfSpeech": "phrasal verb",
                "ipa": "",
                "countability": "N/A",
                "definition": "",
                "turkishMeaning": turkish,
                "examples": [],
                "level": "B2",
                "topics": ["general"],
            }
    return entries


# ---------------------------------------------------------------------------
# PDF 1 (AKIN, four-column table — best-effort)
# ---------------------------------------------------------------------------

# A term head in PDF1: line whose first token is Title-Case English word and
# subsequent tokens are lowercase English (or "(oneself)").
HEAD_TOKEN_RE = re.compile(r"^[A-Z][a-z]+$")
LC_TOKEN_RE = re.compile(r"^(?:[a-z]+|\([a-z]+\))$")
HAS_TURKISH_CHAR = re.compile(r"[çğıöşüÇĞİÖŞÜâî]")


def looks_like_pdf1_head(line: str) -> tuple[str, str] | None:
    """Return (term, remainder_after_term) if the line begins with a phrasal
    verb head followed by Turkish content; else None."""
    words = line.split()
    if not words or not HEAD_TOKEN_RE.match(words[0]):
        return None
    term_words = [words[0]]
    i = 1
    while i < len(words):
        w = words[i]
        if w == "(oneself)":
            term_words.append(w)
            i += 1
            continue
        if LC_TOKEN_RE.match(w) and w.lower() in PARTICLES:
            term_words.append(w)
            i += 1
            if len(term_words) >= 4:
                break
        else:
            break
    # Require at least one particle/extra (phrasal verbs have >=2 tokens) and
    # the next token must look like Turkish (lowercase, ideally Turkish chars
    # or non-particle).
    if len(term_words) < 2:
        return None
    remainder = " ".join(words[i:])
    return " ".join(term_words), remainder


def parse_akin(text: str) -> dict[str, dict]:
    lines = clean_lines(text)
    # Identify term-head lines first.
    head_positions: list[tuple[int, str, str]] = []  # (idx, term, remainder)
    for i, ln in enumerate(lines):
        h = looks_like_pdf1_head(ln)
        if h is not None:
            term, remainder = h
            head_positions.append((i, term, remainder))

    entries: dict[str, dict] = {}
    for idx, (start_i, term, head_remainder) in enumerate(head_positions):
        end_i = (
            head_positions[idx + 1][0]
            if idx + 1 < len(head_positions)
            else len(lines)
        )
        block: list[str] = []
        if head_remainder:
            block.append(head_remainder)
        for j in range(start_i + 1, end_i):
            block.append(lines[j])

        # Classify each line: Turkish vs English vs Example
        turkish_lines: list[str] = []
        english_lines: list[str] = []
        example_lines: list[str] = []
        for ln in block:
            ln_stripped = ln.strip()
            if not ln_stripped:
                continue
            # Examples: usually contain sentence pronouns and end with .,!,?
            # Heuristic: starts with capital and ends with sentence terminator
            # AND contains the phrasal verb root in lowercase.
            head_verb = term.split()[0].lower()
            looks_like_example = (
                ln_stripped[0].isupper()
                and ln_stripped[-1] in ".!?"
                and (head_verb in ln_stripped.lower()
                     or any(p in ln_stripped.lower()
                            for p in term.lower().split()))
            )
            if looks_like_example:
                example_lines.append(ln_stripped)
                continue
            # English vs Turkish classification
            if HAS_TURKISH_CHAR.search(ln_stripped):
                turkish_lines.append(ln_stripped)
            elif ln_stripped[0].isupper():
                english_lines.append(ln_stripped)
            else:
                # lowercase line with no Turkish chars — likely Turkish or
                # English-defn continuation. Prefer Turkish (more reliable).
                turkish_lines.append(ln_stripped)

        # Merge multi-line Turkish meaning (drop trailing punctuation
        # between continuations).
        turkish = " ".join(turkish_lines).strip()
        turkish = re.sub(r"\s+", " ", turkish).strip().rstrip(",")
        definition = " ".join(english_lines).strip()
        definition = re.sub(r"\s+", " ", definition).strip()
        examples_combined: list[str] = []
        # Heuristic: split joined sentences in example_lines if they were
        # concatenated.
        joined_examples = " ".join(example_lines)
        if joined_examples:
            split = re.split(r"(?<=[.!?])\s+(?=[A-Z])", joined_examples)
            examples_combined = [s.strip() for s in split if s.strip()]

        key = term.lower()
        entry = {
            "term": key,
            "partOfSpeech": "phrasal verb",
            "ipa": "",
            "countability": "N/A",
            "definition": definition,
            "turkishMeaning": turkish,
            "examples": examples_combined,
            "level": "B2",
            "topics": ["general"],
        }
        if key in entries:
            # Merge — prefer non-empty fields
            existing = entries[key]
            if not existing["definition"] and definition:
                existing["definition"] = definition
            if turkish and turkish not in existing["turkishMeaning"]:
                existing["turkishMeaning"] = (
                    f"{existing['turkishMeaning']}; {turkish}"
                    if existing["turkishMeaning"]
                    else turkish
                )
            existing["examples"].extend(
                e for e in examples_combined if e not in existing["examples"]
            )
        else:
            entries[key] = entry
    return entries


# ---------------------------------------------------------------------------
# Merge & write
# ---------------------------------------------------------------------------


def merge(akin: dict, yds: dict) -> list[dict]:
    """AKIN entries are richer → keep them as base. For overlapping keys,
    fold the YDS Turkish meaning into the AKIN entry. For YDS-only keys,
    add them as-is."""
    out: dict[str, dict] = {}
    for k, v in akin.items():
        out[k] = dict(v)
    overlap = 0
    yds_only = 0
    for k, v in yds.items():
        if k in out:
            overlap += 1
            existing_turkish = out[k]["turkishMeaning"]
            yds_turkish = v["turkishMeaning"]
            if yds_turkish and yds_turkish.lower() not in existing_turkish.lower():
                out[k]["turkishMeaning"] = (
                    f"{existing_turkish}; {yds_turkish}"
                    if existing_turkish
                    else yds_turkish
                )
        else:
            yds_only += 1
            out[k] = dict(v)
    # Sort: alphabetic
    sorted_entries = [out[k] for k in sorted(out.keys())]
    return sorted_entries, overlap, yds_only


def main() -> int:
    if not PDF_AKIN.exists():
        sys.stderr.write(f"PDF not found: {PDF_AKIN}\n")
        return 1
    if not PDF_YDS.exists():
        sys.stderr.write(f"PDF not found: {PDF_YDS}\n")
        return 1

    print(f"Reading {PDF_AKIN.name}...")
    akin_text = extract_pdf_text(PDF_AKIN)
    akin = parse_akin(akin_text)
    print(f"  AKIN parsed: {len(akin)} unique entries")

    print(f"Reading {PDF_YDS.name}...")
    yds_text = extract_pdf_text(PDF_YDS)
    yds = parse_yds(yds_text)
    print(f"  YDS parsed: {len(yds)} unique entries")

    merged, overlap, yds_only = merge(akin, yds)
    print(f"Merged: {len(merged)} total "
          f"(AKIN-only: {len(akin) - overlap}, "
          f"overlap: {overlap}, YDS-only: {yds_only})")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(merged, ensure_ascii=False, indent=2))
    print(f"Wrote {OUT}")

    missing_turkish = sum(1 for e in merged if not e["turkishMeaning"])
    missing_def = sum(1 for e in merged if not e["definition"])
    missing_ex = sum(1 for e in merged if not e["examples"])
    print(f"Quality:")
    print(f"  missing turkishMeaning: {missing_turkish}")
    print(f"  missing definition:     {missing_def}")
    print(f"  missing examples:       {missing_ex}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
