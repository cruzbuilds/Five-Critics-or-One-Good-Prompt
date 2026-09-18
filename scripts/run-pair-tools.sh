#!/usr/bin/env bash
# Condition 2: one pair of arms, both with shell access, running simultaneously.
#
# Identical to condition 1 except that both arms can run commands. That is the only variable that
# changes between the two conditions, which is what makes the comparison mean anything.
#
#   scripts/run-pair-tools.sh 1     writes reports/A1.2.md and reports/B1.2.md
#
# Naming: A1.2 means arm A, run 1, condition 2. Condition 1 files stay A1.md, B1.md.
set -uo pipefail
cd "$(dirname "$0")/.."
EXP="$PWD"
n="${1:?usage: scripts/run-pair-tools.sh <pair-number>}"
ARM_A_REPO="${ARM_A_REPO:-$HOME/dev/idea-log-armA}"
ARM_B_REPO="${ARM_B_REPO:-$HOME/dev/idea-log-armB}"
SWARM="${SWARM:-$HOME/dev/agentic-review-swarm}"
EMPTY_TREE=4b825dc642cb6eb9a060e54bf8d69288fbee4904
FLAGS="--allowedTools Read,Grep,Glob,Bash,Task --max-turns 60"

./scripts/preflight.sh >/dev/null 2>&1 || { echo "preflight failed. Run scripts/preflight.sh and fix it first." >&2; exit 3; }

for f in "$EXP/reports/A$n.2.md" "$EXP/reports/B$n.2.md"; do
  [ -e "$f" ] && { echo "$f exists. Raw reports are never overwritten." >&2; exit 3; }
done
a_hash="$(git -C "$ARM_A_REPO" rev-parse HEAD)"; b_hash="$(git -C "$ARM_B_REPO" rev-parse HEAD)"
[ "$a_hash" = "$b_hash" ] || { echo "arms on different commits" >&2; exit 3; }
swarm_hash="$(git -C "$SWARM" rev-parse --short HEAD)"
echo "pair $n with tools | subject $a_hash | swarm $swarm_hash"

run_arm_a() {
  local work; work="$(mktemp -d)"
  tar -C "$ARM_A_REPO" -cf - --exclude=node_modules --exclude=.next . | tar -C "$work" -xf -
  mkdir -p "$work/.claude"
  sed -n '/^cat > "\$work\/.claude\/settings.json" <<.JSON./,/^JSON$/p' "$SWARM/scripts/review.sh" | sed '1d;$d' > "$work/.claude/settings.json"
  ( cd "$work" && claude -p "$(cat "$EXP/prompts/arm-a.txt")" --output-format text $FLAGS 2>/dev/null )
  rm -rf "$work"
}

a_start="$(date -u +%FT%TZ)"; t0=$(date +%s)
run_arm_a > "$EXP/reports/A$n.2.md" 2>&1 & a_pid=$!
( cd "$SWARM" && CLAUDE_FLAGS="$FLAGS" ./scripts/review.sh "$ARM_B_REPO" "$EMPTY_TREE..HEAD" ) > "$EXP/reports/B$n.2.md" 2>&1 & b_pid=$!
wait $a_pid; a_rc=$?; a_secs=$(( $(date +%s) - t0 ))
wait $b_pid; b_rc=$?; b_secs=$(( $(date +%s) - t0 ))
end="$(date -u +%FT%TZ)"

printf 'A%s.2,single-tools,%s,%s,%s,sonnet,,,,,,completed,exit=%s\n' "$n" "$a_start" "$end" "$a_secs" "$a_rc" >> "$EXP/reports/runs.csv"
printf 'B%s.2,swarm-tools,%s,%s,%s,sonnet,,,,,,completed,exit=%s swarm=%s\n' "$n" "$a_start" "$end" "$b_secs" "$b_rc" "$swarm_hash" >> "$EXP/reports/runs.csv"
echo "A$n.2 ${a_secs}s exit=$a_rc | B$n.2 ${b_secs}s exit=$b_rc"
echo
echo "Check both reports mention running a command. If they still say tools were denied, stop and tell Claude."
