# Experiment 002: V2 versus agentic investigation

Does giving the V2 reviewers iterative investigative autonomy, dynamic selection from a known tool
set, state-card resumption, and manager-directed follow-up produce better-supported findings than the
one-pass V2 workflow, and at what cost?

This directory is the sealed record. `HYPOTHESES.md` and `PROTOCOL.md` were committed before any run
and are never edited; `SUBJECTS.md` is appended before each subject's first run; `DEVIATIONS.md` is
appended whenever anything changes. Raw reports, state cards, manager logs and adjudication land
under `reports/` and `findings/` here as the experiment runs, under the same append-only rule as
Experiment 001's, enforced by `../scripts/check-append-only.sh` once those directories exist.

The design being tested, the V2 baseline it is tested against, and the research record that led
here are in [agentic-review-swarm](https://github.com/cruzbuilds/agentic-review-swarm): start at
`docs/research/README.md`. The code under test is tag `v2.0-baseline` for V2 and branch
`v3/agentic-investigation` for V3, at a commit recorded in `PROTOCOL.md` before the first V3 run.

**Status: sealed, not started.** No V2 baseline run, no subject chosen beyond the known one, no V3
code.
