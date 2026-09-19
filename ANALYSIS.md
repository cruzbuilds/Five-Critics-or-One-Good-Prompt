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

## 9b. The prompt, line by line

This is the whole input arm A received, from `prompts/arm-a.txt`, with what each part did.

> You are reviewing a web application before it goes to production. Read the repository thoroughly:
> the source, the configuration, the database schema and migrations, the dependency manifest and the
> documentation. Report everything wrong with it.

Sets the job and names the artifacts to read. Neutral.

> Be comprehensive. Consider correctness, security, authentication and authorization, data handling,
> input validation, error handling, dependencies, database design, infrastructure and deployment
> configuration, tests, and documentation.

**This is the swarm's domain list plus correctness, in one sentence.** Security, tests, docs, infra,
dependencies are the five charters. I wrote it after weeks inside those charters, and I wrote it this
way deliberately so arm A could not lose for never having been told where to look. The consequence is
that the "single prompt" carries the swarm's structure compressed into it.

> Consider what is missing as well as what is present: an absent safeguard, an untested path, or an
> undocumented requirement is a finding.

**This sentence is why prediction 5 failed.** The prediction was that a generalist would not notice
an absent test suite. This line tells it to look for absences. It noticed in six of six runs.

> You may run commands to investigate. Do not change any file.

Same tool grant as the swarm, by design.

> For every finding, give: a short title; the severity; the file and line; what is actually wrong;
> the concrete failure it allows; how to fix it.

**This is `shared/output-format.md` restated.** The swarm's own contract. Arm A produced swarm-shaped
findings because it was asked to.

> Group the findings by severity, most severe first. If you are unsure whether something is a real
> problem, include it and say what you would need to confirm it. If you checked something and it was
> fine, do not list it.

The last sentence is the anti-padding rule, and it is the likely reason arm A's precision matched
the swarm's instead of falling below it.

**What this means for the comparison.** The experiment did not test a specialist swarm against what
a developer types. It tested five agents holding the charters separately against one agent holding
the charters summarised into a paragraph, by the person who wrote them. On this subject, outside the
test lane, the paragraph did the same work as the five agents. That is consistent with the study's
own thesis, that direction is what converts capability into evidence, and it says the direction
compresses further than the swarm's design assumed.

The comparison the study set out to make, specialists against a naive "review this code," is arm C.
It is one sentence and it has not been run.

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

---

# 12. Arm C: the goal without the map

**Added 2026-09-19, after the A/B results above were observed and analysed. Exploratory follow-up
evidence. Not part of the preregistered comparison. No prediction in `PREDICTIONS.md` is about it,
none was added, and no A/B verdict was revisited. See `DEVIATIONS.md` D-005.**

## 12.1 What ran

The whole prompt, from `prompts/arm-c.txt`:

> Review this repository as if it were about to go into production. Find anything you think should
> be fixed or investigated before it ships.

Three runs, launched in parallel from three terminals, each in a fresh scratch clone of the sealed
`idea-log` at `b38c5b0`, same `.claude/settings.json` and flags as the A*.2 and B*.2 runs, one
message, no follow-up. Model `claude-sonnet-5` as reported by the harness in every run.

| Run | Wall | Tool calls | Failed | Output tokens | Cost | Report words |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | 216 s | 12 | 0 | 13,558 | $0.37 | 1,042 |
| C2 | 188 s | 13 | 0 | 12,870 | $0.36 | 1,199 |
| C3 | 171 s | 10 | 0 | 10,361 | $0.30 | 877 |

For scale, the A*.2 reports are 2,176 to 2,901 words and the B*.2 reports 1,708 to 2,136. A and B
were not instrumented for tokens or cost; those columns exist for C only and compare to nothing.
Wall time is not comparable either: the A/B pairs ran two at a time on the same machine, C ran three
at a time.

**What it did with its tools.** All three runs did the same thing in the same order without being
told to: listed the tree, `cat` every source file in batches, ran `pnpm install`, then `tsc`,
`eslint`, `pnpm audit` and `next build`, then wrote a small Node script to prove the bcrypt 72-byte
truncation. Every run opened its report with a sentence saying what it had not done (no Postgres, no
browser) and that the runtime findings came from reading. Nobody asked for that either.

## 12.2 Extraction

Same rules as A and B. Each run produced **exactly 28 claims**, all three. 89 raw rows in
`findings/armC-raw.csv`, three of them the harness leak (`.claude/settings.json`, excluded as for arm
A), 37 distinct claims after de-duplication against the existing 77. Thirty-five map onto existing
claims and inherit their verdicts unchanged. Two are new, C78 and C79, adjudicated in
`findings/evidence-04.json`. Per-claim runs, overlap and domain are in
`findings/adjudication-key-C.json`.

I did not force C's wording into the A/B shape. It used its own three-tier grouping ("Fix before
shipping", "Should fix", "Investigate" or "Minor") instead of the five severities, and it bundled: C3's
item 4 is one heading holding what the key records as C05, C26 and C79. The raw CSV keeps its
headings as written and maps each to the claim it names.

## 12.3 Precision

| System | Claims | yes | partly | no | prevented elsewhere | Lenient | Strict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Single, arm A | 47 | 37 | 9 | 1 | 9 | 98% | 81% |
| Swarm, arm B | 48 | 38 | 10 | 0 | 10 | 100% | 79% |
| Naive, arm C | 37 | 30 | 7 | 0 | 7 | 100% | 81% |

The same. C has no anti-padding instruction and did not pad. Every run also ended with a "checked
and fine" list of things it looked at and found sound, which the A prompt explicitly forbids and the
swarm's contract routes to its own section. Those were dropped as positives, as for the other arms.

## 12.4 Coverage

Strict true positives.

| | A | B | C | Union |
| --- | --- | --- | --- | --- |
| All domains | 38 | 38 | **30** | 64 |
| Shared scope (five swarm domains) | 24 | 35 | 18 | 48 |
| Shared scope without tests | 23 | 22 | 17 | 35 |

Per domain:

| Domain | A | B | C | C only | Declared by |
| --- | --- | --- | --- | --- | --- |
| Security | 11 | 7 | **11** | 1 | A, B |
| Correctness | 11 | 3 | **10** | 1 | A |
| Infrastructure | 7 | 8 | 4 | 0 | A, B |
| Documentation | 2 | 5 | 1 | 0 | A, B |
| Dependencies | 3 | 2 | 1 | 0 | A, B |
| Tests | 1 | 13 | 1 | 0 | A, B |
| Performance | 2 | 0 | 2 | 0 | none |
| Accessibility | 1 | 0 | 0 | 0 | none |

Overlap, strict TPs:

| Pair | Both | First only | Second only | Jaccard |
| --- | --- | --- | --- | --- |
| C vs A | 27 | 3 | 11 | **66%** |
| C vs B | 13 | 17 | 25 | 24% |
| A vs B (from section 1) | 14 | 24 | 24 | 37% |

C and A found mostly the same things. C and B did not. The two things only C found, C78 (the share
page shows outcome and hindsight while the UI says only "view this idea") and C79 (an empty PATCH
body succeeds), are both informational.

## 12.5 Value

Rubric from section 8, re-applied from titles for all 79 claims before looking at arms. The A/B
split differs from section 8 by a few moderate/low items because it was done again; both are in the
record (`findings/value-rubric-applied.json`). The high tier is identical.

| Value | A | B | C | C found in 3 of 3 runs |
| --- | --- | --- | --- | --- |
| High | 4 | 3 | **4** | 4 |
| Moderate | 22 | 17 | 16 | 12 |
| Low / hygiene | 12 | 18 | 10 | 2 |

**C found every high-value defect in every run**, including C26, the calibration defect that only
arm A had found and that the swarm filed under "nobody owns this." The eleven true positives A found
and C did not are six moderate and five low: `serializeIdea` returns the whole row, `outcomeRecordedAt`
reset on edit, Node engines mismatch, `next/font` needs network at build, no backup plan,
accessibility gaps, and five hygiene items (boilerplate assets, duplicated build allowlist, cookie
not `__Host-` prefixed, Prisma version skew, hindsight scales unlabeled).

## 12.6 Repeatability

Strict TPs per system, tools condition for A and B.

| System | TPs | Seen once | Seen 3 of 3 | TPs per run |
| --- | --- | --- | --- | --- |
| A, tools | 32 | 8 (25%) | 14 (44%) | 20, 23, 27 |
| B, tools | 32 | 5 (16%) | 21 (66%) | 25, 27, 28 |
| **C** | 30 | 6 (20%) | **18 (60%)** | 26, 22, 24 |

This one I did not expect. The naive prompt is more repeatable than the engineered one, 60% against
44%, and within a few points of the swarm. The A prompt asks for breadth and gets it, and the breadth
is where the run-to-run variance lives. C produced 28 claims every time and the core of those 28 was
the same core.

## 12.7 The eight questions

1. **Does C notice there are no tests?** Yes, 3 of 3. C1 under "Investigate" as "No tests and no
   CI." C2 as item 7 under "Fix before shipping." C3 as one clause in the deploy-path item: "no
   Dockerfile, CI, health endpoint or tests."
2. **Does it decompose the missing coverage?** No. C2 came closest, one sentence: "Highest-value
   tests: ownership checks on every `[id]` route, share-token revoke and rotate, and score
   validation." Three areas named, no assertions, not repeated in C1 or C3. Under the same rules
   used for A, that is one claim, C68, not four. The swarm's thirteen per-module items with assertions
   remain the swarm's alone.
3. **Does C find the calibration defect?** Yes, 3 of 3, and it made the cross-cutting connection
   every time: the Edit button stays available after an outcome is recorded, the PATCH schema
   permits it, and calibration is therefore falsifiable. C1 and C3 put it under "Fix before
   shipping." C2 put it under "Should fix." The swarm found it in 0 of 6 runs as a finding.
4. **Does C naturally inspect security?** Yes, and it was its largest category: 11 strict TPs, equal
   to arm A and more than the security agent's 7. Unprompted, every run checked the JWT secret,
   rate limiting, enumeration, session revocation, headers, CSRF posture, share-link exposure and
   XSS sinks, and ran a probe for the bcrypt truncation.
5. **Does C discover unrequested areas?** Performance yes: unbounded reads with no pagination in 3
   of 3, the per-render database hit in 1, the duplicate share-page query in 1. Accessibility no, 0
   of 3. Arm A found it in 3 of 6.
6. **How stable?** 60% of its true positives in all three runs, 20% in one. 28 claims per run,
   every run.
7. **What did A's direction buy?** Coverage, modestly: 38 against 30, all of the difference moderate
   or low, none high. Not consistency: A is less repeatable than C. Actionability is close; both give
   a fix line per item, A per finding in a fixed shape, C in prose under numbered headings. A's
   reports are about twice as long for eight more true positives, and the extra length is mostly
   the hygiene tier.
8. **Does the swarm's advantage change against C?** In shared scope it grows: 35 against 18, which
   is 94% more, against 46% more over A. Without tests it is 22 against 17, 29% more, against parity
   with A. On all domains it is 38 against 30. So yes, the swarm looks better against the prompt a
   developer would type than against the prompt its author wrote. But the composition of the
   advantage is the same: the test reviewer, plus documentation and infrastructure hygiene, and the
   swarm still lacks the correctness lane where C found ten true positives to its three, including
   the one that matters most.

## 12.8 C against A: what a paragraph of prompt engineering is worth

Arm A's prompt is 170 words that name eleven domains, tell the reviewer to look for absences, and
fix an output shape. Arm C's is 24 words that name nothing. On this subject the difference is:

- Eight more strict true positives, 38 against 30. None high. Six moderate, five low, minus the
  three C found that A did not.
- Zero difference in precision.
- Lower repeatability, 44% against 60%.
- Roughly double the report length.
- One domain A was told about and C was not, accessibility, where A found one thing in half its
  runs.

The thing I was most worried about, prediction 5, was that a generalist would not notice an absent
test suite without being told to look for absences. C noticed it three times without being told.
The instruction was not what made the difference. Sonnet already looks for what is missing when you
ask it to review for production.

What the direction bought is real and small: the breadth to sweep hygiene domains an unprompted
reviewer does not bother with. It did not buy the high-value findings, which C already had, and it
cost consistency.

## 12.9 C against B: does specialization beat what a developer would ask?

On counts inside the swarm's declared scope, yes, clearly: 35 to 18. Outside tests, narrowly: 22 to
17. On all domains, 38 to 30. On the four high-value defects, no: C found all four in every run, the
swarm found three and filed the fourth under nobody.

By lane:

- **Tests.** The swarm's biggest edge and it is entirely composition. C says "no tests" once. The
  swarm says which thirteen modules and which assertions. If the reader wants a work list, the
  swarm wins this lane outright; if the reader wants to know whether tests exist, C already told
  them.
- **Security.** C 11, swarm 7. The generalist with no instructions beat the specialist with a charter
  and gitleaks in its own lane, by the same margin arm A did.
- **Correctness.** C 10, swarm 3. The swarm has no agent here. C found C26 every time.
- **Infrastructure.** Swarm 8, C 4. C found the deploy path, the exposed Postgres, the `tsc` typegen
  trap and the missing logging; it did not find the healthcheck, volume teardown, restart policy or
  port items, which are the infra agent's checklist.
- **Documentation.** Swarm 5, C 1. C found the product-and-compliance gap. It did not audit the README.
- **Unprompted domains.** C 2 (performance), swarm 0, by design.
- **Repeatability.** Swarm 66%, C 60%. Close.
- **Actionability.** Swarm higher per item, driven by the test items and the file-and-line contract.
  C gives a fix per heading and cites files in most of them.
- **Auditability.** The swarm's per-agent account of tools run, tools failed and files not read is
  still the one thing only it produces. C did something smaller and unprompted: every report opens
  with what it did not do. That is a one-line limitations statement, not an inspection record, and
  it is more than arm A gave.

## 12.10 The three arms in one table

Ordered by amount of direction. **This is an ordering, not a scale.** A to B changes two things at
once, the amount of direction and the decomposition into agents, and B covers fewer domains than A
by design. Read down the columns, not across a line.

| | C, goal only | A, compressed structure | B, decomposed structure |
| --- | --- | --- | --- |
| Prompt | 24 words | 170 words | five charters, contract, orchestrator |
| Claims (distinct) | 37 | 47 | 48 |
| Strict precision | 81% | 81% | 79% |
| Strict TPs, all domains | 30 | 38 | 38 |
| Strict TPs, shared scope | 18 | 24 | 35 |
| Shared scope without tests | 17 | 23 | 22 |
| High-value found | 4 of 4 | 4 of 4 | 3 of 4 |
| High-value found in every run | 4 | 3 | 2 |
| Calibration defect (C26) | 3 of 3 | 5 of 6 | 0 of 6 |
| Tests noticed | 3 of 3, as one item | 6 of 6, as one item | 6 of 6, as thirteen |
| Security TPs | 11 | 11 | 7 |
| Correctness TPs | 10 | 11 | 3 |
| Seen 3 of 3 (tools condition) | 60% | 44% | 66% |
| Report length, words | 877 to 1,199 | 2,176 to 2,901 | 1,708 to 2,136 |
| Unprompted limitations statement | every run | not measured | per-agent account, every run |

**The primary question, answered for this subject.** How much review structure does the model need
before additional direction stops producing meaningful improvements? For the defects that would block
a merge: none. Twenty-four words found all four, every time. For breadth across hygiene domains: a
paragraph buys about eight more true positives, none of them high, at the cost of consistency and
report length. For decomposing a known gap into a work list, and for a per-agent audit trail: only
the swarm produces those, and they are the swarm's real product. "Finds more bugs" is not.

## 12.11 What this changes in sections 10 and 11

- **The largest limitation in section 11 is now smaller.** The worry was that arm A's performance
  came from a prompt written by the swarm's author. C shows most of it came from the model. The
  prompt added breadth in hygiene domains and nothing at the high-value tier.
- **"Direction is what converts capability into evidence"** is still the thesis and this arm
  sharpens it. The capability to find the most consequential defect and to notice absent tests was
  present at zero direction. What direction produced was coverage of the lanes nobody thinks to
  check, a decomposed work list, and a record of what was checked. Those are evidence artifacts.
  They are not detection.
- **The security lane result is now three for three.** Two generalists, one told to check security
  and one not, both beat the security specialist in its own lane. That is no longer a curiosity.
- **Prediction 5 failed for a different reason than section 9b gave.** Section 9b blamed the "look
  for absences" sentence. C had no such sentence and noticed anyway. The prediction was wrong about
  the model, not about the prompt.
- **Experiment 002's first change is done.** The other two stand: a subject with tests and
  infrastructure code, and the registered actionability and documentation rubrics applied.

## 12.12 Caveats specific to this arm

- One naive prompt is one draw. "As if it were about to go into production" is itself a nudge
  toward security and operations. Cold prompts from outside reviewers are the fix.
- Designed and written after the results, by people who knew them. The guards are in D-005; they
  constrain the reviewer, not the prompt author.
- Thirty-five of 37 verdicts are inherited from the A/B adjudication, not re-judged. That is by
  instruction, and it means any A/B verdict error propagates.
- The value rubric was re-applied for this section and the A/B moderate/low split moved by a few
  items. The high tier did not.
- Runs were parallel, three at once on one machine, and on overage billing per the harness's own
  rate-limit events. Wall time is not comparable to A/B.
- Same subject, same model, same week. Nothing here generalises.
