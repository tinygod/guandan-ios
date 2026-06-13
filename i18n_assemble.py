#!/usr/bin/env python3
"""Merge per-language translation chunks into a single Localizable.xcstrings.

Validates that every language covers all 654 master strings with non-empty
values, then emits an Xcode String Catalog keyed by the English source text.
"""
import json
import sys
from pathlib import Path

OUT = Path("App/Sources/Localizable.xcstrings")
master = json.load(open("i18n/master.json"))
langs = [l["code"] for l in json.load(open("i18n/langs.json"))]
id2en = {m["id"]: m["en"] for m in master}
ids = [m["id"] for m in master]

# merge chunks per language
per_lang = {}        # code -> {id: text}
problems = []
for code in langs:
    merged = {}
    ci = 0
    while True:
        f = Path(f"i18n/out/{code}__c{ci}.json")
        if not f.exists():
            break
        data = json.loads(f.read_text())
        merged.update(data)
        ci += 1
    per_lang[code] = merged
    missing = [i for i in ids if i not in merged]
    empty = [i for i in ids if i in merged and not str(merged[i]).strip()]
    if missing:
        problems.append(f"{code}: missing {len(missing)} ids e.g. {missing[:3]}")
    if empty:
        problems.append(f"{code}: {len(empty)} empty values e.g. {empty[:3]}")

if problems:
    print("VALIDATION FAILED:")
    for p in problems:
        print("  " + p)
    sys.exit(1)

print(f"All {len(langs)} languages cover all {len(ids)} strings. Building catalog...")

# Build String Catalog. Key = English source text.
strings_obj = {}
for m in master:
    en = m["en"]
    loc = {}
    for code in langs:
        val = per_lang[code][m["id"]]
        loc[code] = {"stringUnit": {"state": "translated", "value": val}}
    strings_obj[en] = {"extractionState": "manual", "localizations": loc}

catalog = {"sourceLanguage": "en", "strings": strings_obj, "version": "1.0"}
OUT.write_text(json.dumps(catalog, ensure_ascii=False, indent=2))
print(f"Wrote {OUT} — {len(strings_obj)} keys × {len(langs)} languages")
# spot check a couple
print("\n--- spot check zh-Hans ---")
for en in ["Single", "What is GuanDan?", "Next", "Your team"]:
    if en in strings_obj:
        print(f"  {en!r} -> {strings_obj[en]['localizations']['zh-Hans']['stringUnit']['value']!r}")
print("--- spot check ar (RTL) ---")
for en in ["Single", "Next"]:
    if en in strings_obj:
        print(f"  {en!r} -> {strings_obj[en]['localizations']['ar']['stringUnit']['value']!r}")
