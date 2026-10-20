#!/bin/bash
# Stop — standard §13.3. Opt-in per project: active only when <repo>/.claude/build-gate exists; its
# first line is the build command (e.g. a quiet `xcodebuild build ...`). If Swift files changed since
# HEAD and that exact change hasn't already passed, run the build; on failure, block the turn from
# ending and hand back the first error lines. Never blocks twice in a row (stop_hook_active).
in=$(cat)
[ "$(jq -r '.stop_hook_active // false' <<<"$in")" = "true" ] && exit 0
cwd=$(jq -r '.cwd // empty' <<<"$in"); [ -n "$cwd" ] || cwd=$PWD
root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || exit 0
gate="$root/.claude/build-gate"; [ -f "$gate" ] || exit 0
changed=$(git -C "$root" status --porcelain -- '*.swift' 2>/dev/null); [ -n "$changed" ] || exit 0
sig=$( (git -C "$root" diff HEAD -- '*.swift'; git -C "$root" ls-files --others --exclude-standard -- '*.swift' | xargs -I{} cat "$root/{}" 2>/dev/null) | shasum | cut -c1-16)
cache="$root/.claude/.build-gate-pass"; [ "$(cat "$cache" 2>/dev/null)" = "$sig" ] && exit 0
cmd=$(head -1 "$gate")
log=$(cd "$root" && bash -c "$cmd" 2>&1); rc=$?
if [ $rc -eq 0 ]; then echo "$sig" > "$cache"; exit 0; fi
errs=$(grep -E 'error:' <<<"$log" | sort -u | head -10); [ -n "$errs" ] || errs=$(tail -10 <<<"$log")
jq -n --arg r "Build gate failed (standard §13.3). Fix before finishing:
$errs" '{decision:"block",reason:$r}'
