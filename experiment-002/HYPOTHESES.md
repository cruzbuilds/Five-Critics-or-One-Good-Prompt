# Experiment 002: hypotheses, sealed

**Written 2026-09-19, after V2 was frozen at tag `v2.0-baseline` (`9d4d365` in
[agentic-review-swarm](https://github.com/cruzbuilds/agentic-review-swarm)) and the V3 design was
reviewed (`fa4a5a8` on `v3/agentic-investigation`), and BEFORE any instrumented V2 baseline run,
before the primary-discovery subject was chosen, and before a line of V3 was implemented.**

Committed to git before any of those. Never edited afterwards. Whatever these get wrong stays wrong
and gets reported. Corrections, if any are ever needed, go in `DEVIATIONS.md` in this directory, not
here.

## The question

Does giving the V2 reviewers iterative investigative autonomy, dynamic selection from a known tool
set, state-card resumption, and manager-directed follow-up produce better-supported findings than
the one-pass V2 workflow, and at what cost?

## What I knew when I wrote these

- Everything in Experiment 001, including the known subject's 79 adjudicated claims and which
  defects V1 missed. That is the contamination the protocol declares for the known subject.
- The V2 evaluation record: systems-reviewer 5 of 5 interaction seeds, arbiter 17 of 17, integrated
  45 of 49 mechanical with 0 implementation failures. No V2 run on a real pull request. No V1
  versus V2 comparison.
- Arm C's instrumented one-pass numbers: 10 to 13 tool calls and 10k to 14k output tokens per pass.
  No per-reviewer instrumentation of V2 yet; that is the first thing the protocol does.
- The V3 design, revision 3, in full, including the budgets it proposes.

I have not seen the primary-discovery subject. It has not been chosen.

## What is held constant, so a difference means something

The model. The six reviewer charters, verbatim. The two shared contracts. The tool registry and its
permission scoping. The subject and its hash. The description of the change given at round 0. The
arbiter and its rules. The output format. The judge, the rubrics, and the adjudication procedure.

## What is bundled inside the treatment, so a difference means only this much

Iterative rounds; investigator-controlled tool selection across rounds with a stated hypothesis;
state-card resumption; the manager's CONTINUE / REDIRECT / COMPLETE / STOP decisions;
boundary-question routing through the manager; additional evidence gathering after round 0; the
investigation addendum itself. A difference between arms is attributable to this bundle and to
nothing narrower. No hypothesis below claims otherwise.

## The hypotheses

All are per run, per subject, unless stated. The known subject (`idea-log` at `b38c5b0`) and the
primary-discovery subject are graded separately and never pooled.

| # | Hypothesis | Fails if |
| --- | --- | --- |
| H0, the null | Round 0 with every investigator COMPLETE reproduces V2: every measure in the protocol is within noise of V2's on the same subject. | It holds. If H0 holds, the answer to the question is no, on these subjects, and that is published. |
| H1 | V3 produces more confirmed defects at evidence quality *reproduced* or *tool-corroborated* than V2, per run. | V3 ≤ V2 on the primary-discovery subject. |
| H2 | Iteration is load-bearing: on the primary-discovery subject, in at least two of three runs, at least one confirmed defect is absent from every round-0 card of that run and present in that run's final report. The "absent from round 0" test is per run; a defect on round 0's card in one run does not count for another. | Fewer than two of three runs. |
| H3a, syntactic | Zero redirects name a suspected defect, by a human reading the manager log. The guardrail. | One does. |
| H3b, semantic | Under blind scoring of every redirect (0 neutral evidence or coverage question, 1 somewhat suggestive, 2 clearly implies a particular suspected defect), no redirect scores 2 and the mean is below 0.5. The measurement. | Any 2, or mean ≥ 0.5. |
| H4 | Compute is bounded: V3's output tokens per confirmed defect are no more than three times V2's, per subject. **3x is a preregistered engineering acceptability threshold, not a natural boundary**: the most this project will pay for a review that runs on every pull request, chosen before data. | Above 3x, regardless of H1. If V3 exceeds it and finds what V2 missed, H4 failed as preregistered and the number is argued afterward, in that order. |
| H5 | Boundary routing does not anchor: findings whose evidence chain includes a boundary question are confirmed at a rate within ten points of findings that do not. | Otherwise. |
| H6 | The investigation addendum does not change the lane: out-of-lane findings per report are within one of V2's, and round-0 cards cover the same files as V2's reports on the same subject. | Otherwise. |
| H7 | Repeatability does not collapse: the share of confirmed findings seen in all three runs is within ten points of V2's, per subject. | Otherwise. |
| H8 | Budget exhaustion is not the dominant terminator: fewer than a third of investigations end by mandatory STOP, and no confirmed defect found by V2 is left as a budget-limited outcome in V3 in two or more of three runs. | Otherwise, which means the budgets decided the result; the experiment is rerun with revised budgets, logged as a deviation, before anything is concluded. |

Every numeric threshold above that is a judgment call (H3b's 0.5, H4's 3x, H5's and H7's ten
points, H8's one third) is chosen before data and labeled so. None is presented as something the
data found.

## What I expect, written so it can be wrong

I expect H2 to be the hypothesis most likely to fail, because the V2 charters already tell a
reviewer how to work and a well-charted reviewer may reach its evidence in one pass. I expect H4 to
be close. I expect H3b to pass on the letter and be the most interesting thing to read afterward. I
expect the known subject to show smaller differences than the primary-discovery subject, because
V2's reviewers were evaluated against fixtures built from what that subject taught us. I would not
put a number on any of it.

## Predictions I did not make

Absolute counts per arm. Which domain moves most. Whether the manager or the investigators' own tool
choice carries any effect (the design cannot separate them, and neither can I). Whether V3 beats V1;
V1 is not an arm.
