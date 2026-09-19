#!/usr/bin/env bash
# Fails if anything already committed under findings/ or reports/ was changed or deleted.
#
# Evidence is append-only. New lines and new files are fine. Editing a recorded finding, changing a
# verdict in place, or removing a run is not, because the whole reason anyone should believe the
# scoring in this study is that they can see every judgment in the order it was made, including the
# ones that turned out wrong.
#
# Corrections do not edit. They append to findings/corrections.csv, naming the finding, the old
# verdict, the new one, and why.
#
#   scripts/check-append-only.sh            check the working tree against HEAD
#   scripts/check-append-only.sh <ref>      check against some other commit
set -uo pipefail
cd "$(dirname "$0")/.."

base="${1:-HEAD}"
guarded="findings reports experiment-002/HYPOTHESES.md experiment-002/PROTOCOL.md experiment-002/SUBJECTS.md experiment-002/DEVIATIONS.md experiment-002/findings experiment-002/reports"
fail=0

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  red "not a git repository"; exit 1
fi

# Deleted or renamed files under the guarded paths.
gone="$(git diff --diff-filter=DR --name-only "$base" -- $guarded)"
if [ -n "$gone" ]; then
  red "Evidence files deleted or renamed:"
  printf '  %s\n' $gone
  fail=1
fi

# Modified files: allowed only if every change is an addition. Any removed line means an existing
# record was edited or dropped.
for f in $(git diff --diff-filter=M --name-only "$base" -- $guarded); do
  removed="$(git diff --unified=0 "$base" -- "$f" | grep -c '^-[^-]' || true)"
  if [ "$removed" -gt 0 ]; then
    red "Existing records changed in $f ($removed line(s) removed or rewritten):"
    git diff --unified=0 "$base" -- "$f" | grep '^-[^-]' | head -5 | sed 's/^/    /'
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  green "append-only holds: evidence was added to, never rewritten"
else
  echo
  echo "To correct a verdict, append a row to findings/corrections.csv instead of editing the"
  echo "original. The original stays as it was recorded. See findings/README.md."
fi
exit "$fail"
