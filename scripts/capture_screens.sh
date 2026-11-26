#!/usr/bin/env bash
# Re-takes every UI screenshot and rebuilds the review sheets.
#
#   scripts/capture_screens.sh                 # all pages, all variants -> docs/layout_review
#   scripts/capture_screens.sh --out /tmp/shots
#   scripts/capture_screens.sh --only "dashboard"      # only pages whose name contains this
#
# How it works: test/layout/layout_test.dart renders each page (with realistic data, no backend) at
# 6 setups (phone, small phone, dark, 1.6x text, tablet, landscape), fails on any overflow/exception,
# and writes one PNG per page+setup. This script runs it, then groups the PNGs and builds contact sheets.
#
# Needs: flutter, python3 with Pillow (pip install pillow).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/docs/layout_review"
ONLY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)  OUT="$(realpath -m "$2")"; shift 2 ;;
    --only) ONLY="$2"; shift 2 ;;
    -h|--help) sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1 (try --help)" >&2; exit 2 ;;
  esac
done

command -v flutter >/dev/null || { echo "flutter not found in PATH" >&2; exit 1; }
python3 -c "import PIL" 2>/dev/null || { echo "Pillow missing: pip install pillow" >&2; exit 1; }

RAW="$(mktemp -d)"
trap 'rm -rf "$RAW"' EXIT

echo "==> Rendering pages (this takes about a minute)..."
cd "$ROOT"
TEST_ARGS=(test/layout/layout_test.dart)
[[ -n "$ONLY" ]] && TEST_ARGS+=(--plain-name "$ONLY")
STATUS=0
SHOT_DIR="$RAW" flutter test "${TEST_ARGS[@]}" || STATUS=$?

shopt -s nullglob
PNGS=("$RAW"/*.png)
if [[ ${#PNGS[@]} -eq 0 ]]; then echo "No screenshots were produced." >&2; exit 1; fi

echo "==> Organising ${#PNGS[@]} screenshots into $OUT"
if [[ -z "$ONLY" ]]; then rm -rf "$OUT"; fi
mkdir -p "$OUT/phone" "$OUT/other_sizes" "$OUT/sheets"
for f in "${PNGS[@]}"; do
  case "$f" in
    *__phone.png) cp "$f" "$OUT/phone/" ;;
    *)            cp "$f" "$OUT/other_sizes/" ;;
  esac
done

echo "==> Building contact sheets"
python3 - "$OUT" <<'PY'
import os, sys
from PIL import Image, ImageDraw

out = sys.argv[1]
phone = os.path.join(out, "phone")

# Which pages go on which sheet (missing pages are skipped).
SHEETS = {
    "1_auth_and_profile_forms": [
        "auth_user_login", "auth_user_signup_errors", "auth_astrologer_login", "auth_astrologer_signup",
        "auth_otp", "auth_loading", "user_profile_setup", "user_profile_edit",
        "astro_profile_setup", "astro_profile_errors", "astro_profile_edit"],
    "2_astrologer_list_detail_states": [
        "user_home", "astrologers_list", "astrologers_loading", "astrologers_error", "astrologers_no_match",
        "history_filled", "history_empty", "detail_online", "detail_busy_long_name", "detail_loading"],
    "3_session_and_chat": [
        "session_starting", "session_waiting", "session_waiting_reconnecting", "session_summary_user",
        "session_summary_astrologer", "session_failed", "chat_user", "chat_astrologer", "chat_empty_offline"],
    "4_dashboard_and_calls": [
        "dashboard_empty_offline", "dashboard_requests", "dashboard_busy_active", "dashboard_loading",
        "voice_connected", "voice_waiting_muted", "voice_failed", "video_waiting", "video_connected", "video_failed"],
}

def sheet(names, path, cols=5, w=250):
    tiles = []
    for n in names:
        p = os.path.join(phone, f"{n}__phone.png")
        if os.path.exists(p):
            im = Image.open(p).convert("RGB")
            tiles.append((n, im.resize((w, int(im.height * w / im.width)))))
    if not tiles:
        return False
    rows = [tiles[i:i + cols] for i in range(0, len(tiles), cols)]
    H = sum(max(t.height for _, t in r) + 18 for r in rows)
    W = cols * w + (cols + 1) * 6
    img = Image.new("RGB", (W, H), (200, 200, 200))
    d = ImageDraw.Draw(img)
    y = 0
    for r in rows:
        x = 6
        for n, t in r:
            d.text((x, y + 2), n[:44], fill=(0, 0, 0))
            img.paste(t, (x, y + 16))
            x += w + 6
        y += max(t.height for _, t in r) + 18
    img.save(path)
    return True

for name, pages in SHEETS.items():
    if sheet(pages, os.path.join(out, "sheets", f"{name}.png")):
        print("  sheet:", name)
PY

echo
echo "Screenshots : $OUT/phone (390x844), $OUT/other_sizes (small, dark, 1.6x text, tablet, landscape)"
echo "Sheets      : $OUT/sheets"
if [[ "$STATUS" -ne 0 ]]; then
  echo "RESULT      : layout test FAILED - see the errors above (an overflow or exception on some page)" >&2
  exit "$STATUS"
fi
echo "RESULT      : all pages rendered with no overflow or errors"
