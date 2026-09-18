#!/usr/bin/env bash
# Prove the reviewers can reach their tools BEFORE any run is counted.
#
# Condition 1 of this study was run with every shell call silently denied, because --allowedTools did
# not name Bash. The reports looked normal. This script exists so that cannot happen twice: it asks a
# live session to run one command and report what came back. If the answer is not the expected string,
# no run happens.
set -uo pipefail
SWARM="${SWARM:-$HOME/dev/agentic-review-swarm}"
fail=0
ok(){ printf '\033[32m  ok   %s\033[0m\n' "$1"; }
no(){ printf '\033[31m  FAIL %s\033[0m\n' "$1"; fail=1; }

echo "1. tools installed on this machine"
for t in git node pnpm gitleaks semgrep checkov hadolint shellcheck; do
  if command -v "$t" >/dev/null; then ok "$t  $(command -v $t)"; else no "$t not installed"; fi
done

echo
echo "2. review.sh names Bash in its tool flag"
if grep -q -- '--allowedTools Read,Grep,Glob,Bash,Task' "$SWARM/scripts/review.sh"; then
  ok "Bash present in CLAUDE_FLAGS"
else
  no "Bash missing from --allowedTools in review.sh. Every shell call will be denied."
fi

echo
echo "3. review.sh permits the subject's package manager"
if grep -q 'Bash(pnpm audit' "$SWARM/scripts/review.sh"; then ok "pnpm audit permitted"; else no "pnpm audit not in the allow list"; fi

echo
echo "4. a live session can actually run a command"
probe="$(claude -p 'Run exactly this shell command and reply with only its output: echo TOOLS_REACHABLE' \
  --output-format text --allowedTools Bash --max-turns 6 2>/dev/null | tr -d '[:space:]')"
if [ "$probe" = "TOOLS_REACHABLE" ]; then ok "shell reachable from a headless session"
else no "shell NOT reachable. Got: '${probe:0:60}'"; fi

echo
if [ "$fail" -eq 0 ]; then
  printf '\033[32mpreflight passed. Condition 2 runs may be counted.\033[0m\n'
else
  printf '\033[31mpreflight failed. Do not run condition 2 until every line above is ok.\033[0m\n'
  echo "Missing scanners install with:  brew install gitleaks semgrep checkov hadolint shellcheck"
fi
exit "$fail"
