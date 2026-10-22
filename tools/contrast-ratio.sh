#!/bin/bash
# WCAG 2.x contrast ratio between a foreground and a background colour. Read-only; prints one line.
#   contrast-ratio.sh <fg> <bg> [fg-opacity]
# A colour is #RRGGBB, or three components as an Xcode colorset writes them:
#   0.247,0.490,0.306 (floats 0–1, any part with a '.'), 0x3F,0x7D,0x4E, or 63,125,78 (0–255).
# fg-opacity (0–1) blends the foreground over the background first, as `.opacity()` does.
# Output: ratio, then pass/fail for normal text 4.5:1, large text and non-text UI 3:1.
set -euo pipefail
[ $# -ge 2 ] || { echo "usage: contrast-ratio.sh <fg> <bg> [fg-opacity]" >&2; exit 2; }

rgb() { # -> "r g b" in 0–255
  local c="${1// /}"
  if [[ $c =~ ^#?([0-9A-Fa-f]{6})$ ]]; then
    local h="${BASH_REMATCH[1]}"; echo "$((16#${h:0:2})) $((16#${h:2:2})) $((16#${h:4:2}))"; return
  fi
  IFS=, read -r a b d <<<"$c"
  [ -n "${d:-}" ] || { echo "bad colour: $1" >&2; exit 2; }
  if [[ $c == *.* ]]; then
    awk -v a="$a" -v b="$b" -v d="$d" 'BEGIN { printf "%.4f %.4f %.4f\n", a*255, b*255, d*255 }'
  else
    # 0-255 integers. All of them 0 or 1 is almost always a float colour typed without decimals (1,1,1 meaning white),
    # which this reads as near-black; warn rather than guess (added 2026-10-22 after a wrong quoted ratio).
    if [[ $a =~ ^[01]$ && $b =~ ^[01]$ && $d =~ ^[01]$ && "$a$b$d" == *1* ]]; then
      echo "warning: '$1' is read as 0-255 integers (near-black). For white write #FFFFFF or 1.0,1.0,1.0" >&2
    fi
    echo "$((a)) $((b)) $((d))"
  fi
}

read -r fr fg fb <<<"$(rgb "$1")"
read -r br bg bb <<<"$(rgb "$2")"
awk -v fr="$fr" -v fg="$fg" -v fb="$fb" -v br="$br" -v bg="$bg" -v bb="$bb" -v al="${3:-1}" '
  function lin(v) { v /= 255; return v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ^ 2.4 }
  function lum(r, g, b) { return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b) }
  BEGIN {
    fr = fr * al + br * (1 - al); fg = fg * al + bg * (1 - al); fb = fb * al + bb * (1 - al)
    l1 = lum(fr, fg, fb); l2 = lum(br, bg, bb)
    if (l1 < l2) { t = l1; l1 = l2; l2 = t }
    r = (l1 + 0.05) / (l2 + 0.05)
    printf "%.2f:1  text %s  large/non-text %s\n", r, (r >= 4.5 ? "pass" : "FAIL"), (r >= 3 ? "pass" : "FAIL")
  }'
