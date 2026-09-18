#!/usr/bin/env bash
# Run one pair of review arms at the same time, in the same harness, on the same frozen commit.
#
#   scripts/run-pair.sh 1        runs A1 and B1 in parallel
#   scripts/run-pair.sh 2        runs A2 and B2
#
# Why parallel rather than alternating: the protocol originally said A1, B1, A2, B2 to control for
# drift across a session. Running each pair simultaneously controls for it better, because both arms
# see the same model in the same minute. Recorded as an amendment in the deviation log, made before
# the first run and before any result existed.
#
# Both arms get identical treatment:
#   - the same frozen tree, from their own working copy
#   - a scratch copy, so neither writes to anything that matters
#   - the same .claude/settings.json permissions that review.sh writes for the swarm
#   - the same --allowedTools set
#   - the same model, whatever the account default is, recorded per run
#
# Arm A reads the repository. Arm B is handed the whole repository as its "change", using the empty
# tree hash as the range, because review.sh is built to review a diff and this subject has exactly one
# root commit. Every file is therefore a changed file both arms must read in full.
set -uo pipefail
cd "$(dirname "$0")/.."
EXP="$PWD"

n="${1:?usage: scripts/run-pair.sh <pair-number>}"
ARM_A_REPO="${ARM_A_REPO:-$HOME/dev/idea-log-armA}"
ARM_B_REPO="${ARM_B_REPO:-$HOME/dev/idea-log-armB}"
SWARM="${SWARM:-$HOME/dev/agentic-review-swarm}"
EMPTY_TREE=4b825dc642cb6eb9a060e54bf8d69288fbee4904

command -v claude >/dev/null || { echo "claude CLI not on PATH" >&2; exit 3; }
[ -d "$ARM_A_REPO/.git" ] || { echo "missing $ARM_A_REPO" >&2; exit 3; }
[ -d "$ARM_B_REPO/.git" ] || { echo "missing $ARM_B_REPO" >&2; exit 3; }
[ -x "$SWARM/scripts/review.sh" ] || { echo "missing $SWARM/scripts/review.sh" >&2; exit 3; }

for f in "$EXP/reports/A$n.md" "$EXP/reports/B$n.md"; do
  [ -e "$f" ] && { echo "$f already exists. Raw reports are never overwritten." >&2; exit 3; }
done

a_hash="$(git -C "$ARM_A_REPO" rev-parse HEAD)"
b_hash="$(git -C "$ARM_B_REPO" rev-parse HEAD)"
[ "$a_hash" = "$b_hash" ] || { echo "arms are on different commits: $a_hash vs $b_hash" >&2; exit 3; }
swarm_hash="$(git -C "$SWARM" rev-parse --short HEAD)"

echo "pair $n"
echo "  subject commit : $a_hash"
echo "  swarm version  : $swarm_hash"
echo

# ---------------------------------------------------------------- arm A, in a scratch copy
run_arm_a() {
  local work; work="$(mktemp -d)"
  tar -C "$ARM_A_REPO" -cf - --exclude=node_modules --exclude=.next . | tar -C "$work" -xf -
  mkdir -p "$work/.claude"
  # The same permission set review.sh writes for the swarm. Identical tool access is the whole point.
  sed -n '/^cat > "\$work\/.claude\/settings.json" <<.JSON./,/^JSON$/p' "$SWARM/scripts/review.sh" \
    | sed '1d;$d' > "$work/.claude/settings.json"
  ( cd "$work" && claude -p "$(cat "$EXP/prompts/arm-a.txt")" \
      --output-format text --allowedTools Read,Grep,Glob --max-turns 60 2>/dev/null )
  rm -rf "$work"
}

a_start="$(date -u +%FT%TZ)"; a_epoch=$(date +%s)
run_arm_a > "$EXP/reports/A$n.md" 2>&1 &
a_pid=$!

b_start="$(date -u +%FT%TZ)"; b_epoch=$(date +%s)
( cd "$SWARM" && ./scripts/review.sh "$ARM_B_REPO" "$EMPTY_TREE..HEAD" ) > "$EXP/reports/B$n.md" 2>&1 &
b_pid=$!

wait $a_pid; a_rc=$?; a_end="$(date -u +%FT%TZ)"; a_secs=$(( $(date +%s) - a_epoch ))
wait $b_pid; b_rc=$?; b_end="$(date -u +%FT%TZ)"; b_secs=$(( $(date +%s) - b_epoch ))

model="$(claude --version 2>/dev/null | head -1)"
printf 'A%s,single,%s,%s,%s,%s,,,,,,%s,exit=%s\n' \
  "$n" "$a_start" "$a_end" "$a_secs" "$model" "completed" "$a_rc" >> "$EXP/reports/runs.csv"
printf 'B%s,swarm,%s,%s,%s,%s,,,,,,%s,exit=%s swarm=%s\n' \
  "$n" "$b_start" "$b_end" "$b_secs" "$model" "completed" "$b_rc" "$swarm_hash" >> "$EXP/reports/runs.csv"

echo "A$n  ${a_secs}s  exit=$a_rc  $(wc -l < "$EXP/reports/A$n.md") lines"
echo "B$n  ${b_secs}s  exit=$b_rc  $(wc -l < "$EXP/reports/B$n.md") lines"
echo
echo "Raw reports written. Do not edit them. Fill in tokens and cost in reports/runs.csv by hand."
