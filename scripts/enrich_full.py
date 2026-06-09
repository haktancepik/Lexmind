#!/usr/bin/env python3
"""
enrich_full.py

Full build-time enrichment pipeline for Lexmind library JSON files.

Input  : starter JSON (term/POS/level, optionally definition+examples+...)
Output : enriched JSON with definition, turkishMeaning, IPA, countability,
         examples, topics, familyRoot, familyMembers, familyMembersVerified,
         inflectionExamples, synonyms[], antonyms[], related[] (each relation
         entry has a `verified: bool` flag based on Datamuse cross-check).

Pipeline (three phases, run sequentially):

    1. submit  — send a Claude Message Batch with all entries
    2. poll    — wait for batch, write intermediate JSON (Claude fields)
    3. verify  — run Datamuse on each entry, mark verified flags, write final

Usage:
    export ANTHROPIC_API_KEY=sk-ant-...
    python scripts/enrich_full.py submit  --starter scripts/oxford5000_starter.json
    python scripts/enrich_full.py poll    --starter scripts/oxford5000_starter.json
    python scripts/enrich_full.py verify  --starter scripts/oxford5000_starter.json

By default `--out` resolves to `Lexmind/Resources/<starter-stem>.json`.

Optional flags:
    --limit N        only process the first N entries (smoke test)
    --out PATH       final output JSON path
    --model NAME     override Claude model id

Requires:  pip install anthropic
Datamuse is free, no API key.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any

def _import_anthropic():
    try:
        import anthropic  # type: ignore
        return anthropic
    except ImportError:
        sys.exit("Run: pip install anthropic")


ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = Path(__file__).resolve().parent

DEFAULT_MODEL = "claude-haiku-4-5-20251001"

TOPICS = [
    "daily", "work", "travel", "academic", "technology", "business",
    "health", "emotions", "food", "nature", "general",
]

SYSTEM_PROMPT = """You are a bilingual lexicographer producing JSON for a Turkish-speaking English-learning app.

For each English headword, return ONE compact JSON object with these exact fields:

  "ipa"                : IPA in /.../ slashes, American pronunciation.
  "countability"       : "countable" | "uncountable" | "both" | "N/A" (use N/A for non-nouns).
  "definition"         : ONE clear English sentence, learner-friendly.
  "turkishMeaning"     : short Turkish gloss (comma-separated synonyms allowed).
  "examples"           : EXACTLY 4 natural English sentences using the headword.
  "topics"             : 1–2 of: daily, work, travel, academic, technology, business, health, emotions, food, nature, general.
  "familyRoot"         : the lemma/root form (lowercase). For most verbs/adjectives/nouns, this is the headword itself unless it is an inflected form.
  "familyMembers"      : 0–6 derived forms or inflections (lowercase). Include past tense, ‑ing form, agent noun, abstract noun, adjective form as relevant. Do NOT include the headword itself.
  "inflectionExamples" : EXACTLY 3 short sentences (≤12 words) each showcasing a DIFFERENT inflection from familyMembers. Wrap the inflected form in **double asterisks**.
  "synonyms"           : 0–5 English synonyms (single words, lowercase).
  "antonyms"           : 0–3 English antonyms (single words, lowercase).
  "related"            : 0–4 closely related English words (single words, lowercase).

Rules:
- Reply with raw JSON only. No prose, no markdown, no code fences.
- Use lowercase for all family/synonym/antonym/related entries.
- Skip any list if no good options exist; never invent rare or obscure words.
"""


# --- Phase 1 & 2: Claude Batch -----------------------------------------------


def build_user_prompt(term: str, pos: str, level: str) -> str:
    return (
        f"Headword: {term}\n"
        f"Part of speech: {pos}\n"
        f"CEFR level: {level}\n\n"
        "Return JSON only."
    )


def custom_id(i: int, entry: dict) -> str:
    return f"row-{i:05d}-{entry['term']}"


def load_starter(path: Path, limit: int | None) -> list[dict]:
    if not path.exists():
        sys.exit(f"Starter not found: {path}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if limit:
        data = data[:limit]
    return data


def state_path(out: Path) -> Path:
    return SCRIPTS / f".enrich_full_state_{out.stem}.json"


def intermediate_path(out: Path) -> Path:
    return SCRIPTS / f".enrich_full_intermediate_{out.stem}.json"


def submit(client, starter: Path, out: Path,
           limit: int | None, model: str) -> int:
    entries = load_starter(starter, limit)
    state = state_path(out)
    if state.exists():
        existing = json.loads(state.read_text())
        sys.stderr.write(
            f"Existing batch in flight (batch_id={existing['batch_id']}). "
            "Run `poll` instead, or delete the state file to resubmit.\n")
        return 1

    print(f"Submitting {len(entries)} requests to {model} (batch)…")
    requests = [
        {
            "custom_id": custom_id(i, e),
            "params": {
                "model": model,
                "max_tokens": 1500,
                "system": SYSTEM_PROMPT,
                "messages": [{
                    "role": "user",
                    "content": build_user_prompt(
                        e["term"], e.get("partOfSpeech", ""), e.get("level", "")),
                }],
            },
        }
        for i, e in enumerate(entries)
    ]
    batch = client.messages.batches.create(requests=requests)
    state.write_text(json.dumps({
        "batch_id": batch.id,
        "starter": str(starter.resolve()),
        "out": str(out.resolve()),
        "model": model,
        "limit": limit,
    }, indent=2))
    print(f"batch_id = {batch.id}")
    print(f"state    = {state.name}")
    print("Run `poll` next to download results when the batch finishes.")
    return 0


def poll(client, starter: Path, out: Path) -> int:
    state = state_path(out)
    if not state.exists():
        sys.exit("No batch state — run `submit` first.")
    info = json.loads(state.read_text())
    batch_id = info["batch_id"]

    while True:
        batch = client.messages.batches.retrieve(batch_id)
        counts = batch.request_counts
        print(
            f"status={batch.processing_status}  "
            f"processing={counts.processing} succeeded={counts.succeeded} "
            f"errored={counts.errored} canceled={counts.canceled} expired={counts.expired}")
        if batch.processing_status == "ended":
            break
        time.sleep(30)

    entries = load_starter(starter, info.get("limit"))
    by_id = {custom_id(i, e): (i, e) for i, e in enumerate(entries)}

    intermediate: list[dict] = []
    errors = 0
    for result in client.messages.batches.results(batch_id):
        if result.custom_id not in by_id:
            continue
        idx, starter_entry = by_id[result.custom_id]
        merged = dict(starter_entry)
        if result.result.type != "succeeded":
            errors += 1
            sys.stderr.write(f"[err]   {result.custom_id}: {result.result.type}\n")
            intermediate.append(merged)
            continue

        text = "".join(
            b.text for b in result.result.message.content if b.type == "text"
        ).strip()
        payload = _parse_json_relaxed(text)
        if payload is None:
            errors += 1
            sys.stderr.write(f"[parse] {result.custom_id}: {text[:120]}…\n")
            intermediate.append(merged)
            continue

        _merge_claude_payload(merged, payload)
        intermediate.append(merged)

    intermediate_path(out).write_text(
        json.dumps(intermediate, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8")
    print(f"\nWrote intermediate ({len(intermediate)} entries, {errors} errors) "
          f"→ {intermediate_path(out).name}")
    print("Run `verify` next to add Datamuse verification flags.")
    state.unlink(missing_ok=True)
    return 0 if errors == 0 else 2


def _parse_json_relaxed(text: str) -> dict | None:
    candidates = [text]
    if text.startswith("```"):
        stripped = text.strip("`")
        if stripped.lstrip().startswith("json"):
            stripped = stripped.split("json", 1)[1]
        candidates.append(stripped.strip())
    for candidate in candidates:
        try:
            return json.loads(candidate)
        except json.JSONDecodeError:
            continue
    return None


def _merge_claude_payload(merged: dict, payload: dict) -> None:
    """Apply Claude fields onto merged starter dict. Starter values win for
    fields the starter already populated (definition/turkishMeaning/etc.)."""

    def take(key: str, default: Any = "") -> Any:
        return payload.get(key, default) if not merged.get(key) else merged[key]

    merged["ipa"] = merged.get("ipa") or payload.get("ipa", "")
    merged["countability"] = merged.get("countability") or payload.get("countability", "N/A")
    merged["definition"] = merged.get("definition") or payload.get("definition", "")
    merged["turkishMeaning"] = merged.get("turkishMeaning") or payload.get("turkishMeaning", "")

    if not merged.get("examples"):
        ex = payload.get("examples") or []
        merged["examples"] = [str(x) for x in ex][:5]

    if not merged.get("topics"):
        raw_topics = payload.get("topics") or []
        topics = [t for t in raw_topics if t in TOPICS] or ["general"]
        merged["topics"] = topics

    family_root = payload.get("familyRoot") or ""
    family_root = family_root.strip().lower()
    if family_root and family_root != merged["term"].lower():
        merged["familyRoot"] = family_root
    else:
        merged["familyRoot"] = None

    members = [str(x).strip().lower() for x in (payload.get("familyMembers") or [])]
    members = [m for m in members if m and m != merged["term"].lower()]
    merged["familyMembers"] = members[:6]

    merged["inflectionExamples"] = [
        str(x).strip() for x in (payload.get("inflectionExamples") or [])
    ][:3]

    merged["_aiSynonyms"] = _clean_relation_list(payload.get("synonyms"), 5)
    merged["_aiAntonyms"] = _clean_relation_list(payload.get("antonyms"), 3)
    merged["_aiRelated"] = _clean_relation_list(payload.get("related"), 4)


def _clean_relation_list(raw: Any, limit: int) -> list[str]:
    if not isinstance(raw, list):
        return []
    out: list[str] = []
    seen: set[str] = set()
    for item in raw:
        if not isinstance(item, str):
            continue
        norm = item.strip().lower()
        if not norm or norm in seen:
            continue
        # only allow letters, hyphens, apostrophes (single-word relations).
        if not all(ch.isalpha() or ch in "-'" for ch in norm):
            continue
        seen.add(norm)
        out.append(norm)
        if len(out) >= limit:
            break
    return out


# --- Phase 3: Datamuse verification ------------------------------------------


DATAMUSE_URL = "https://api.datamuse.com/words"


def datamuse_get(params: dict[str, str]) -> list[dict]:
    qs = urllib.parse.urlencode(params)
    url = f"{DATAMUSE_URL}?{qs}"
    req = urllib.request.Request(url, headers={"User-Agent": "Lexmind enrich/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception:
        return []


def fetch_relation_words(term: str, rel: str, limit: int) -> set[str]:
    items = datamuse_get({"rel_" + rel: term, "max": str(limit)})
    return {it.get("word", "").lower() for it in items if it.get("word")}


def word_exists(word: str) -> bool:
    items = datamuse_get({"sp": word, "md": "p", "max": "1"})
    if not items:
        return False
    return items[0].get("word", "").lower() == word.lower()


def verify_one(entry: dict) -> dict:
    term = entry["term"]

    # Relations: pull all three sets in parallel via Datamuse.
    syn_set = fetch_relation_words(term, "syn", 100)
    ant_set = fetch_relation_words(term, "ant", 50)
    rel_set = fetch_relation_words(term, "trg", 100)

    def mark(items: list[str], verified_set: set[str]) -> list[dict]:
        return [{"term": t, "verified": (t in verified_set)} for t in items]

    entry["synonyms"] = mark(entry.pop("_aiSynonyms", []), syn_set)
    entry["antonyms"] = mark(entry.pop("_aiAntonyms", []), ant_set)
    entry["related"]  = mark(entry.pop("_aiRelated",  []), rel_set)

    members = entry.get("familyMembers", [])
    if members:
        verified_members = [m for m in members if word_exists(m)]
        entry["familyMembersVerified"] = verified_members
    else:
        entry["familyMembersVerified"] = []

    return entry


def verify(starter: Path, out: Path) -> int:
    inter = intermediate_path(out)
    if not inter.exists():
        sys.exit(f"Intermediate not found: {inter.name} — run `poll` first.")
    entries = json.loads(inter.read_text(encoding="utf-8"))
    print(f"Verifying {len(entries)} entries against Datamuse (16 workers)…")

    # Datamuse is free but please don't hammer; 16 in-flight is conservative.
    done = 0
    start = time.time()
    with ThreadPoolExecutor(max_workers=16) as pool:
        futures = {pool.submit(verify_one, dict(e)): i for i, e in enumerate(entries)}
        result_by_index: dict[int, dict] = {}
        for fut in as_completed(futures):
            i = futures[fut]
            try:
                result_by_index[i] = fut.result()
            except Exception as exc:
                sys.stderr.write(f"[verify] index {i}: {exc}\n")
                result_by_index[i] = entries[i]
            done += 1
            if done % 50 == 0 or done == len(entries):
                rate = done / max(time.time() - start, 0.001)
                print(f"  {done}/{len(entries)} ({rate:.1f}/s)")
    finalized = [result_by_index[i] for i in range(len(entries))]

    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(
        json.dumps(finalized, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8")
    print(f"\nWrote {len(finalized)} entries → {out}")
    inter.unlink(missing_ok=True)
    return 0


# --- CLI ----------------------------------------------------------------------


def default_out_for(starter: Path) -> Path:
    return ROOT / "Lexmind" / "Resources" / f"{starter.stem.replace('_starter', '')}.json"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("phase", choices=["submit", "poll", "verify"])
    parser.add_argument("--starter", type=Path, required=True)
    parser.add_argument("--out", type=Path)
    parser.add_argument("--limit", type=int)
    parser.add_argument("--model", default=DEFAULT_MODEL)
    args = parser.parse_args()

    out = args.out or default_out_for(args.starter)

    if args.phase in {"submit", "poll"}:
        if not os.environ.get("ANTHROPIC_API_KEY"):
            sys.exit("Set ANTHROPIC_API_KEY first.")
        anthropic = _import_anthropic()
        client = anthropic.Anthropic()
        if args.phase == "submit":
            return submit(client, args.starter, out, args.limit, args.model)
        return poll(client, args.starter, out)

    return verify(args.starter, out)


if __name__ == "__main__":
    sys.exit(main())
