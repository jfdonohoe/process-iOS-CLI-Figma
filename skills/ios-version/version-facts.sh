#!/bin/bash
# Read-only. Prints the facts needed to suggest the next version number for an
# iOS project: current version/build, the last release baseline, and the
# changes since it, grouped into the signals the ios-version skill classifies.
# Usage: version-facts.sh [project-dir]

dir="${1:-$PWD}"
cd "$dir" 2>/dev/null || { echo "error: no such directory: $dir"; exit 1; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "error: not a git repository"; exit 1; }

echo "== Project"
echo "dir: $dir"
echo "branch: $(git rev-parse --abbrev-ref HEAD)  head: $(git rev-parse --short HEAD)"
echo "uncommitted files: $(git status --short | wc -l | tr -d ' ')"

echo
echo "== Current version settings"
pbx=$(find . -maxdepth 2 -name project.pbxproj -path "*.xcodeproj/*" -not -path "*/Pods/*" | head -1)
if [ -n "$pbx" ]; then
  echo "pbxproj: $pbx"
  echo "MARKETING_VERSION values: $(grep -oE 'MARKETING_VERSION = [^;]+' "$pbx" | sed 's/.*= //' | sort -u | tr '\n' ' ')($(grep -c 'MARKETING_VERSION = ' "$pbx") occurrences)"
  echo "CURRENT_PROJECT_VERSION values: $(grep -oE 'CURRENT_PROJECT_VERSION = [^;]+' "$pbx" | sed 's/.*= //' | sort -u | tr '\n' ' ')($(grep -c 'CURRENT_PROJECT_VERSION = ' "$pbx") occurrences)"
  echo "IPHONEOS_DEPLOYMENT_TARGET: $(grep -oE 'IPHONEOS_DEPLOYMENT_TARGET = [^;]+' "$pbx" | sed 's/.*= //' | sort -u | tr '\n' ' ')"
else
  echo "pbxproj: none found"
fi
if [ -f project.yml ]; then
  echo "project.yml: MARKETING_VERSION $(grep -E 'MARKETING_VERSION' project.yml | sed 's/.*: *//' | tr -d '"' | tr '\n' ' ')/ CURRENT_PROJECT_VERSION $(grep -E 'CURRENT_PROJECT_VERSION' project.yml | sed 's/.*: *//' | tr -d '"' | tr '\n' ' ')"
fi
[ -f CHANGELOG.md ] && echo "CHANGELOG.md: present, latest heading: $(grep -m1 -E '^## \[' CHANGELOG.md)" || echo "CHANGELOG.md: absent"

echo
echo "== Release baseline"
tag=$(git describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null)
if [ -n "$tag" ]; then
  base="$tag"
  echo "last release tag: $tag ($(git log -1 --format='%h %ad' --date=short "$tag"))"
else
  base=""
  [ -n "$pbx" ] && base=$(git log -1 --format=%H -S 'MARKETING_VERSION' -- "$pbx" 2>/dev/null)
  if [ -n "$base" ]; then
    echo "no v* tag; using the last commit that changed MARKETING_VERSION: $(git log -1 --format='%h %ad %s' --date=short "$base")"
  else
    base=$(git rev-list --max-parents=0 HEAD | tail -1)
    echo "no v* tag and no version change found; using the first commit: $(git log -1 --format='%h %ad %s' --date=short "$base")"
  fi
fi

echo
echo "== Commits since baseline: $(git rev-list --count "$base"..HEAD)"
git log --format='  %h %s' "$base"..HEAD | head -40

# Changes since baseline, committed and uncommitted together.
changes=$( { git diff --name-status "$base"; git ls-files --others --exclude-standard | sed 's/^/A\t/'; } | sort -u -k2)
count() { printf '%s\n' "$changes" | grep -cE "$1"; }

echo
echo "== Changed files since baseline (committed + working tree): $(printf '%s\n' "$changes" | grep -c .)"
echo "added: $(count '^A')  modified: $(count '^M')  deleted: $(count '^D')  renamed: $(count '^R')"
for area in Models Persistence Services Views Tests Resources Assets design; do
  n=$(printf '%s\n' "$changes" | grep -cE "(/|	)[^/	]*$area/")
  [ "$n" -gt 0 ] && echo "  $area: $n"
done

echo
echo "== Signals"
echo "-- new files (possible new features):"
printf '%s\n' "$changes" | grep -E '^A' | grep -E '\.swift$' | grep -vE 'Tests?/' | sed 's/^A\t/  + /' | head -30
echo "-- deleted files (possible removed features):"
printf '%s\n' "$changes" | grep -E '^D' | sed 's/^D\t/  - /' | head -30
echo "-- schema: VersionedSchema declarations now: $(grep -rhoE 'enum [A-Za-z0-9_]+: *VersionedSchema' --include=*.swift . 2>/dev/null | wc -l | tr -d ' ')"
echo "   versionIdentifier values now: $(grep -rhoE 'Schema.Version\([0-9, ]+\)' --include=*.swift . 2>/dev/null | sort -u | tr '\n' ' ')"
echo "   stored properties added in Models/ since baseline: $(git diff "$base" -- '*Models/*.swift' | grep -cE '^\+[[:space:]]*(var|let) [a-zA-Z]')"
echo "   stored properties removed in Models/ since baseline: $(git diff "$base" -- '*Models/*.swift' | grep -cE '^-[[:space:]]*(var|let) [a-zA-Z]')"
echo "-- backup/export format version lines changed:"
git diff "$base" -- '*.swift' | grep -E '^[+-].*formatVersion[^/]*= *[0-9]+' | sed 's/^/  /' | head -5
echo "-- deployment target changed: $(git diff "$base" -- "$pbx" project.yml 2>/dev/null | grep -cE '^[+-].*(IPHONEOS_DEPLOYMENT_TARGET|iOS: )') lines"
echo "-- Info.plist / entitlements / privacy manifest changes:"
printf '%s\n' "$changes" | grep -E 'Info\.plist|\.entitlements|PrivacyInfo\.xcprivacy|INFOPLIST_KEY' | sed 's/^/  /'
git diff "$base" -- "$pbx" 2>/dev/null | grep -E '^[+-].*INFOPLIST_KEY_NS[A-Za-z]+UsageDescription' | sed 's/^/  /'
echo "-- fix-like commit subjects: $(git log --format=%s "$base"..HEAD | grep -ciE '\b(fix|bug|crash|repair|correct)')"
echo "-- feature-like commit subjects: $(git log --format=%s "$base"..HEAD | grep -ciE '\b(add|new|feature|introduce|support)')"
