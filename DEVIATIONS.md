# Deviation log

Every departure from the registered protocol, with the date, the reason, who decided, and whether any
result had been observed at the time. Append only.

The last column is the one that matters. A change made before any result exists is a design decision.
A change made after is a finding about the person making it.

---

## 2026-09-18, D-001: arms run in parallel pairs rather than alternating

**Protocol said:** six runs, alternating A1, B1, A2, B2, A3, B3.

**Now:** three pairs, each pair run simultaneously. A1 and B1 start in the same second, then A2 and
B2, then A3 and B3.

**Why:** alternating was there to stop drift across a session from favouring whichever arm ran later.
Running each pair at the same moment controls for that better, since both arms meet the same model in
the same minute. It is also faster, which is why I asked, but it is not the reason it is allowed.

**Results observed at the time of the change:** none. No review of any kind had run.

**Decided by:** me, before the first run.

**Risk this introduces:** two concurrent sessions on the same account may hit rate limits, which
alternating would not. Any run that fails for that reason is recorded in the failure log and re-run
with a new run ID, and both the failure and the re-run stay in the record.

---

## 2026-09-18, D-002: arm B is given the whole repository as its change

**Protocol said:** `scripts/review.sh` at the pinned commit, unmodified.

**The problem:** `review.sh` reviews a *change*. Its default range is "everything uncommitted plus
every commit on this branch that is not on main." The subject has exactly one root commit and no main
to compare against, so that instruction is meaningless here and the swarm would have been reviewing
nothing coherent.

**Now:** the empty tree hash is passed as the range,
`4b825dc642cb6eb9a060e54bf8d69288fbee4904..HEAD`. The diff is then the entire repository, and every
file is a changed file the agents must read in full.

**Why this is the fair mapping, not a favour to either arm:** arm A is told to read the repository
thoroughly. This makes arm B's instruction the same thing in the form its runner understands. Without
it, arm B would have been handicapped by a harness assumption rather than by anything about
specialized review, and I would have drawn a conclusion about the swarm from a mistake of mine.

`review.sh` itself is unmodified. Only the range argument is supplied.

**Results observed at the time of the change:** none.

**Decided by:** me, before the first run.

---

## 2026-09-18, D-003: arm A runs through the same permission file as arm B

**Protocol said:** identical tool access, without saying how it would be guaranteed.

**The gap:** `review.sh` writes a `.claude/settings.json` into its scratch workspace, granting a
specific list of commands and denying the ways `git` can be turned into a general command runner. Had
arm A run with a plain `Bash` grant, it would have had wider access than the swarm, and any difference
in findings would have been partly a difference in permissions.

**Now:** `scripts/run-pair.sh` extracts that same settings block out of `review.sh` and writes it into
arm A's scratch copy, and passes the same `--allowedTools` set. Both arms work from a scratch copy of
their own repository, so neither can write to anything that matters.

**Results observed at the time of the change:** none.

**Decided by:** me, before the first run. Caught while building the runner, not during analysis.

---

## 2026-09-18, D-004: the study becomes two conditions, because the first one denied every tool

**What happened.** All six condition-1 runs completed with every shell call refused. `review.sh`
passed `--allowedTools Read,Grep,Glob,Task`, which does not name `Bash`, so no agent in either arm
could run a command. The agents said so in their Noted sections. The reports otherwise looked normal.

**Whose fault.** Mine. I removed `Bash` from that flag on 2026-09-17 while narrowing permissions after
a security finding, believing the command allow list in the settings file would scope it. That flag is
the gate, not a filter. The allow list underneath was never consulted. A second bug compounded it: the
allow list permitted `npm audit` but not `pnpm audit`, and the subject is a pnpm project.

**Results observed at the time of the change:** yes. Six runs had completed and been compared. This is
the first amendment in this study made with results already in view, and it is recorded as such.

**Why it is not a rewrite of an inconvenient result.** Condition 1 is kept, in full, and reported as
what it is: a fair comparison in which both arms were equally denied their tools. Nothing is deleted
or re-run to replace it. What changes is that a second condition is added, with the fix applied to
both arms equally.

**What the study becomes.**

|  | reading only | with tools |
| --- | --- | --- |
| single prompt | A1-A3, done | A1-A3-tools |
| swarm | B1, B2r, B3, done | B1-B3-tools |

That is a better design than the one registered, and it exists because of a defect. Tool access
becomes the isolated variable, which is the question a reader most wants answered about specialized
reviewers: whether the specialization pays off only when the specialists can use their instruments.

**Risk this introduces, stated plainly.** Condition 2 is being run after seeing condition 1, by
someone who now knows the swarm underperformed. The guards are that both arms get identical access,
the arm A prompt does not change by a character, the subject commit does not change, and
`scripts/preflight.sh` must pass before any condition-2 run counts. The preflight asks a live session
to run one command and checks the output, so a silently-denied shell cannot happen twice.

**Swarm version changes between conditions.** Condition 1 ran swarm `7461982`. Condition 2 runs
`a18fba7`, which differs only in the two permission fixes. Both hashes are recorded per run in
`reports/runs.csv`. A reader can object that the swarm under test is not identical across conditions;
the answer is that the condition-1 version could not run tools by construction, so there was no way to
hold it constant and change the variable.

## 2026-09-19, D-005: a third arm is added after the A/B results were observed

**What was registered.** Two arms. A: one strong general prompt. B: the specialist swarm. Five
predictions about A against B, sealed at `9e2155d`.

**What changed.** A third arm, C, is added. One general review instruction with no domain map, run
three times under the tools condition, same frozen subject, same model, same permissions as A*.2 and
B*.2. The whole prompt is `prompts/arm-c.txt`, two sentences, 24 words.

**Why.** The re-analysis (`ANALYSIS.md`, section 9b) found that arm A's prompt is the swarm's five
charters compressed into a paragraph, plus correctness, written by the swarm's author. That makes A a
strong baseline and a strange one: it compares five agents holding the map against one agent handed
the map. The comparison a developer actually makes is against "take a look at this before I ship
it." Arm C is that.

**What this is and is not.** Arm C is exploratory follow-up evidence. It was designed after the A/B
results were known, by someone who knows what A and B found, which domains mattered, and that tests
and correctness were the interesting lanes. It is **not** part of the preregistered comparison and no
prediction in `PREDICTIONS.md` is about it. The predictions are not rewritten. The A/B adjudications
are not touched. The result of C, whatever it is, is reported in its own section of `ANALYSIS.md`
under that label.

**Guards against contamination.** The reviewer runs in a fresh scratch clone of the sealed `idea-log`
at `v0-raw`, containing the repository and nothing else: no study repo, no reports, no findings, no
other arm's prompt. `scripts/run-arm-c.sh` refuses to run if the prompt file has grown past forty
words, if the subject is not at `v0-raw`, or if a report with that number already exists. The
reviewer gets one message and no follow-up.

**What the design knowledge could still leak through.** The prompt was written by the same people
who know the results. It was written to be as plain as possible and it names nothing, but "as if it
were about to go into production" is itself a choice, and a different plain sentence might steer
differently. That is one prompt, not a population of naive prompts. Reviewers of this study have been
asked for their own cold one-sentence prompts; if those get run, they go in as further arms with
their own deviation entries.

**Recording.** Arm C runs capture the full event stream (`reports/C*.stream.jsonl`) as well as the
final text (`reports/C*.md`), so tool calls, failed tool calls, tokens and cost are recorded from the
harness rather than estimated. A and B did not have this; their `runs.csv` rows leave those columns
blank. That is a difference in instrumentation, not in what the reviewer could do.

**Normalization.** C's claims are extracted and de-duplicated by the same rules as A and B, only
after all three runs exist, and its raw wording is preserved as written. Nothing in the rules changes
to fit C. Where a C claim matches an existing A/B claim, it inherits the existing verdict; the
existing verdict is not revisited. New claims get new verdicts by the same three-value rule, with the
`already prevented` flag, and go into the append-only evidence files.
