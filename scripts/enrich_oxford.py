#!/usr/bin/env python3
"""
oxford5000_starter.json -> oxford5000.json

Enriches each (term, partOfSpeech, level) entry with definition,
turkishMeaning, IPA, countability, examples and topics by submitting
prompts to Anthropic's Message Batches API.

Usage:
    export ANTHROPIC_API_KEY=sk-ant-...
    python3 scripts/enrich_oxford.py            # submit batch, save batch id
    python3 scripts/enrich_oxford.py --poll     # check status, download when done

Cost estimate (1988 entries, Haiku 4.5 batch, ~600 output tokens each):
    ~$8–25 one-time. Outputs Lexmind/Lexmind/Resources/oxford5000.json.

Requires:  pip install anthropic
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

try:
    import anthropic
except ImportError:
    sys.stderr.write("Run: pip install anthropic\n")
    sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
STARTER = Path(__file__).resolve().parent / "oxford5000_starter.json"
OUT = ROOT / "Lexmind" / "Resources" / "oxford5000.json"
STATE = Path(__file__).resolve().parent / ".batch_state.json"

MODEL = "claude-haiku-4-5-20251001"

TOPICS = [
    "daily", "work", "travel", "academic", "technology", "business",
    "health", "emotions", "food", "nature", "general",
]

SYSTEM_PROMPT = """You are a bilingual lexicographer producing JSON for a Turkish-speaking English-learning app.
For each English headword, return ONE compact JSON object with these exact fields:
- "ipa": IPA transcription in /.../ slashes, American pronunciation.
- "countability": "countable" | "uncountable" | "both" | "N/A" (use N/A for verbs/adjectives/adverbs).
- "definition": one clear English sentence, learner-friendly.
- "turkishMeaning": short Turkish gloss (comma-separated synonyms allowed).
- "examples": 4 natural English sentences using the headword in the given part of speech.
- "topics": 1–2 of: daily, work, travel, academic, technology, business, health, emotions, food, nature, general.

Reply with JSON only. No prose, no markdown."""


def build_user_prompt(term: str, pos: str, level: str) -> str:
    return (
        f"Headword: {term}\n"
        f"Part of speech: {pos}\n"
        f"CEFR level: {level}\n\n"
        "Return JSON only."
    )


def load_starter() -> list[dict]:
    if not STARTER.exists():
        sys.stderr.write(f"Missing {STARTER}. Run scripts/parse_oxford.py first.\n")
        sys.exit(1)
    return json.loads(STARTER.read_text())


def custom_id(i: int, entry: dict) -> str:
    # Must be unique per request within a batch.
    return f"row-{i:05d}-{entry['term']}-{entry['partOfSpeech']}-{entry['level']}"


def submit(client: anthropic.Anthropic) -> str:
    entries = load_starter()
    print(f"Submitting batch of {len(entries)} requests to {MODEL}...")

    requests = []
    for i, e in enumerate(entries):
        requests.append({
            "custom_id": custom_id(i, e),
            "params": {
                "model": MODEL,
                "max_tokens": 800,
                "system": SYSTEM_PROMPT,
                "messages": [{
                    "role": "user",
                    "content": build_user_prompt(e["term"], e["partOfSpeech"], e["level"]),
                }],
            },
        })

    batch = client.messages.batches.create(requests=requests)
    STATE.write_text(json.dumps({"batch_id": batch.id}))
    print(f"batch_id = {batch.id}  (saved to {STATE.name})")
    print("Re-run with --poll to check status and download results.")
    return batch.id


def poll(client: anthropic.Anthropic) -> int:
    if not STATE.exists():
        sys.stderr.write("No batch in flight (state file missing). Submit one first.\n")
        return 1
    batch_id = json.loads(STATE.read_text())["batch_id"]
    while True:
        batch = client.messages.batches.retrieve(batch_id)
        counts = batch.request_counts
        print(f"status={batch.processing_status}  "
              f"processing={counts.processing} succeeded={counts.succeeded} "
              f"errored={counts.errored} canceled={counts.canceled} expired={counts.expired}")
        if batch.processing_status == "ended":
            break
        time.sleep(30)
    return write_results(client, batch_id)


def write_results(client: anthropic.Anthropic, batch_id: str) -> int:
    entries = load_starter()
    by_id = {custom_id(i, e): e for i, e in enumerate(entries)}
    enriched: list[dict] = []
    errors = 0

    for result in client.messages.batches.results(batch_id):
        starter = by_id.get(result.custom_id)
        if not starter:
            continue
        if result.result.type != "succeeded":
            errors += 1
            sys.stderr.write(f"[err] {result.custom_id}: {result.result.type}\n")
            continue
        text = "".join(b.text for b in result.result.message.content if b.type == "text").strip()
        try:
            payload = json.loads(text)
        except json.JSONDecodeError:
            # Some models wrap JSON in ```json fences — strip them.
            cleaned = text.strip("`").lstrip("json").strip()
            try:
                payload = json.loads(cleaned)
            except Exception:
                errors += 1
                sys.stderr.write(f"[parse] {result.custom_id}: {text[:120]}...\n")
                continue
        topics = [t for t in payload.get("topics", []) if t in TOPICS] or ["general"]
        enriched.append({
            "term": starter["term"],
            "partOfSpeech": starter["partOfSpeech"],
            "ipa": payload.get("ipa", ""),
            "countability": payload.get("countability", "N/A"),
            "definition": payload.get("definition", ""),
            "turkishMeaning": payload.get("turkishMeaning", ""),
            "examples": payload.get("examples", [])[:5],
            "level": starter["level"],
            "topics": topics,
        })

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(enriched, ensure_ascii=False, indent=2))
    print(f"\nWrote {len(enriched)} entries ({errors} errors) -> {OUT}")
    if errors == 0:
        STATE.unlink(missing_ok=True)
    return 0 if errors == 0 else 2


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--poll", action="store_true", help="check batch status and download")
    args = parser.parse_args()

    if not os.environ.get("ANTHROPIC_API_KEY"):
        sys.stderr.write("Set ANTHROPIC_API_KEY first.\n")
        return 1
    client = anthropic.Anthropic()
    if args.poll:
        return poll(client)
    submit(client)
    return 0


if __name__ == "__main__":
    sys.exit(main())
