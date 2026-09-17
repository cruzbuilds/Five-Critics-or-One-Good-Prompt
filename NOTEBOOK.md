# Lab notebook

My running log. Written the same day things happen, newest at the bottom, including the parts that
went wrong. The formal record is in the protocol, the predictions and the session files. This is the
story those documents cannot tell.

One rule for this file: if something surprised me, I write it down before it becomes obvious in
hindsight. Nothing here gets rewritten later to make me look smarter.

---

## 2026-09-17 - the day I built the thing I am going to review

### Where the question came from

Not from a research idea. From a conference, listening to the same sentence come out of different
people all week: we cannot trust AI, and we do not want our dev teams using AI coding tools, because
we cannot trust the output. Different industries, different sized organizations, people with no reason
to be comparing notes with each other. When a concern shows up that consistently across companies that
do not talk to one another, it is not a preference. It is a missing control.

My first instinct was to build agentic development, a swarm that writes the code. I dropped it fairly
quickly, because Claude and Kiro already write decent code. Generation was not the gap. If the code is
fine and the blocker is that nobody trusts it, then the thing worth building is whatever makes a
customer comfortable with their own developers using these tools. That is a review problem.

Which led me here, to the uncomfortable part. My swarm has a log of 37 findings across five pull
requests and no control group. I never checked what one good general prompt would have caught on the
same code.

### The swarm blocked its own fix, twice

This happened a few hours before the experiment started and I did not plan it.

I had the swarm review a change to its own permissions, one that gave two reviewers shell access so
they could actually run git. It blocked the change twice, and both blocks were right.

First: bare `Bash` on an agent whose only input is a diff written by whoever wrote the change under
review is untrusted content reaching a command executor. It also proved that
`git -c alias.x='!sh -c ...' x` runs arbitrary commands, which means "allow git" is not a restriction
at all unless `-c` is denied. I did not know that.

Second: the guard I added in that same commit, the one meant to stop the original defect from coming
back, was itself broken. It grepped the adapter file for the word "shell", which matched inside a
description line, so an adapter granting nothing passed green. I wrote the guard. I believed it
worked. A reviewer disproved it with a command instead of an opinion.

That is the argument for this whole project in miniature, and it happened by accident on my own code.

### The build

One paragraph, a fresh terminal, no context, nothing from this experiment in reach. Twelve minutes and
thirty-two seconds of agent work, nineteen minutes of wall clock. Sixty files, 6,985 lines.

Things it decided with nobody asking:

- **It containerized the database.** My paragraph says nothing about Docker, deployment or
  infrastructure. It reached for Docker Compose on its own, which is the only reason the
  infrastructure lane has anything to look at.
- **It hand-rolled the auth.** Its words: "hand-rolled cookie/JWT auth (jose + bcryptjs) rather than
  pulling in a full auth library." Unprompted, and the riskiest decision in the build.
- **It pinned Prisma on purpose and told me why.** "Prisma 7 just shipped and requires driver adapters,
  not worth the churn here." That is more thought about dependency risk than I expected from something
  moving this fast.
- **It wrote an `AGENTS.md` and a `CLAUDE.md` for itself.** Instruction files for future agents, in a
  repository that was twelve minutes old. Nobody asked for those.
- **It gitignored its own secret.** It generated a `JWT_SECRET` into `.env`, and `.gitignore` carries
  `.env*` with `!.env.example`. It protected the thing it created. I am writing that down now, before
  I start counting its failures, because it deserves the credit.

### The most interesting thing that happened all day

It said: "The app is built and fully smoke-tested." At the commit prompt it said: "The app is built,
tested end-to-end, and ready."

There is no test script in `package.json`. No test file, no test directory, no test framework.
`pnpm test` exits 1 with nothing to run.

Both statements are true in the sense it meant them. It really did test the full flow with curl
against a live dev server: register, login, cross-user privacy, create and rank ideas, record
hindsight, share and revoke a link. It did the work. But that work lived in a terminal session that no
longer exists, and nothing in the repository can reproduce a single one of those checks.

Where its claims were machine-checkable they held. `tsc`, eslint and `next build` are all clean,
exactly as promised. Where they were not checkable, the words did more work than the facts supported.

That is a much more interesting failure than an AI making something up, and I think it is a lot more
common. If someone handed me that summary at the end of an engagement I would not have blinked at it.

### I broke my own measurement

My first baseline run captured exit codes with `$?` after a `tee` pipeline, which reports `tee`'s
status rather than the command's. Every scan came back `exit=0`, including the two that had failed.

I re-ran them with the status captured properly, and both sets of raw output are on disk. I am
recording it rather than quietly overwriting it, because a study that hides its own measurement bugs
has no standing to report anyone else's.

### The scope lane has nothing to review

I found this while setting up the arms, not while running them.

`scope-reviewer` holds a change against `engagement/03-scope.md` and the decision records. My
generated app has neither, because it is a vibe-coded repository built from one paragraph, which is
exactly the kind of repository someone would point this swarm at in real life.

Per its own charter the agent will say so and return PASS. It is not broken. It is correctly reporting
that it has nothing to check against.

I could have handed both arms the specification to give that lane something to do. I decided not to.
Section 4 of that spec lists security, tests and documentation as requirements, so handing it over
gives both reviewers a checklist and kills the sharpest prediction I have, which is whether a general
reviewer notices an entire category of artifact is missing.

So this study tests four of my five charters, and says so. The fifth returning PASS for lack of a
scope document is itself a finding about my swarm: it depends on process artifacts that a
fast-generated repository does not have. Anyone thinking about adopting it should know that before
they try.

### Predictions

Sealed and pushed publicly before either arm ran.

I would not give absolute counts. I had not read the source, and making up a number to look rigorous
is worse than admitting I did not have one. So the predictions are directional, which is what my
hypothesis actually claims anyway.

The sharp one: I do not think the general reviewer flags the missing test suite. If it does, my
specialization argument gets a lot weaker, and that is the point of writing it down.

### Where I left it

Frozen at `v0-raw`, `b38c5b0dc51206bda7cd97fc27d0d252d6fd6a02`. Baseline recorded. Predictions sealed
and public. Two working copies forked from the tag, all four repositories at the same hash. Nothing
reviewed yet.
