#!/bin/bash
# Capture localized App Store screenshots (6.9" landscape) for all 13 languages.
# Uses the app's `-route` launch hook to jump to each screen, then rotates the
# portrait-canvas capture 90° CCW to upright landscape (2868x1320).
set -e
MAX="${1:?usage: capture_screenshots.sh <iPhone-16/17-Pro-Max-UDID>}"
BID=com.yorick.guandan
cd "$(dirname "$0")/../App/fastlane"
LANGS=("en-US:en" "zh-Hans:zh-Hans" "zh-Hant:zh-Hant" "ja:ja" "ko:ko" "es-ES:es" "fr-FR:fr" "de-DE:de" "pt-BR:pt-BR" "ru:ru" "ar-SA:ar" "hi:hi" "id:id")
SCREENS=("01_welcome:" "02_academy:learn" "03_game:game" "04_combos:lesson2")
for pair in "${LANGS[@]}"; do
  asc="${pair%%:*}"; lang="${pair##*:}"; loc="${lang//-/_}"; mkdir -p "screenshots/$asc"
  for s in "${SCREENS[@]}"; do
    fname="${s%%:*}"; route="${s##*:}"
    xcrun simctl terminate "$MAX" "$BID" 2>/dev/null || true
    xcrun simctl launch "$MAX" "$BID" -AppleLanguages "($lang)" -AppleLocale "$loc" -route "$route" >/dev/null 2>&1
    sleep 4
    out="screenshots/$asc/$fname.png"
    xcrun simctl io "$MAX" screenshot "$out" >/dev/null 2>&1
    sips -r 270 "$out" >/dev/null 2>&1
  done
  echo "$asc done"
done
