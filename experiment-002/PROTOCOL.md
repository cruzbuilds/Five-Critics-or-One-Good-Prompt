# Experiment 002: protocol

**Frozen with `HYPOTHESES.md`, before any run.** Changes after the first run go in `DEVIATIONS.md`
in this directory, with the reason and the risk, as Experiment 001 did. The full design this protocol
executes is `docs/research/v3-agentic-investigation-design.md` (revision 3, `fa4a5a8`) in the swarm
repository; where this page and that document differ, this page governs the experiment and the
difference is a deviation to log.

## Arms

| Arm | What | Code |
| --- | --- | --- |
| V2 | six reviewers, one pass, arbiter | agentic-review-swarm at tag `v2.0-baseline` (`9d4d365`) |
| V3 | the same six charters plus the investigation addendum, round 0 then manager-directed bounded rounds, the same arbiter | agentic-review-swarm on `v3/agentic-investigation`, at a commit recorded here before the first V3 run |

Same model for every reviewer and the manager (Sonnet, as the adapters pin). Same tool registry, the
`review.sh` allow list at `v2.0-baseline`. Three runs per arm per subject. Round 0 of V3 receives the
same change description as V2's fan-out.

## Subjects

1. **Known subject.** `idea-log` at `b38c5b0`, Experiment 001's. Contaminated by design: the
   authors of V2 and V3 know its defects. Reported as replication on a known subject, never as
   discovery. Existing claims inherit their Experiment 001 verdicts; new claims are adjudicated by
   the same rules.
2. **Primary-discovery subject.** A repository with existing automated tests, CI, infrastructure or
   deployment configuration, documentation, and meaningful business logic. Chosen and frozen before
   any run, reviewed by nobody beforehand, its hash appended to `SUBJECTS.md` in this directory
   before the first V2 baseline run. Discovery claims come from this subject only.

## Order of operations

1. Commit and push this directory. Nothing runs before the push exists.
2. Choose and freeze the primary-discovery subject; append its hash to `SUBJECTS.md`.
3. Run V2 on both subjects, three runs each, instrumented with `--output-format stream-json` so
   per-reviewer tool calls and tokens are on record. Save raw reports and streams under
   `reports/v2/`. This is the baseline and the source of V3's budget check.
4. Compare V2's per-reviewer tool calls and output tokens against the design's budgets (soft 12
   calls per round, hard 36 per run, 60k output tokens, 20 minutes). If they differ materially,
   reset the budgets from V2's numbers before any V3 run and log the change in `DEVIATIONS.md`.
5. Implement V3 on its branch. Run its component evals (manager seeds, investigator seeds) and
   preserve them in the swarm repository under `docs/evals/`, as V2's were. Record the V3 commit
   here.
6. Run V3 on both subjects, three runs each, same instrumentation. Save under `reports/v3/`, with
   every state card, the manager log, and the budget ledger per run.
7. Extract claims from all twelve final reports by Experiment 001's rules. Adjudicate new claims
   blind to arm, V2 first. Score severity and actionability blind. Blind-score every redirect.
8. Compute every measure below per run. Grade every hypothesis. Write it up whichever way it came
   out, in `ANALYSIS.md` in this directory, with the preregistered qualitative analysis.

## Measures, per run

Four properties of a finding are scored separately and never collapsed: factual correctness (the
adjudicated verdict), evidence quality (read-only, tool-corroborated, reproduced), severity (the
consequence rubric, blind), actionability (the 0 to 3 rubric from Experiment 001's protocol, blind).

Confirmed defects (strict rule). Consequential defects (high tier). False positives. Unsupported or
hedged findings. Evidence quality per confirmed finding. Hypothesis lifecycle (V3: formed, supported,
disproved with evidence, upgraded, stopped open; preserved in full). Upgraded findings. Disproved and
discarded. Load-bearing iteration (H2). Load-bearing redirects. Budget-limited outcomes (V3: at STOP,
supported-but-not-reproduced findings; unresolved hypotheses; un-upgradable evidence; `not_examined`
items never reached; each counted and compared against whether V2 or the other V3 runs found the
defect). Coverage per domain, and V3's `examined` versus `not_examined` at the final card. Duplicate
work. Manager integrity, syntactic (H3a) and semantic (H3b). Compute efficiency: tool calls, rounds,
redirects, output tokens, elapsed time, per investigator and per run; tokens per confirmed defect
per arm. Repeatability. Lane hygiene. Human adjudication: one judge blind to arm, verdicts open and
versioned in an append-only `findings/` directory here, corrections logged; a second judge if
resources allow.

## Preregistered qualitative analysis

Written now so it cannot be chosen after the data. (a) For every load-bearing redirect, the chain
from question to evidence to finding, read for whether the question was necessary. (b) For every
disproved hypothesis, whether the disproof was correct. (c) For every STOP, what was left and
whether another arm found it. (d) Round-0 cards against V2 reports on the same subject, for whether
the addendum changed what the charter looked at. (e) Five randomly chosen redirects per subject, read
beside the card they came from, for whether the cited field justified the question.

## Reporting

Per arm, per subject, per run. Declared-scope discipline as in Experiment 001. Nothing normalized
away. Causal claims limited to the bundle. The known subject and the primary-discovery subject in
separate tables, always. Hypotheses graded as sealed, including the ones that fail.

## What this experiment does not test

Thin roles. Full context versus state card. The manager alone. Boundary routing alone. Tool
discovery. Effort scaling. V1. Each is a deferred ablation in the design document.
