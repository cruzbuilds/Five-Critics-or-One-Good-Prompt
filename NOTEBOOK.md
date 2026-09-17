# Lab notebook

The running narrative. Written as it happens, newest at the bottom, including the parts that went
wrong. The formal record lives in `experiment-001-protocol.md`, `PREDICTIONS.md` and
`sessions/`; this file is the story those documents cannot tell.

Rule for this file: if something was surprising, write it down the same day, before it becomes
obvious in hindsight. Nothing here gets rewritten later to look smarter.

---

## 2026-09-17 — the day the subject got built

### Where the question came from

Not from a research idea. From a conference, listening to the same sentence come out of different
people all week: we cannot trust AI, and we do not want our dev teams using AI coding tools, because
we cannot trust the output. Different industries, different sized organizations, people with no
reason to be comparing notes. When a concern shows up that consistently across organizations that do
not talk to each other, it is not a preference, it is a missing control.

The first instinct was to build agentic *development*. That got dropped quickly: Claude and Kiro
already write decent code. Generation was not the gap. If the code is fine and the blocker is that
nobody trusts it, the thing worth building is whatever makes a customer comfortable with their own
developers using these tools. That is a review problem.

Which led here, to the uncomfortable part: the review swarm has a log of 37 findings across five
pull requests, and no control group. Nobody ever checked what one good general prompt would have
caught on the same code.

### The swarm blocked its own fix, twice

Before the experiment started, the swarm reviewed a change to its own permissions — a change that
gave two of its reviewers shell access so they could run git. It blocked it twice, and both blocks
were right.

The first: bare `Bash` on an agent whose only input is a diff written by whoever wrote the change
under review is untrusted content reaching a command executor. It also proved that
`git -c alias.x='!sh -c ...' x` runs arbitrary commands, which means "allow git" is not a restriction
at all unless `-c` is denied.

The second: the guard added in that same commit to prevent the original defect from returning was
itself broken. It grepped the adapter file for the word "shell", which matched inside a description
line, so an adapter granting nothing passed green. The author wrote the guard, believed it worked,
and a reviewer disproved it with a command rather than an opinion.

That is the argument for this whole project in miniature, and it happened by accident a few hours
before the experiment began.

### The build

One paragraph, a fresh terminal, no context. 12 minutes 32 seconds of agent work, 19 minutes of wall
clock. 60 files, 6,985 lines.

Things it decided with nobody asking:

- **Containerized the database.** The prompt says nothing about Docker, deployment or
  infrastructure. It reached for Docker Compose on its own, which is why the infrastructure lane has
  anything to review at all.
- **Hand-rolled the auth.** Its words: "hand-rolled cookie/JWT auth (jose + bcryptjs) rather than
  pulling in a full auth library." Unprompted, and the highest-risk decision in the build.
- **Pinned Prisma deliberately and explained why.** "Prisma 7 just shipped and requires driver
  adapters, not worth the churn here." Unprompted reasoning about dependency churn, which is more
  care than the stereotype of fast generation would predict.
- **Wrote an `AGENTS.md` and a `CLAUDE.md` for itself.** Instruction files for future agents working
  in a repository that was 12 minutes old.
- **Gitignored its own secret.** It generated a `JWT_SECRET` into `.env`, and `.gitignore` carries
  `.env*` with `!.env.example`. It protected the thing it created. Point in its favour, recorded
  before anyone starts counting its failures.

### The most interesting thing that happened all day

It said: "The app is built and fully smoke-tested." At the commit prompt it said: "The app is built,
tested end-to-end, and ready."

`package.json` has no `test` script. The repository contains no test file, no test directory, no test
framework. `pnpm test` exits 1 with nothing to run.

Both statements are true in the sense the agent meant them. It really did test the full flow with
curl against a live dev server: register, login, cross-user privacy, create and rank ideas, record
hindsight, share and revoke a link. It did the work. But that work existed only in a terminal session
that no longer exists, and nothing in the repository can reproduce a single one of those checks.

Where its claims were machine-checkable, they held: `tsc`, `eslint` and `next build` all clean,
exactly as promised. Where they were not checkable, the words did more work than the facts supported.
That is a much more interesting failure than "the AI lied," and it is the kind of thing a person
skimming a handoff would accept without blinking.

### A measurement bug in the measurement

The first baseline run captured exit codes with `$?` after a `tee` pipeline, which reports `tee`'s
status rather than the command's. Every scan came back `exit=0`, including the two that had failed.
The scans were re-run with the status captured directly, and both sets of raw output are on disk.

Recorded rather than quietly overwritten. A study that hides its own measurement bugs has no standing
to report anyone else's.

### The scope lane has nothing to review

Found while preparing the arms, not while running them.

`scope-reviewer` holds a change against `engagement/03-scope.md` and the decision records. `idea-log`
has neither, because it is a vibe-coded application built from one paragraph — which is precisely the
kind of repository the swarm would be pointed at in the wild.

Per its own charter the agent will say so under Noted and return PASS. It is not broken. It is
correctly reporting that it has nothing to check against.

The alternative was to hand both arms the specification as context, which would have given the scope
lane something to do. That was rejected, deliberately: section 4 of that specification lists security,
tests and documentation as requirements, so handing it over would give both reviewers a checklist and
collapse the sharpest prediction in the study — whether a general reviewer notices that an entire
category of artifact is missing — into whether it can read a document that says tests are required.

**So this study tests four of five charters, and reports that it did.** The fifth lane returning PASS
for lack of a scope document is itself a finding about the swarm: it depends on process artifacts that
a fast-generated repository does not have. Anyone deciding whether to adopt this thing should know
that before they try it.

### Predictions, sealed

Committed before either arm ran. The conductor declined to give absolute counts — "I'd be silly to
just throw a number in thin air" — so the predictions are directional, and the refusal is registered
as-is rather than replaced with an invented number.

The sharp one: the single reviewer will **not** flag the missing test suite. If it does, the
specialization argument weakens considerably.

### State at end of day

Frozen at `v0-raw`, `b38c5b0dc51206bda7cd97fc27d0d252d6fd6a02`. Baseline scans recorded. Predictions
sealed and public. Both arms cloned from the tag. Nothing reviewed yet.
