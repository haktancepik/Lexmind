#!/usr/bin/env python3
"""
export_common_to_json.py

Parses CommonWordsLibrary.swift's static `all: [CommonWord]` literal array
and emits a JSON file with the same schema as oxford5000.json (no family /
relations yet — those are added later by enrich_full.py).

Usage:
    python scripts/export_common_to_json.py
    python scripts/export_common_to_json.py --input PATH --output PATH

Default paths assume the script is run from the repo root.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Iterator

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_INPUT = REPO_ROOT / "Lexmind" / "Services" / "CommonWordsLibrary.swift"
DEFAULT_OUTPUT = REPO_ROOT / "scripts" / "common_starter.json"

ARRAY_MARKER = re.compile(r"static\s+let\s+all\s*:\s*\[CommonWord\]\s*=\s*\[")


def find_array_body(source: str) -> str:
    """Return the substring between the outer `[` and matching `]` of `all`."""
    match = ARRAY_MARKER.search(source)
    if not match:
        raise SystemExit("Could not locate `static let all: [CommonWord] = [`")
    start = match.end() - 1  # position of the opening `[`
    depth = 0
    in_string = False
    escape = False
    for i in range(start, len(source)):
        ch = source[i]
        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            continue
        if ch == '"':
            in_string = True
            continue
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
            if depth == 0:
                return source[start + 1 : i]
    raise SystemExit("Unbalanced brackets in `all` array")


def iter_common_word_blocks(body: str) -> Iterator[str]:
    """Yield each `CommonWord(...)` call's inner argument text."""
    i = 0
    n = len(body)
    target = "CommonWord("
    while i < n:
        idx = body.find(target, i)
        if idx == -1:
            return
        arg_start = idx + len(target)
        depth = 1
        in_string = False
        escape = False
        j = arg_start
        while j < n and depth > 0:
            ch = body[j]
            if in_string:
                if escape:
                    escape = False
                elif ch == "\\":
                    escape = True
                elif ch == '"':
                    in_string = False
            else:
                if ch == '"':
                    in_string = True
                elif ch == "(":
                    depth += 1
                elif ch == ")":
                    depth -= 1
                    if depth == 0:
                        yield body[arg_start:j]
                        i = j + 1
                        break
            j += 1
        else:
            raise SystemExit("Unterminated CommonWord(...) call")


def split_named_args(block: str) -> list[tuple[str, str]]:
    """Split a CommonWord argument body into [(name, raw_value), ...]."""
    args: list[tuple[str, str]] = []
    depth_paren = 0
    depth_bracket = 0
    in_string = False
    escape = False
    start = 0
    n = len(block)

    def flush(end: int) -> None:
        chunk = block[start:end].strip()
        if not chunk:
            return
        colon = chunk.find(":")
        if colon == -1:
            raise SystemExit(f"Argument without label: {chunk!r}")
        name = chunk[:colon].strip()
        value = chunk[colon + 1 :].strip()
        args.append((name, value))

    for i in range(n):
        ch = block[i]
        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            continue
        if ch == '"':
            in_string = True
            continue
        if ch == "(":
            depth_paren += 1
        elif ch == ")":
            depth_paren -= 1
        elif ch == "[":
            depth_bracket += 1
        elif ch == "]":
            depth_bracket -= 1
        elif ch == "," and depth_paren == 0 and depth_bracket == 0:
            flush(i)
            start = i + 1
    flush(n)
    return args


STRING_LITERAL = re.compile(r'"((?:\\.|[^"\\])*)"', re.DOTALL)


def decode_string_literal(raw: str) -> str:
    """Decode a single Swift double-quoted string literal."""
    raw = raw.strip()
    match = STRING_LITERAL.fullmatch(raw)
    if not match:
        raise SystemExit(f"Expected single string literal, got: {raw!r}")
    body = match.group(1)
    # Swift escape sequences subset we care about
    return (
        body.replace("\\\\", "\\")
        .replace('\\"', '"')
        .replace("\\n", "\n")
        .replace("\\t", "\t")
    )


def decode_string_array(raw: str) -> list[str]:
    """Decode a Swift `[ "a", "b", ... ]` literal into a Python list."""
    raw = raw.strip()
    if not raw.startswith("[") or not raw.endswith("]"):
        raise SystemExit(f"Expected `[...]` array, got: {raw!r}")
    inner = raw[1:-1]
    items: list[str] = []
    for match in STRING_LITERAL.finditer(inner):
        body = match.group(1)
        items.append(
            body.replace("\\\\", "\\")
            .replace('\\"', '"')
            .replace("\\n", "\n")
            .replace("\\t", "\t")
        )
    return items


def decode_level(raw: str) -> str:
    """`.a1` → `A1`."""
    raw = raw.strip()
    if not raw.startswith("."):
        raise SystemExit(f"Expected level enum case (e.g. .a1), got: {raw!r}")
    return raw[1:].upper()


def decode_topic_array(raw: str) -> list[str]:
    """`[.daily, .food]` → `["daily", "food"]`."""
    raw = raw.strip()
    if not raw.startswith("[") or not raw.endswith("]"):
        raise SystemExit(f"Expected `[.case, ...]` array, got: {raw!r}")
    inner = raw[1:-1]
    cases = [item.strip() for item in inner.split(",") if item.strip()]
    out: list[str] = []
    for case in cases:
        if not case.startswith("."):
            raise SystemExit(f"Expected enum case, got: {case!r}")
        out.append(case[1:])
    return out


def convert(block: str) -> dict:
    args = dict(split_named_args(block))
    required = {
        "term", "partOfSpeech", "ipa", "countability",
        "definition", "turkishMeaning", "examples", "level", "topics",
    }
    missing = required - args.keys()
    if missing:
        raise SystemExit(f"Missing fields {missing} in block: {block[:120]!r}")
    return {
        "term": decode_string_literal(args["term"]),
        "partOfSpeech": decode_string_literal(args["partOfSpeech"]),
        "ipa": decode_string_literal(args["ipa"]),
        "countability": decode_string_literal(args["countability"]),
        "definition": decode_string_literal(args["definition"]),
        "turkishMeaning": decode_string_literal(args["turkishMeaning"]),
        "examples": decode_string_array(args["examples"]),
        "level": decode_level(args["level"]),
        "topics": decode_topic_array(args["topics"]),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    source = args.input.read_text(encoding="utf-8")
    body = find_array_body(source)

    entries = [convert(block) for block in iter_common_word_blocks(body)]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(entries, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    try:
        rel = args.output.resolve().relative_to(REPO_ROOT)
        display = str(rel)
    except ValueError:
        display = str(args.output)
    print(f"Wrote {len(entries)} entries → {display}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
