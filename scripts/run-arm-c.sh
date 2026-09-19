#!/usr/bin/env bash
# Arm C: one general review instruction, no domain map. Added 2026-09-19, AFTER the A/B results were
# observed. Exploratory follow-up, not part of the preregistered comparison. See DEVIATIONS.md D-005.
#
#   scripts/run-arm-c.sh 1     writes reports/C1.md (raw text) and reports/C1.stream.jsonl (full event log)
#
# Same tool permissions and flags as the tools condition (A*.2 / B*.2). Same frozen subject commit.
# Fresh scratch clone of the sealed original per run, so the reviewer sees the repository and nothing
# else: no study repo, no reports, no findings, no prompts from the other arms.
set -uo pipefail
cd "$(dirname "$0")/.."
EXP="$PWD"
n="${1:?usage: scripts/run-arm-c.sh <run-number>}"
SUBJECT="${SUBJECT:-$HOME/dev/idea-log}"
SWARM="${SWARM:-$HOME/dev/agentic-review-swarm}"
V0=b38c5b0dc51206bda7cd97fc27d0d252d6fd6a02
FLAGS="--allowedTools Read,Grep,Glob,Bash,Task --max-turns 60"

./scripts/preflight.sh >/dev/null 2>&1 || { echo "preflight failed. Run scripts/preflight.sh and fix it first." >&2; exit 3; }
for f in "$EXP/reports/C$n.md" "$EXP/reports/C$n.stream.jsonl"; do
  [ -e "$f" ] && { echo "$f exists. Raw reports are never overwritten." >&2; exit 3; }
done
[ "$(git -C "$SUBJECT" rev-parse HEAD)" = "$V0" ] || { echo "subject is not at v0-raw ($V0)" >&2; exit 3; }
[ "$(wc -w < "$EXP/prompts/arm-c.txt" | tr -d ' ')" -le 40 ] || { echo "prompts/arm-c.txt grew. Arm C is two sentences." >&2; exit 3; }

work="$(mktemp -d)"
git clone -q "$SUBJECT" "$work" && git -C "$work" checkout -q "$V0"
[ "$(git -C "$work" rev-parse HEAD)" = "$V0" ] || { echo "scratch clone not at v0-raw" >&2; exit 3; }
mkdir -p "$work/.claude"
sed -n '/^cat > "\$work\/.claude\/settings.json" <<.JSON./,/^JSON$/p' "$SWARM/scripts/review.sh" | sed '1d;$d' > "$work/.claude/settings.json"
[ -s "$work/.claude/settings.json" ] || { echo "could not extract settings.json from review.sh" >&2; exit 3; }

echo "C$n | subject $V0 | scratch $work | $(claude --version 2>/dev/null)"
start="$(date -u +%FT%TZ)"; t0=$(date +%s)
( cd "$work" && claude -p "$(cat "$EXP/prompts/arm-c.txt")" --output-format stream-json --verbose $FLAGS 2>/dev/null ) > "$EXP/reports/C$n.stream.jsonl"
rc=$?; secs=$(( $(date +%s) - t0 )); end="$(date -u +%FT%TZ)"
rm -rf "$work"

meta="$(mktemp)"
python3 - "$EXP/reports/C$n.stream.jsonl" "$EXP/reports/C$n.md" > "$meta" <<'PY'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
result = None; tools = 0; errors = 0; models = set()
for line in open(src):
    line = line.strip()
    if not line: continue
    try: ev = json.loads(line)
    except Exception: continue
    t = ev.get("type")
    if t == "assistant":
        m = ev.get("message", {})
        if m.get("model"): models.add(m["model"])
        for b in m.get("content", []):
            if b.get("type") == "tool_use": tools += 1
    elif t == "user":
        for b in ev.get("message", {}).get("content", []):
            if isinstance(b, dict) and b.get("type") == "tool_result" and b.get("is_error"): errors += 1
    elif t == "result":
        result = ev
if result is None:
    open(dst, "w").write("(no result event in stream; see .stream.jsonl)\n")
    print("NO_RESULT,,,,,%d,%d,%s" % (tools, errors, "|".join(sorted(models))))
else:
    open(dst, "w").write((result.get("result") or "") + "\n")
    u = result.get("usage", {}) or {}
    print("%s,%s,%s,%s,%s,%d,%d,%s" % (
        result.get("subtype", ""), u.get("input_tokens", ""), u.get("output_tokens", ""),
        result.get("total_cost_usd", ""), result.get("num_turns", ""), tools, errors, "|".join(sorted(models))))
PY
IFS=, read -r subtype in_tok out_tok cost turns tools errs models < "$meta"; rm -f "$meta"
printf 'C%s,naive-tools,%s,%s,%s,%s,%s,%s,%s,%s,%s,completed,exit=%s subject=%s subtype=%s turns=%s added-after-AB=D-005\n' \
  "$n" "$start" "$end" "$secs" "${models:-sonnet}" "$in_tok" "$out_tok" "$cost" "$tools" "$errs" "$rc" "${V0:0:7}" "$subtype" "$turns" >> "$EXP/reports/runs.csv"
echo "C$n ${secs}s exit=$rc | model=${models:-?} | tools=$tools failed=$errs | in=$in_tok out=$out_tok cost=\$$cost"
echo
echo "Do not read reports/C$n.md yet. Run the next one. Interpretation waits until C3 is in."
