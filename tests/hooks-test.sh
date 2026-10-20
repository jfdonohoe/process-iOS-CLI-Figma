#!/bin/bash
# Runs every standard hook against fixed inputs and checks its decision. Usage: tests/hooks-test.sh
# Part of the process evaluation (standard §14): run after any hook edit; all must pass.
H="$(cd "$(dirname "$0")/../hooks" && pwd)"; T=$(mktemp -d); pass=0; fail=0
check() { if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: $1 (got '$2', want '$3')"; fi; }
dec() { local o; o=$(cat); [ -n "$o" ] && jq -r '.hookSpecificOutput.permissionDecision // "none"' <<<"$o" || echo none; }
g() { "$H/ios-guard.sh" <<<"$1" | dec; }
# --- ios-guard (inputs built with jq: hand-escaped JSON inside $( ) gets split by brace expansion)
gb() { g "$(jq -nc --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}')"; }
ge() { g "$(jq -nc --arg t "$1" --arg f "$2" --arg n "$3" '{tool_name:$t,tool_input:{file_path:$f,new_string:$n,content:$n}}')"; }
check "push asks"            "$(gb 'git push origin main')" ask
check "push -C dir asks"     "$(gb 'cd x && git -C repo push -u origin main')" ask
check "git status allowed"   "$(gb 'git status')" none
check "'git pushed' text ok" "$(gb 'echo git pushed it')" none
mkdir -p "$T/gen/App.xcodeproj" "$T/plain/App.xcodeproj"; touch "$T/gen/project.yml"
check "pbxproj w/ xcodegen denied" "$(ge Edit "$T/gen/App.xcodeproj/project.pbxproj" x)" deny
check "pbxproj w/o xcodegen ok"    "$(ge Edit "$T/plain/App.xcodeproj/project.pbxproj" x)" none
printf 'import SwiftData\n@Model final class A { var x = 0 }\n' > "$T/Model.swift"; printf 'struct V {}\n' > "$T/View.swift"
check "@Model file asks"     "$(ge Edit "$T/Model.swift" 'var y = 1')" ask
check "new @Model asks"      "$(ge Write "$T/New.swift" '@Model class B {}')" ask
check "plain swift ok"       "$(ge Edit "$T/View.swift" 'struct W {}')" none
# --- swift-lint (opt-in)
git -C "$T" init -q; git -C "$T" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init; l() { local o; o=$("$H/swift-lint.sh" <<<"{\"tool_input\":{\"file_path\":\"$T/View.swift\"}}"); [ -n "$o" ] && echo context || echo none; }
check "lint off without config" "$(l)" none
printf 'struct   V {   }\n' > "$T/View.swift"; echo '{"version":1,"indentation":{"spaces":4}}' > "$T/.swift-format"
check "lint on with config"     "$(l)" context
rm "$T/.swift-format"
# --- build-gate (opt-in)
b() { local o; o=$("$H/build-gate.sh" <<<"{\"cwd\":\"$T\",\"stop_hook_active\":$1}"); [ -n "$o" ] && jq -r '.decision // "none"' <<<"$o" || echo none; }
check "gate off without file"   "$(b false)" none
mkdir -p "$T/.claude"; echo 'echo "x.swift:1: error: boom"; exit 1' > "$T/.claude/build-gate"
check "gate blocks failing build" "$(b false)" block
check "gate never blocks twice"   "$(b true)" none
echo 'exit 0' > "$T/.claude/build-gate"
check "gate passes good build"  "$(b false)" none
echo 'exit 1' > "$T/.claude/build-gate"
check "gate caches a passed change" "$(b false)" none
rm -rf "$T"; echo "hooks-test: $pass passed, $fail failed"; [ $fail -eq 0 ]
