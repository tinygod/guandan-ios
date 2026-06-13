#!/usr/bin/env python3
"""Extract ALL user-facing English prose from App/Sources for localization.

Strategy: collect every string literal, then drop the ones whose immediate
left-context marks them as non-prose (SF Symbols, ids, fonts, colors) or whose
content is glyph/number-only. This catches strings anywhere — data fields,
Text(...), tr(...), helper-function `return`s, ternaries, arrays.

Outputs i18n_strings.json (sorted, de-duplicated master list) + an audit report.
"""
import json
import re
from pathlib import Path

SRC = Path("App/Sources")
STR = re.compile(r'"((?:\\.|[^"\\])*)"')

# If the text immediately before a string literal matches one of these, the
# string is an identifier/glyph/style token, not prose — skip it.
SKIP_CONTEXT = re.compile(
    r'(?:'
    r'\b(?:icon|systemName|systemImage|id|emoji|separator|image|key|font|color|tint|tag|design|sound)\s*:\s*'
    r'|Image\(\s*'
    r'|\.font\(\s*'
    r'|Font\.'
    r'|\.foregroundColor\(\s*'
    r'|UIImage\(\s*'
    r'|forResource:\s*|withExtension:\s*|named:\s*'
    r')$'
)

SF_SYMBOL = re.compile(r'^[a-z0-9]+(\.[a-z0-9]+)+$')
NUMERIC = re.compile(r'^[\d.,%+\-k×x°/ ]+$')

def is_prose(s: str) -> bool:
    t = s.strip()
    if not t or NUMERIC.match(t) or SF_SYMBOL.match(t):
        return False
    return bool(re.search(r'[A-Za-z一-鿿]', t))   # has a latin or CJK letter

def unescape(s: str) -> str:
    return re.sub(r'\\(.)', lambda m: {'n': '\n', 't': '\t'}.get(m.group(1), m.group(1)), s)

strings = {}            # key -> set(files)
skipped = []            # (reason, raw)

for path in sorted(SRC.rglob("*.swift")):
    f = str(path.relative_to(SRC))
    for line in path.read_text().splitlines():
        for m in STR.finditer(line):
            raw = m.group(1)
            before = line[:m.start()]
            if SKIP_CONTEXT.search(before):
                skipped.append(("context", raw)); continue
            if '\\(' in raw:                       # interpolated — handle in code
                skipped.append(("interpolated", raw)); continue
            key = unescape(raw)
            if is_prose(key):
                strings.setdefault(key, set()).add(f)
            else:
                skipped.append(("non-prose", key))

master = sorted(strings)
Path("i18n_strings.json").write_text(
    json.dumps({"count": len(master), "strings": master}, ensure_ascii=False, indent=2))

print(f"Extracted {len(master)} unique translatable strings")
print(f"Skipped {len(skipped)} literals")
interp = sorted({s for r, s in skipped if r == "interpolated" and is_prose(re.sub(r'\\\(.*?\)', '', s))})
print(f"\n--- {len(interp)} interpolated strings with prose (need format-key handling) ---")
for s in interp[:20]:
    print(f"  {s!r}")
