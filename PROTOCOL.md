# Protocol: single-agent review versus a role-specialized swarm

**Status:** v3, all design decisions closed. Registered 2026-09-17, before any review ran.
**Run by:** Chris Cruz. Personal project. No employer, customer, or internal material anywhere in it.

Written before the subject was built. Once the first review runs this does not change. Every change
after that goes in the deviation log with the date, the reason, and whether results had already been
observed.

---

## I. Study identity

| Field | Value |
| --- | --- |
| Working title | Five critics or one good prompt |
| Planning began | 2026-09-17 |
| Review system under test | `cruzbuilds/agentic-review-swarm`, pinned at the commit recorded before arm B runs |
| Subject application | `cruzbuilds/idea-log`, frozen at `v0-raw` = `b38c5b0dc51206bda7cd97fc27d0d252d6fd6a02` |
| Working copies | `idea-log-armA`, `idea-log-armB`, both forked from that tag |
| This repository | The study. Public from the start. |
| Configuration frozen before testing | Yes. If the swarm changes mid-study, the study restarts or each version is labeled and reported separately. |

## II. Problem statement

**The organizational problem.** Customers across industries say they cannot trust AI-written code and
do not want their development teams using AI coding tools. Generation is not the gap; the tools are
already good at it. The gap is assurance: nothing tells a risk owner what was checked.

**Definitions, fixed.**

- **Trust.** A decision-maker's willingness to permit AI-assisted development in their environment.
- **Assurance.** Evidence that a specific class of problem was looked for, by a stated rule, with a
  recorded outcome. Separate from defect detection. A review can find things and produce no
  assurance, and the reverse.
- **AI-generated code.** The frozen application, produced from one paragraph by a coding agent,
  unreviewed and unedited by a human.
- **Single-agent review.** One model session, one good general prompt, no roles.
- **Multi-agent review.** Five reviewers with written charters, run in parallel, merged into one
  verdict.

**Out of scope.** Whether AI should write production code. Vendor comparisons. Comparison against
human reviewers. Any claim about a population of applications.

**Claims this study will not make.** That the result generalizes beyond this application, model and
stack. That a difference in counts is statistically significant. That the swarm is safe to rely on
without a human.

## III. Research questions

**Primary.** On the same frozen commit, same model, same day, does the role-specialized swarm find
more valid defects across more quality domains than a single general reviewer, at an acceptable
precision rate?

**Secondary.**

1. Does the swarm produce assurance the single agent does not: a per-finding record tied to a written
   rule, including what was deliberately let through?
2. Which quality domains does each condition miss entirely?
3. What does each cost, in tokens and wall clock, per valid finding?
4. Do findings repeat across runs, or is either condition unstable?
5. Given each report, does a coding agent produce a better fix from one than the other?

**What matters most:** valid findings in domains the other condition missed, and whether either missed
a critical the other caught. Raw totals reward whichever condition talks more.

## IV. Hypotheses

> **H1.** The role-specialized swarm identifies more valid defects across more quality domains than
> the single-agent reviewer, while maintaining a precision rate within 10 points of it.

> **H0.** The swarm produces no meaningful improvement in valid findings, domain coverage, or
> actionability over the single-agent reviewer.

- **Expected advantage of specialization:** domains a general reviewer has no reason to
  prioritize, such as tests that cannot fail, documentation drift, teardown, scope.
- **Expected disadvantage:** duplication across agents, higher cost, and five chances to produce a
  false positive instead of one.
- **Where the single agent may do better:** whole-system reasoning that crosses lanes, and precision,
  since nothing pushes it to report something.
- **Expected cost difference:** the swarm costs multiples of the single agent. The number is unknown
  and is an output of the study.

## V. Success criteria

- **Primary metrics:** valid findings, precision, domain coverage, critical and high recall.
- **Secondary:** unique valid findings per condition, actionability, stability across runs, cost per
  valid finding, remediation quality.
- **Practically meaningful:** the swarm must produce **at least 5 valid findings the single agent
  missed, across at least 2 domains**, to be worth its cost. Below that, the honest recommendation is
  the single prompt.
- **The disqualifier, applied equally to both:** missing a critical the other condition caught is
  reported in the abstract regardless of who won on totals.
- **A higher count alone is not success.** 40 findings at 50 percent precision is worse than 20 at 90,
  because a person reads all of them.
- **Acceptable false-positive rate:** above 30 percent, a reviewer's credibility is the finding.
- **Statistics:** none. The sample is too small, and the paper says so rather than implying otherwise.

## VI. Method

### 1. Subject

Three-tier TypeScript web application: frontend, HTTP API, relational datastore, real authentication,
a real permissions surface. Generated from one paragraph, vibe-coded on purpose: no review, no
refactor, no hand-written tests. Writing it carefully would ruin the experiment.

The full specification (`APP-SPEC.md`) was written before generation and withheld from the builder. It
names features; it deliberately never names qualities like security, testing or documentation, because
those are what a fast build skips and asking for them would prompt away the phenomenon.

### 2. Generation record

Captured at run time, not reconstructed: tool, model, version, UTC times, tool permissions, every
prompt and answer verbatim, files touched, commands run, failures, retries, and any human action.
Tokens, cost, wall clock, active human time. See `sessions/01-build.md`.

### 3. Freeze

Commit exactly what exists, tag `v0-raw`, clean tree, lockfile committed. Both conditions review that
hash. Nothing changes between arms, including typos. A failing acceptance criterion is recorded, not
fixed.

### 4. Objective baseline

Free tools, run once against the frozen commit, raw output preserved in `baseline/`. This is the
floor: anything a scanner catches earns no credit for either condition, and the same output is the
corroboration source during adjudication.

### 5. Seeded defects

**None.** Planted defects are more obvious than natural ones, which flatters both conditions and
invites the objection that the test was rigged.

The cost: no true recall denominator. Recall is reported only against the union of what both
conditions found plus the baseline scans, and the paper states plainly that defects neither condition
found are invisible to this study.

### 6. Fairness between conditions

Identical: commit, repository documentation, ability to run the application and any commands,
dependency install, internet access, model, clean context, and cost budget. Neither sees the other's
output.

**Both run on Sonnet.** The swarm's Claude adapters pin `model: sonnet`, so arm B runs on Sonnet
regardless. Arm A therefore runs on Sonnet too, or the study measures Opus against Sonnet dressed up
as swarm against single.

### 7. Arm A, single agent

One session, one prompt, published verbatim in `ARM-A-PROMPT.md`, written to be a realistic strong
production prompt rather than a strawman. It names breadth by name, asks for absences as well as
defects, permits investigation, and requires the same output fields the swarm's contract requires.

### 8. Arm B, swarm

`scripts/review.sh` at the pinned commit, unmodified, with the empty tree hash passed as the range so
the diff is the entire repository. The subject has one root commit and no main branch, so the runner's
default range would have been meaningless. See `DEVIATIONS.md` D-002. Every agent's raw output preserved as well as
the merged report, including anything the orchestrator dropped during consolidation.

### 9. Four lanes, not five

The swarm's `scope-reviewer` holds a change against an engagement folder and decision records. The
subject has neither, because it was generated from one paragraph, which is exactly the kind of
repository this swarm would meet in the wild. Per its charter the agent reports that and returns PASS.

Supplying the specification to both arms would give that lane something to check, and was rejected:
the specification lists security, tests and documentation as requirements, so supplying it hands both
reviewers a checklist and destroys the study's sharpest prediction.

**So four of five charters are under test, and the study says so.** The fifth returning PASS for lack
of a scope document is reported as a finding about the swarm rather than hidden: it depends on process
artifacts that fast-generated repositories do not have.

### 10. Repeated trials

**3 runs per condition**, run IDs assigned before execution. Amended on 2026-09-18, before any run,
from alternating to **parallel pairs**: A1 with B1, then A2 with B2, then A3 with B3. Both arms in a
pair start in the same second, which controls for drift better than alternating did. See
`DEVIATIONS.md` D-001. Both
conditions are non-deterministic; one run each measures a sample and calls it a result. All runs
preserved including failures.

Stability across runs is a reported metric in its own right. A reviewer that finds different things
every time is a different product from one that does not, and almost nobody publishes this.

### 11. Finding schema

One row per finding: ID, condition, run, source agent, title, domain, claimed severity, file, line,
description, failure scenario, impact, evidence, reproduction, remediation, confidence, duplicate
group, corroboration source, validation status, adjudicated severity, adjudicator note.

### 12. Classification rules, frozen before scoring

| Verdict | Means |
| --- | --- |
| True positive | The code exists as described, the failure can occur, a person would fix it |
| False positive | Wrong, already prevented elsewhere, or true but not a problem |
| Partially correct | Real issue, wrong location, severity or mechanism |
| Duplicate | Same defect, same condition. Collapses to one. Cross-condition matches are overlap, not duplicates. |
| Unverifiable | Cannot be confirmed from the code. Counted separately, never in totals. |
| Informational | True, no action implied |
| Out of scope | Real, but excluded by the specification |

**Actionability, 0 to 3:** 0 vague, 1 investigable, 2 located and explained with a direction, 3
evidence plus reproduction plus a technically sound fix. Frozen with examples before scoring.

### 13. Adjudication

I built one of the conditions and I am judging both. That cannot be removed, so it is constrained
four ways, all published.

**(a) The tool-corroborated subset is the headline.** Every finding records how it was corroborated: a
`tsc` error, an eslint rule, an audit advisory, a failing test, or a runnable reproduction. Those are
counted separately and reported first. That number does not depend on my opinion.
Author-judged findings are reported second, labeled.

This also handles the language problem. I am learning TypeScript, so nothing counts as a true
positive on my reading alone. Anything I cannot corroborate and cannot confidently judge goes to
**unverifiable**, reported separately, never in totals.

**(b) Blinded, arm A first.** Labels stripped, findings shuffled, arm A's list scored in full before
I open arm B's.

**(c) An independent second judge.** Adjudication runs again on a model that is not the one used in
either review condition. Its verdicts publish beside mine, and the disagreement rate is a
published result. Where we disagree, both calls stay visible and mine stands, marked
disputed. At least 20 percent of the second judge's verdicts are hand spot-checked.

**(d) Open verdicts, versioned.** The full dataset with every verdict and its evidence is published.
Anyone can challenge one. Changed verdicts are logged with the date, the challenge and the reason.

Every adjudication needs evidence: the code exists, the failure can occur, no existing control already
prevents it. Scanner output alone proves existence, not severity.

### 14. Remediation arm

Same coding model, two identical copies of the frozen application, identical prompt except for which
report is attached. The agent may reject findings but must say which and why.

Measured: valid findings correctly fixed, invalid findings acted on anyway, regressions introduced,
whether the build still passes, cost per correct fix, and whether a critical present in one report and
absent from the other survived into the fixed build.

### 15. Nothing is deployed

The study is a static review of a repository. No cloud account, no credentials given to any agent at
any stage.

This costs nothing: every infrastructure artifact is reviewable as code with the repository sitting
still. It is also more honest, since both reviewers are reading a repository, which is what a reviewer
does, and neither is advantaged by running the system.

What the builder produced for deployment, or failed to produce, is a finding rather than a constraint.
The build prompt says nothing about deployment.

A demo deployment may happen later, by hand, on a fixed-cost host, from the remediated build. It is
not part of this study and its outcome does not appear in the results.

## VII. Deviations, confounds, failures

**Deviation log.** Every departure from this protocol: date, change, reason, who decided, whether
results were already observed, which runs are affected, effect on interpretation.

**Confounds being watched:** unequal tool permissions, unequal budgets, one condition seeing more
documentation, swarm agents duplicating each other, a weak arm A prompt, an application too clean or
too broken, model updates mid-study, non-determinism, adjudicator bias, my TypeScript
inexperience, the same model as reviewer and judge, and excluding failed runs.

**Failure log.** Crashes, context limits, rate limits, malformed reports, hallucinated files,
contaminated runs. Nothing deleted for being inconvenient.

## VIII. Publication package

Protocol, preregistered hypotheses, application specification, every prompt, the frozen commit, arm A's
prompt, the swarm version and every charter, raw output from every run, the normalized findings
dataset, the adjudication rubric and finding-level decisions from both judges, the disagreement set,
metric scripts, cost and timing data, remediation prompts and commits, reproduction instructions,
deviation and failure logs, limitations, license, verdict changelog.

Negative and neutral results included. Failed runs disclosed. Preplanned metrics separated from
anything exploratory. Labeled a preprint and a personal project.

## IX. Steps

1. Write the application specification. Commit it. **Done.**
2. Generate the application from one paragraph. Record everything. Do not review it. **Done.**
3. Freeze, tag `v0-raw`, run the objective baseline. **Done.**
4. Write and commit predictions. **Done, publicly, before any review.**
5. Runs, alternating: A1, B1, A2, B2, A3, B3.
6. Normalize. Adjudicate blind, arm A first. Run the second judge. Publish the disagreement set.
7. Compute metrics, tool-corroborated subset first. Grade the sealed predictions.
8. Remediation arm.
9. Publish everything, whichever way it came out.

## Decisions closed 2026-09-17

| Question | Decision |
| --- | --- |
| Runs per condition | 3 each, alternating |
| Seeded defects | None. Recall reported against the found-union plus baseline, limitation stated. |
| Remediation arm | In |
| Adjudication | Author judges blinded, arm A first. Tool-corroborated subset is the headline. Second judge on a different model, disagreement published. Verdicts open and versioned. |
| Stack | TypeScript throughout |
| Model | Sonnet for both arms, because the swarm's adapters pin it |
| Scope lane | Four of five charters under test. The inert fifth is reported as a finding. |
| Deployment | None. Static review only. No credentials to any agent. |
| Missing a critical | Reported in the abstract regardless of totals, for either condition |
