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
