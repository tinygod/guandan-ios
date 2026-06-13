#!/usr/bin/env python3
"""Patch GuandanApp.xcodeproj to register L10n.swift (compiled) and
Localizable.xcstrings (resource), and add the 12 target languages."""
from pathlib import Path

P = Path("App/GuandanApp.xcodeproj/project.pbxproj")
src = P.read_text()

# Deterministic, unique 24-hex object IDs (verified absent before patching).
L10N_REF, L10N_BLD = "F10E000000000000000000A1", "B11D000000000000000000A1"
XCS_REF,  XCS_BLD  = "F10E000000000000000000C5", "B11D000000000000000000C5"
for oid in (L10N_REF, L10N_BLD, XCS_REF, XCS_BLD):
    assert oid not in src, f"id collision: {oid}"

LANGS = ["zh-Hans", "zh-Hant", "ja", "ko", "es", "fr", "de", "pt-BR", "ru", "ar", "hi", "id"]

def once(old, new):
    global src
    assert src.count(old) >= 1, f"anchor not found: {old[:60]!r}"
    src = src.replace(old, new, 1)

# 1) PBXBuildFile entries
once("/* Begin PBXBuildFile section */\n",
     "/* Begin PBXBuildFile section */\n"
     f"\t\t{L10N_BLD} /* L10n.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {L10N_REF} /* L10n.swift */; }};\n"
     f"\t\t{XCS_BLD} /* Localizable.xcstrings in Resources */ = {{isa = PBXBuildFile; fileRef = {XCS_REF} /* Localizable.xcstrings */; }};\n")

# 2) PBXFileReference entries
once("/* Begin PBXFileReference section */\n",
     "/* Begin PBXFileReference section */\n"
     f"\t\t{L10N_REF} /* L10n.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = L10n.swift; sourceTree = \"<group>\"; }};\n"
     f"\t\t{XCS_REF} /* Localizable.xcstrings */ = {{isa = PBXFileReference; lastKnownFileType = text.json.xcstrings; path = Localizable.xcstrings; sourceTree = \"<group>\"; }};\n")

# 3) L10n.swift into DesignSystem group
once("\t\t\t\t402A664062C7BD0CBD2972B2 /* Theme.swift */,\n",
     "\t\t\t\t402A664062C7BD0CBD2972B2 /* Theme.swift */,\n"
     f"\t\t\t\t{L10N_REF} /* L10n.swift */,\n")

# 4) Localizable.xcstrings into top-level Sources group (next to Assets.xcassets)
once("\t\t\t\t6C7BC54A2FE1A9F3A9074DD2 /* Assets.xcassets */,\n\t\t\t\t1C79BA6B7B501DDE39070667 /* GuandanApp.swift */,\n",
     "\t\t\t\t6C7BC54A2FE1A9F3A9074DD2 /* Assets.xcassets */,\n"
     f"\t\t\t\t{XCS_REF} /* Localizable.xcstrings */,\n"
     "\t\t\t\t1C79BA6B7B501DDE39070667 /* GuandanApp.swift */,\n")

# 5) L10n.swift into Sources build phase
once("\t\t\t\tF06781993BDF5768CC69295D /* CardView.swift in Sources */,\n",
     "\t\t\t\tF06781993BDF5768CC69295D /* CardView.swift in Sources */,\n"
     f"\t\t\t\t{L10N_BLD} /* L10n.swift in Sources */,\n")

# 6) Localizable.xcstrings into Resources build phase
once("\t\t\t\t5AB907623953C0035F033EE9 /* Assets.xcassets in Resources */,\n",
     "\t\t\t\t5AB907623953C0035F033EE9 /* Assets.xcassets in Resources */,\n"
     f"\t\t\t\t{XCS_BLD} /* Localizable.xcstrings in Resources */,\n")

# 7) knownRegions
region_lines = "".join(f"\t\t\t\t{l},\n" for l in LANGS)
once("\t\t\tknownRegions = (\n\t\t\t\tBase,\n\t\t\t\ten,\n\t\t\t);",
     "\t\t\tknownRegions = (\n\t\t\t\tBase,\n\t\t\t\ten,\n" + region_lines + "\t\t\t);")

P.write_text(src)
print("Patched pbxproj:")
print("  + L10n.swift (Sources)")
print("  + Localizable.xcstrings (Resources)")
print("  + knownRegions:", ", ".join(LANGS))
