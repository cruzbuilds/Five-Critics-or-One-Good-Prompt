# Experiment 001: independent re-analysis

**Date:** 2026-09-19
**Basis:** the underlying files only. `findings/adjudication-key.json` (77 distinct claims with the
arm, condition and run each was seen in), `findings/evidence-0*.json` (per-claim verdicts against the
frozen commit), the four raw extraction CSVs, the twelve raw reports, and the source at `v0-raw`.
The earlier report narrative was treated as one interpretation and not assumed.

**A correction first.** The earlier headline said the swarm found "nearly twice" what the single
reviewer found in shared scope. That compared the two unique-to-arm counts (28 against 16) and read
them as totals. The totals are 42 against 30, which is 40% more. The headline was wrong. Everything
below is recomputed from the files.

---

## Definitions used throughout

**Claim.** One distinct defect after de-duplication across runs, arms and conditions. 77 in total.

**Verdict.** Each claim was checked against the code. `yes`: the code is as described. `partly`:
the problem is real but something in the claim is off, usually the line number. `no`: the premise is
false. Separately, `already prevented elsewhere` marks a claim that is true of the named file but
whose failure cannot occur because another part of the system prevents it.

**Precision** is reported three ways, because the choice changes the number and the reader should
see all three: lenient (`yes` + `partly`), strict (`yes` + `partly`, minus already-prevented), and
`yes` only.

**True positive (TP)** below means the strict definition unless stated: the code matches and no
existing control prevents the failure. 62 of 77 claims.

**Coverage, not recall.** There are no seeded defects and no ground truth, so recall cannot be
computed. What is reported is each system's share of the union of true positives that either system
found. Defects that neither found are invisible to this study. That is a coverage figure relative to
the other system, and it is called that here.

**Shared scope.** Security, tests, documentation, infrastructure, dependencies. The five domains
where the swarm has a charter and the single reviewer's prompt names the domain. Correctness is named
in the single reviewer's prompt only; the swarm has no correctness agent by design (ADR 0004).
Performance and accessibility were named by neither.

---

## 1. Shared-scope comparison

### All claims that were not outright wrong (lenient)

| | Single only | Both | Swarm only | Single total | Swarm total | Union |
| --- | --- | --- | --- | --- | --- | --- |
| Shared scope | 16 | 14 | 28 | **30** | **42** | 58 |

- Swarm total is 1.40 times single total, so **40% more**, not twice.
- Overlap (Jaccard, both over union): **24%**.
- Unique contribution to the union: single 28%, swarm 48%.
- Share of each system's own list that the other never found: single 53%, swarm 67%.

### Strict true positives only

| | Single only | Both | Swarm only | Single total | Swarm total | Union |
| --- | --- | --- | --- | --- | --- | --- |
| Shared scope | 13 | 11 | 24 | **24** | **35** | 48 |

Swarm total is 1.46 times single, **46% more**, on the stricter definition.

## 2. Where the advantage comes from

Strict TPs, per domain. `so` single only, `bo` both, `wo` swarm only.

| Domain | so | bo | wo | Single total | Swarm total | Union | Declared by |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Tests | 0 | 1 | 12 | 1 | **13** | 13 | both |
| Security | 5 | 6 | 1 | **11** | 7 | 12 | both |
| Infrastructure | 5 | 2 | 6 | 7 | 8 | 13 | both |
| Documentation | 2 | 0 | 5 | 2 | **5** | 7 | both |
| Dependencies | 1 | 2 | 0 | 3 | 2 | 3 | both |
| Correctness | 8 | 3 | 0 | **11** | 3 | 11 | single only |
| Performance | 2 | 0 | 0 | 2 | 0 | 2 | neither |
| Accessibility | 1 | 0 | 0 | 1 | 0 | 1 | neither |

**The swarm's shared-scope advantage is the test reviewer.** Twelve of its 24 swarm-only
shared-scope TPs are test gaps: 50%. Remove tests from shared scope and the totals are 23 against
22, which is parity. The swarm also leads on documentation, 5 to 2, but the single reviewer leads on
security, 11 to 7, and those roughly cancel.

So the accurate claim is narrow: **a dedicated test reviewer dramatically improves detection of
test gaps, and the rest of the swarm roughly matches one well-prompted generalist.** "Specialization
improves coverage" is not what this data says.

There is a second, quieter pattern. The single reviewer beat the security agent 11 to 7 inside the
security agent's own lane. The domain with the most focused charter and the most tooling was won by
the generalist. That is worth its own experiment.

## 3. Precision

| System | Scope | n | yes | partly | no | prevented elsewhere | lenient | strict | yes only |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Single | global | 47 | 37 | 9 | 1 | 8 | 98% | 81% | 79% |
| Single | shared | 31 | 25 | 5 | 1 | 6 | 97% | 77% | 81% |
| Swarm | global | 48 | 38 | 10 | 0 | 10 | 100% | 79% | 79% |
| Swarm | shared | 42 | 32 | 10 | 0 | 7 | 100% | 83% | 76% |

Precision is the same within a few points under every definition. One claim in 77 was outright
wrong, and it was the single reviewer's: it said Next 16 conventions were unverifiable while
`node_modules` was present and every convention checked out.

**What `partly` meant.** Read the notes for all 19 partly verdicts. Every one is a real problem with
a defect in the citation: wrong line, wrong file for one half of a bundled claim, a count of 13 given
as 10. None was an overstated impact. None was a fabrication. The two arms' partly rates are the
same, 9 of 47 and 10 of 48, and the reasons are the same kind. There is no systematic difference in
how the two systems are wrong.

**What `already prevented` meant.** Fifteen claims describe a real weakness in the named file whose
failure something else blocks. Example: `jwtVerify` is unpinned (C19, both arms), but `getSecretKey`
returns a `Uint8Array`, so jose restricts verification to HMAC and algorithm confusion is not
available. These are counted as false positives under the strict definition because a maintainer
acting on them would be fixing something that cannot fail today. They are also exactly the kind of
defence-in-depth note a careful reviewer makes, which is why the lenient figure is reported beside it.

## 4. Repeatability

Strict TPs, per system per condition. "Seen 3" means the same defect appeared in all three runs of
that condition.

| System | Condition | TPs | Seen once | Seen 3 of 3 | TPs per run | Range |
| --- | --- | --- | --- | --- | --- | --- |
| Single | no tools | 33 | 12 (36%) | 15 (45%) | 25, 22, 22 | 3 |
| Single | tools | 32 | 8 (25%) | 14 (44%) | 20, 23, 27 | 7 |
| Swarm | no tools | 30 | 6 (20%) | 18 (60%) | 24, 22, 26 | 4 |
| Swarm | tools | 32 | 5 (16%) | 21 (66%) | 25, 27, 28 | 3 |

The swarm repeats itself more. Roughly two thirds of what it finds it finds every time; the single
reviewer is under half. Per-run TP counts are similar between systems (means 23 to 27); the
difference is in which findings recur, not how many.

Of the 24 unique-to-single TPs, 7 were seen exactly once across all six single runs. Of the 24
unique-to-swarm TPs, 6 were seen once, and 11 were seen in all six swarm runs. **The swarm's unique
findings are mostly things it finds every time. The single reviewer's unique findings are more often
one-offs.** For a team running this in CI, that is the number that matters: a reviewer that finds a
defect once in three runs has a one-in-three chance of catching it on the run that ships.

The specialist agents did consistently find their important issues. Every one of the nine
per-module test gaps was seen in all six swarm runs.

## 5. Tools versus no tools

Strict TPs per system.

| System | No tools | Tools | In both | Only no-tools | Only tools |
| --- | --- | --- | --- | --- | --- |
| Single | 33 | 32 | 27 | 6 | 5 |
| Swarm | 30 | 32 | 24 | 6 | 8 |

Tools changed almost nothing for either system. The single reviewer gained 5 and lost 6; the swarm
gained 8 and lost 6. Neither gained coverage; both swapped a handful of findings.

Of the 13 tools-only TPs across both systems, **one** required a tool: the `pnpm audit` advisory,
found by both, already in the baseline. Everything else was reading. The clearest single instance of
tool value is the single reviewer running a bcrypt timing benchmark and a 72-byte truncation
reproduction in the tools condition, which turned a code-read claim into a demonstrated one. That is
a quality improvement, not a coverage one.

Repeatability moved in the swarm's favour with tools, 60% to 66%. That may be noise at this sample.

**Why tools did so little.** The subject has no tests to run, no Terraform, no Dockerfile, no CI. Three
of five swarm agents had instruments with nothing to point them at. `checkov` failed in all three
runs trying to reach `api0.prismacloud.io`. The tools condition measures "tools on a repository that
mostly cannot use them," and that is a limitation of the subject, not a finding about tools.

## 6. Correctness as a coverage boundary

- Correctness TPs in the union: 11. Single found all 11. The swarm found 3, all also found by the
  single reviewer. Single-only: 8.
- Practical total coverage across all domains: **single 38, swarm 38**, of a union of 62. The two
  systems found the same number of true things; they found different things.
- The absence of a correctness agent costs the swarm 8 of the 62 TPs in this study, 13%, and it
  costs the specific finding that matters most (section 9).

**What the data shows about the gap, without inventing what a new agent would find.** The swarm did
not fail to notice correctness problems. In two of six runs it noticed C26, the calibration-corruption
defect, and routed it to "Handoffs nobody picked up" with the note "no agent in the roster owns
this." The observation existed. The architecture had nowhere to put it. That is stronger evidence for
adding a correctness reviewer than a miss would have been, because it shows the capability is present
and the charter structure is what discards it.

## 7. Out-of-scope discovery

The single reviewer produced three TPs in domains neither system was asked about:

- C43, unbounded reads with no pagination, seen in **6 of 6** single runs
- C74, accessibility gaps in the score picker and forms, seen in 3 of 6
- C48, duplicate query on the share page, seen in 1 of 6

Under the controlled comparison these are excluded, and the tables above exclude them. Under
practical usefulness they are real defects a team would want, and one of them recurred every time,
so it is not luck. The swarm produced zero, and cannot: every charter ends with a list of things that
agent must not comment on, and an out-of-lane observation is required to be handed off rather than
reported. The generalist has no lane, so it wanders, and here wandering paid. Whether that is
"serendipity" or "unpredictability" depends on whether you are the person reading the report or the
person building CI around it. The data supports calling it a real property the specialist design
gives up. It does not support calling it better cross-domain reasoning; three findings is too few.

## 8. Qualitative analysis

### Themes

Each of the 62 strict TPs was assigned one theme from its title and description, before looking at
which arm found it.

| Theme | Single | Swarm | Only single | Only swarm | Both |
| --- | --- | --- | --- | --- | --- |
| Security vulnerability | 11 | 7 | 5 | 1 | 6 |
| Correctness / business logic | 11 | 3 | 8 | 0 | 3 |
| Missing test | 1 | 13 | 0 | 12 | 1 |
| Missing documentation | 2 | 5 | 2 | 5 | 0 |
| Operational readiness | 6 | 6 | 4 | 4 | 2 |
| Config / hygiene | 4 | 4 | 2 | 2 | 2 |
| Performance | 2 | 0 | 2 | 0 | 0 |
| Accessibility | 1 | 0 | 1 | 0 | 0 |

**Deeper or more granular?** More granular, and the granularity is the value. The single reviewer
said "no tests, no test script, no CI" once per run and moved on. The swarm's test reviewer produced
thirteen items, each naming a module and the assertions to write: "test that user B gets 404 from
GET, PATCH, DELETE and outcome PATCH on user A's idea, and that A's idea is unchanged." A developer
can start on that tomorrow. "Add tests" is true and not a task. Whether thirteen rows or one is the
better *report* depends on the reader; the thirteen are the better work list.

**Broader or cross-cutting?** Yes, the single reviewer. Its highest-value unique finding, C26, is a
cross-cutting one: it connects the update schema, the PATCH handler, and the calibration filter to
show that the product's core promise can be silently falsified. No single-lane agent is positioned to
make that connection, and the data shows the swarm's agents making it and having nowhere to file it.
The single reviewer also produced bundled findings, like C27, which ties a registration race, a
missing-secret crash and a swallowed error into one error-handling story. Those bundles cost it on
citation precision (several `partly` verdicts are bundles where one half was cited wrong) and gain it
on conceptual coherence.

**Fragmentation.** The swarm's reports do fragment. A single "no tests" observation becomes thirteen
rows. In the no-tools condition the swarm also reported the same Postgres exposure from two agents at
two different line numbers, and the orchestrator flagged the discrepancy itself. That self-reporting
of disagreement is a feature of the design and it is also more text to read.

**Actionability.** The swarm's findings are more actionable on average, driven by the test items and
by the contract's requirement that every finding name a file and a line. The single reviewer's
findings are more often conceptual and more often bundled, which is why its `partly` verdicts cluster
on wrong-file-for-one-half.

**Evidence precision.** Similar. Both cite file and line. The swarm's contract forces it; the single
reviewer's prompt requested it and it complied. The tools condition let the single reviewer add
executed evidence (the bcrypt benchmark) that no swarm agent produced.

**Redundancy.** The swarm produces more redundant text: cross-agent duplicates, per-agent tool notes,
disagreement notes. The single reviewer produces fewer, longer items. Neither was scored for report
length here and it should be in Experiment 002.

**Structural blind spots.** Both have them and they are mirror images. The swarm cannot report
correctness, performance or accessibility, and the data shows it noticing and discarding. The single
reviewer cannot produce a per-agent account of what was checked and what could not be run; the swarm
produced one in every run, listing tools that ran, tools that failed, files not read, and agents that
disagreed. That account is the assurance artifact the study registered as a secondary question, and
it exists in one column only.

### Practical value

Rubric, fixed before applying, applied from title and description without looking at the arm:

- **High.** Exploitable in production, or silently corrupts user-facing data or the product's core
  function. Would block a merge on any real team.
- **Moderate.** A real defect in reliability, security posture, operations or maintainability that
  should be fixed before production but does not cause immediate harm. Includes missing tests for
  critical paths, since an untested ownership check is a latent high.
- **Low / hygiene.** Style, documentation polish, configuration tidiness, informational.

| Value | Single total | Swarm total | Only single | Only swarm | Both | n |
| --- | --- | --- | --- | --- | --- | --- |
| High | 4 | 3 | 1 | 0 | 3 | 4 |
| Moderate | 19 | 23 | 11 | 15 | 8 | 34 |
| Low / hygiene | 15 | 12 | 12 | 9 | 3 | 24 |

The four high-value findings: the placeholder `JWT_SECRET` that passes validation (both, 12 of 12
runs), no rate limiting with pure-JS bcrypt as a CPU-exhaustion vector (both, 12 of 12), sessions
that cannot be revoked (both, 10 of 12), and **predictions rewritable after the outcome, corrupting
calibration (single only, 5 of 6 single runs, handed off to nobody by the swarm in 2 of 6).**

Both systems found every high-value security defect every time. The one high-value defect found by
only one system is a correctness defect, and it is the reason the single reviewer's practical
coverage equals the swarm's despite the swarm's 40% shared-scope advantage.

This rubric is one person's judgment on 62 items and should be treated as such. It was not adjusted
after seeing the split.

## 9. Confounders and weaknesses

**Internal validity**

- **Prompt scope is not symmetric.** The single reviewer's prompt names correctness; the swarm has
  no correctness agent. The shared-scope tables handle this. The practical-coverage figures do not,
  and should not.
- **The single reviewer's prompt was written by someone who knows the charters.** It names breadth
  explicitly and asks for absences. It is a strong prompt, deliberately, so arm A could not lose
  unfairly. The cost is that the "one prompt" arm carries the swarm's thinking compressed. A naive
  prompt was not tested. This is the largest confound in the study and it cuts against the swarm.
- **Adjudication was assisted by agents, not blind to the author, and the author built one arm.**
  Evidence gathering was done blind to arm. Verdict rules were fixed before scoring. The practical
  value rubric was applied from titles. None of that removes the conflict; it constrains it.
- **Domain granularity.** The swarm's test reviewer reports per module; the single reviewer reports
  once. De-duplication kept them as separate defects because they name separate untested modules.
  Collapsing them would remove most of the swarm's shared-scope lead. Keeping them is defensible
  because each is a separately actionable item, but a reader who disagrees would get parity.
- **Harness leakage.** The single reviewer reported the experiment's own `.claude/settings.json` as
  a defect in all three tools runs; the swarm was told to ignore `.claude/`. Excluded from all
  counts. Recorded in `DEVIATIONS.md`.
- **Tool access was denied in condition 1 and only partly usable in condition 2.** Recorded.
- **Non-determinism.** Three runs per condition describe variance; they do not support inference.
  No statistical test was run and none should be claimed.

**External validity**

- One application, one language, one model, one author, one week. Nothing here supports a claim
  about multi-agent review in general.
- The subject has no tests, no infrastructure code and no CI, so the test and infra agents were
  measured on their ability to notice absence, not to review presence. A subject with an existing
  test suite might invert the test result: the single reviewer said "add tests" once; whether it
  would find *tests that cannot fail* is untested.
- The subject was vibe-coded from one paragraph and reviewed by nobody before the study. Findings
  on a mature codebase would be fewer and harder.

## 10. What the evidence supports

**Strongly supported**

- The two systems have similar precision. 81% and 79% strict, within noise, and one outright wrong
  claim between them.
- The two systems are complementary. 37% agreement; each found 24 true positives the other did not;
  practical total coverage is 38 and 38 of a union of 62.
- The swarm's shared-scope advantage is produced by the test reviewer. 12 of 24 swarm-only TPs are
  test gaps; without tests, shared scope is 23 against 22.
- The swarm is more repeatable. 60% to 66% of its TPs recur in all three runs against 44% to 45%.
- The swarm's charter structure discards observations it makes outside its lanes. Demonstrated
  directly: C26 noticed in two runs and filed under "nobody owns this."
- The single reviewer beat the security agent inside the security lane, 11 to 7.
- Tools did not materially change coverage for either system on this subject.

**Suggestive**

- The generalist produces out-of-scope findings of real value. Three TPs, one of them recurring in
  every run. Too few to characterise as a general property.
- Specialist output is more actionable per item. Consistent with the reports read; not scored with
  the registered actionability rubric, which should be done.
- The single reviewer's unique findings are more often one-offs, 7 of 24 seen once against 6 of 24,
  with 11 of the swarm's seen in every run. Direction is clear; the gap is small.

**Not supported**

- "The swarm finds nearly twice as many defects." Wrong. The earlier report's error.
- "Specialization improves defect coverage." Not as a general claim. One specialist improved one
  domain; the rest matched a generalist.
- "Multi-agent review is superior to single-agent review." Total practical coverage is equal and the
  generalist found the most valuable single defect.
- "Similar precision but substantially different recall." Recall cannot be computed. Coverage
  relative to the union is equal overall and differs by domain in both directions.
- "Better cross-domain reasoning." Three findings.

**Supported with the stated qualification**

- "The swarm finds approximately 40% more defects within equivalent review scope." True, 30 to 42
  lenient or 24 to 35 strict, and 50% of that margin is test gaps, and the generalist's prompt was
  written by the swarm's author.
- "The current swarm is missing an important correctness-review capability." Supported by 8
  single-only correctness TPs including the highest-value finding in the study, and by the swarm's
  own handoff notes saying nobody owns it.

## 11. How I would write it

**Primary quantitative finding.** On one vibe-coded application, a five-agent specialist swarm and
a single well-prompted generalist reviewer found the same number of confirmed defects, 38 each of 62,
with the same precision, around 80%, and only 37% agreement on which. The swarm found 40% more within
the five domains both were assigned, and half of that margin is one agent, the test reviewer. Outside
tests the two were at parity.

**Most important qualitative finding.** The specialist design trades breadth for repeatability and
actionability. The swarm found the same things every time, named the module and the assertion, and
produced a per-agent account of what was checked and what could not be run. The generalist found the
single most consequential defect in the codebase, a cross-cutting logic flaw that lets users falsify
the product's core metric, and the swarm noticed the same flaw in two runs and filed it under "nobody
owns this." Both facts are about the same design decision.

**Most important limitation.** The generalist's prompt was written by the swarm's author, after
weeks inside the charters, and names every domain the swarm covers. This experiment compares a
specialist swarm against a generalist who was handed the map. A naive prompt was not tested, and
that is the comparison most people actually make.

**Most surprising finding.** Tools barely mattered, and the security agent, the most instrumented
specialist, was out-found in its own lane by the generalist, 11 to 7.

**Architectural implication.** The lane rule is doing two jobs and they conflict. It keeps the
merged report readable and it throws away cross-cutting observations. The data points at adding a
correctness or application-logic reviewer, and at reconsidering whether "hand off to nobody" should
exist as an outcome. A hybrid, one generalist pass plus specialists on the lanes where they
demonstrably win, is the obvious next design and it is not the one that was built.

**Experiment 002.** Three changes, one at a time. First, a naive prompt as a third arm, one sentence,
to find out whether the generalist's performance came from the model or from the prompt. Second, a
subject that has tests, infrastructure code and CI, so the test and infra agents are measured on
reviewing what exists rather than noticing what is missing. Third, score every finding with the
actionability and documentation-quality rubrics already in the protocol, which were registered and
never used. Do not add the correctness agent yet; measure the gap it would fill first.

---

Every number above can be regenerated from the files in `findings/` with the scripts in the session
record. Verdicts are open. If one is wrong, the correction goes in `findings/corrections.csv`.
