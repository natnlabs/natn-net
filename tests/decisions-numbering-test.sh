#!/usr/bin/env bash
# Auto-detecting decisions-numbering guard (natnlabs-skills#151).
#
# Canonical, propagated version of natnlabs/sdlc's own
# tests/decisions-numbering-test.sh (natnlabs/sdlc#375, written against that
# repo's decisions/ only). That original hardcodes a bare 3-digit `NNN-`
# pattern, which breaks on the other two numbering schemes actually in use
# across natnlabs/*:
#
#   - `ADR-NNN-` (IdeaCapture, vault-tooling) — the hardcoded pattern
#     extracts zero numbers and the glob matches nothing, so the test
#     reports "ok / 0 failed" while checking nothing at all. A green check
#     with no coverage is worse than no check, because it stops anyone
#     looking.
#   - `NNNN-` (bluetti-esp32-firmware, SparkWorkshop) — the hardcoded
#     3-digit pattern truncates `0001-` and `0002-` both to `000`, then
#     reports `000` as a false-positive duplicate on every such repo.
#
# Rather than per-repo config (a prefix + digit-count pair baked into each
# target repo's copy), which would make every target repo's copy diverge
# from this canonical template by design -- exactly what reconcile.py's
# byte-compare drift detector exists to flag, and would need a deviation-
# section entry in every receiving repo's CLAUDE.md just to suppress that
# drift report forever -- this version auto-detects the scheme in use from
# decisions/'s own contents at run time. One byte-identical script works
# unmodified in every repo; see natnlabs-sdlc/references/
# decisions-numbering-schemes.md for the full rationale and per-repo table.
#
# Detection order: ADR-NNN- (unambiguous literal "ADR-" prefix), then
# NNNN-, then NNN-. The two digit-only forms can never collide with each
# other by construction -- a NNN- filename's 4th character is a literal
# "-", so it can never also match the NNNN- glob, and vice versa -- but the
# order still matches the reasoning laid out during #151's plan review
# (check the more specific shapes first).
#
# Run directly: bash tests/decisions-numbering-test.sh
set -uo pipefail
cd "$(dirname "$0")/.."

shopt -s nullglob
adr_files=(decisions/ADR-[0-9][0-9][0-9]-*.md)
nnnn_files=(decisions/[0-9][0-9][0-9][0-9]-*.md)
nnn_files=(decisions/[0-9][0-9][0-9]-*.md)
shopt -u nullglob

if [ "${#adr_files[@]}" -gt 0 ]; then
  scheme="ADR-NNN-"
  files=("${adr_files[@]}")
  num_regex='^ADR-[0-9]{3}'
elif [ "${#nnnn_files[@]}" -gt 0 ]; then
  scheme="NNNN-"
  files=("${nnnn_files[@]}")
  num_regex='^[0-9]{4}'
elif [ "${#nnn_files[@]}" -gt 0 ]; then
  scheme="NNN-"
  files=("${nnn_files[@]}")
  num_regex='^[0-9]{3}'
else
  echo "decisions-numbering-test: decisions/ has no files matching a known numbering scheme (ADR-NNN-, NNNN-, NNN-) -- nothing to check"
  exit 0
fi

pass=0
fail=0

# --- Duplicate numbers -------------------------------------------------------
dupes=$(printf '%s\n' "${files[@]}" | xargs -n1 basename | grep -oE "$num_regex" | sort | uniq -d)
if [ -z "$dupes" ]; then
  pass=$((pass + 1)); echo "  ok   - no duplicate decision numbers ($scheme scheme)"
else
  fail=$((fail + 1))
  echo "  FAIL - duplicate decision number(s): $(echo "$dupes" | tr '\n' ' ')"
  for n in $dupes; do
    echo "         $n claimed by:"
    printf '%s\n' "${files[@]}" | xargs -n1 basename | grep -E "^${n}-" | sed 's/^/           /'
  done
fi

# --- Heading matches filename ------------------------------------------------
# A renumbered file whose H1 still carries the old number is as misleading as
# a duplicate -- the number a reader sees depends on whether they looked at
# the filename or the heading.
mismatched=0
for f in "${files[@]}"; do
  file_num=$(basename "$f" | grep -oE "$num_regex")
  head_match=$(head -1 "$f" | grep -oE "^# ${num_regex#^}")
  head_num="${head_match#\# }"
  # Only assert when the heading uses the "# <num>" form at all; some
  # entries may legitimately open differently.
  if [ -n "$head_num" ] && [ "$file_num" != "$head_num" ]; then
    mismatched=$((mismatched + 1))
    echo "         $f: filename says $file_num, heading says $head_num"
  fi
done
if [ "$mismatched" -eq 0 ]; then
  pass=$((pass + 1)); echo "  ok   - every decision's H1 number matches its filename"
else
  fail=$((fail + 1)); echo "  FAIL - $mismatched decision(s) with heading/filename number mismatch"
fi

# --- Summary -----------------------------------------------------------------
echo
echo "decisions-numbering-test: $pass passed, $fail failed ($scheme scheme, ${#files[@]} file(s))"
[ "$fail" -eq 0 ]
