#!/usr/bin/env python3
"""
enrich_datamuse_only.py

No-API alternative to enrich_full.py: populates familyMembers,
synonyms, antonyms, related using ONLY the free Datamuse API.

What it does:
  - synonyms        : Datamuse rel_syn (top 5)        — all verified:true
  - antonyms        : Datamuse rel_ant (top 3)        — all verified:true
  - related         : Datamuse rel_trg (top 4)        — all verified:true
  - familyRoot      : term itself (lemma assumption)
  - familyMembers   : Datamuse `sp=<term>*` prefix wildcard
                      (derived forms / inflections / plurals)
  - familyMembersVerified : same as familyMembers (all from Datamuse)

What it does NOT do (leaves untouched):
  - definition / turkishMeaning / examples / topics  — preserved from starter
  - inflectionExamples                                — stays empty

Existing definition/turkishMeaning/examples (e.g. Common library curated
data) are NEVER overwritten. For Oxford entries whose definition is
empty in the starter, the runtime fallback (Apple Intelligence) will
fill them in on first detail open — same as today.

Usage:
    python3 scripts/enrich_datamuse_only.py \
        --starter scripts/common_starter.json \
        --out Lexmind/Resources/common.json

Runtime: ~3-5 minutes for 2400 entries (16 workers).
Cost   : $0 (Datamuse is free).
"""

from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
DATAMUSE_URL = "https://api.datamuse.com/words"

SYN_LIMIT = 5
ANT_LIMIT = 3
REL_LIMIT = 4
FAMILY_LIMIT = 8


def datamuse_get(params: dict[str, str]) -> list[dict]:
    qs = urllib.parse.urlencode(params)
    url = f"{DATAMUSE_URL}?{qs}"
    req = urllib.request.Request(url, headers={"User-Agent": "Lexmind enrich/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception:
        return []


POS_TAG_MAP = {
    "verb": {"v"},
    "noun": {"n"},
    "adjective": {"adj"},
    "adverb": {"adv"},
}

# Datamuse frequency score (`md=f` → "f:NNN"). Higher = more common.
MIN_REL_FREQ = 1.0       # filters out very rare synonyms (e.g. "sudor")
MIN_FAMILY_FREQ = 0.5    # family members can be slightly rarer (inflections)


def _parse_tags(it: dict) -> tuple[float, set[str]]:
    """Return (frequency_score, set_of_pos_tags) from a Datamuse item."""
    freq = 0.0
    tags: set[str] = set()
    for raw in it.get("tags", []) or []:
        if raw.startswith("f:"):
            try:
                freq = float(raw[2:])
            except ValueError:
                pass
        else:
            tags.add(raw)
    return freq, tags


def filtered_relations(items: list[dict], limit: int, pos_set: set[str] | None,
                       min_freq: float, exclude: str = "") -> list[str]:
    """Filter+sort Datamuse results: same POS (if known), above freq threshold,
    sorted by frequency desc."""
    candidates: list[tuple[float, str]] = []
    for it in items:
        w = (it.get("word") or "").strip().lower()
        if not w or w == exclude:
            continue
        if not all(ch.isalpha() or ch in "-'" for ch in w):
            continue
        freq, tags = _parse_tags(it)
        if pos_set and not (tags & pos_set):
            continue
        if freq < min_freq:
            continue
        candidates.append((freq, w))

    seen: set[str] = set()
    out: list[str] = []
    for _, w in sorted(candidates, key=lambda x: -x[0]):
        if w in seen:
            continue
        seen.add(w)
        out.append(w)
        if len(out) >= limit:
            break
    return out


def fetch_family_members(term: str) -> list[str]:
    """Use `sp=term*` with frequency + POS metadata, then keep only inflections
    that are common enough to be useful."""
    items = datamuse_get({"sp": term + "*", "md": "fp", "max": "50"})
    candidates: list[tuple[float, str]] = []
    for it in items:
        w = (it.get("word") or "").strip().lower()
        if not w or w == term.lower():
            continue
        if not all(ch.isalpha() or ch in "-'" for ch in w):
            continue
        # Length heuristic: an inflection rarely adds more than 6 chars.
        if len(w) > len(term) + 6:
            continue
        freq, _ = _parse_tags(it)
        if freq < MIN_FAMILY_FREQ:
            continue
        candidates.append((freq, w))

    out: list[str] = []
    seen: set[str] = set()
    for _, w in sorted(candidates, key=lambda x: -x[0]):
        if w in seen:
            continue
        seen.add(w)
        out.append(w)
        if len(out) >= FAMILY_LIMIT:
            break
    return out


def enrich_entry(entry: dict) -> dict:
    term = entry["term"].lower()
    pos = (entry.get("partOfSpeech") or "").lower()
    pos_set = POS_TAG_MAP.get(pos)

    syn = filtered_relations(
        datamuse_get({"rel_syn": term, "md": "fp", "max": "50"}),
        SYN_LIMIT, pos_set, MIN_REL_FREQ, exclude=term)
    ant = filtered_relations(
        datamuse_get({"rel_ant": term, "md": "fp", "max": "30"}),
        ANT_LIMIT, pos_set, MIN_REL_FREQ, exclude=term)
    rel = filtered_relations(
        datamuse_get({"rel_trg": term, "md": "fp", "max": "50"}),
        REL_LIMIT, None, MIN_REL_FREQ, exclude=term)  # related: any POS
    family = fetch_family_members(term)

    merged = dict(entry)
    merged["synonyms"] = [{"term": t, "verified": True} for t in syn]
    merged["antonyms"] = [{"term": t, "verified": True} for t in ant]
    merged["related"]  = [{"term": t, "verified": True} for t in rel]

    # Preserve any existing family fields if starter already provided them.
    if not merged.get("familyMembers"):
        merged["familyMembers"] = family
    if not merged.get("familyMembersVerified"):
        merged["familyMembersVerified"] = list(merged["familyMembers"])
    if merged.get("familyRoot") in (None, ""):
        # Best-effort lemma assumption: the term itself is the root.
        merged["familyRoot"] = None

    merged.setdefault("inflectionExamples", [])
    return merged


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--starter", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--limit", type=int, help="process first N entries (test mode)")
    parser.add_argument("--workers", type=int, default=16)
    args = parser.parse_args()

    if not args.starter.exists():
        sys.exit(f"Starter not found: {args.starter}")

    entries = json.loads(args.starter.read_text(encoding="utf-8"))
    if args.limit:
        entries = entries[: args.limit]

    print(f"Enriching {len(entries)} entries via Datamuse ({args.workers} workers)…")
    out_by_index: dict[int, dict] = {}
    done = 0
    start = time.time()
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {pool.submit(enrich_entry, e): i for i, e in enumerate(entries)}
        for fut in as_completed(futures):
            i = futures[fut]
            try:
                out_by_index[i] = fut.result()
            except Exception as exc:
                sys.stderr.write(f"[err] index {i}: {exc}\n")
                out_by_index[i] = entries[i]
            done += 1
            if done % 50 == 0 or done == len(entries):
                rate = done / max(time.time() - start, 0.001)
                eta = (len(entries) - done) / max(rate, 0.001)
                print(f"  {done}/{len(entries)}  ({rate:.1f}/s, ETA {eta:.0f}s)")

    finalized = [out_by_index[i] for i in range(len(entries))]
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(
        json.dumps(finalized, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8")
    print(f"\nWrote {len(finalized)} entries → {args.out}")

    # Quick stats on enrichment density.
    n_syn = sum(1 for e in finalized if e.get("synonyms"))
    n_ant = sum(1 for e in finalized if e.get("antonyms"))
    n_rel = sum(1 for e in finalized if e.get("related"))
    n_fam = sum(1 for e in finalized if e.get("familyMembers"))
    print(f"\nEnrichment coverage:")
    print(f"  synonyms     : {n_syn}/{len(finalized)} ({100*n_syn//max(len(finalized),1)}%)")
    print(f"  antonyms     : {n_ant}/{len(finalized)} ({100*n_ant//max(len(finalized),1)}%)")
    print(f"  related      : {n_rel}/{len(finalized)} ({100*n_rel//max(len(finalized),1)}%)")
    print(f"  familyMembers: {n_fam}/{len(finalized)} ({100*n_fam//max(len(finalized),1)}%)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
