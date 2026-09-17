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

### What I expected versus what I got, and why the difference is good news

I expected to find that the agent skipped testing. That is the easy story about fast AI code, and it
is the one I would have written if I had stopped at the file listing.

What actually happened is more interesting and, honestly, more encouraging.

It said "the app is built and fully smoke-tested," and at the commit prompt, "built, tested end-to-end,
and ready." Then it described exactly what it had done, without being asked:

> "I tested the full flow with curl against a live dev server: register/login, cross-user privacy
> (404s, not leaky 403s), create/rank ideas, record hindsight, share/revoke a link, and confirmed
> unauthenticated requests get redirected or 401'd correctly."

That is a real test plan. It covers the things I would have asked it to cover, including cross-user
privacy, which is the one that matters most in this app. Nobody told it to do any of that. It was not
lazy and it did not fake anything.

And there is no test file, no test framework, no `test` script. `pnpm test` exits 1 with nothing to
run. All of that work happened in a terminal session that no longer exists.

**So the gap is not capability. The gap is that nothing told it to leave the work behind.**

That is a process problem, and it is the same one humans have. I have worked with plenty of engineers
who tested carefully, fixed what they found, and wrote down none of it. The work was real. Six months
later nobody can prove it happened or re-run it, so for practical purposes it did not.

Two things follow from that, and both matter more than "the AI didn't test."

The first is how this reads to whoever inherits it. An engineer opening this repository sees no tests
and reasonably concludes either that nothing was tested, or that whatever was tested cannot be
reproduced. Both conclusions are wrong about the effort and right about the consequence. The agent's
own summary makes it worse, not better, because "tested end-to-end" in a handoff means a suite you can
run, and here it meant curl in a scrollback buffer. If someone handed me that at the end of an
engagement I would not have blinked.

The second is the argument for this whole project. Agents do not need to be smarter to produce
evidence. They need rules, the same way people do. Every one of my charters is a written rule that
says what must be checked and what must be recorded, and this is a clean example of what happens
without one: real work, no record, and a sentence that sounds like assurance and is not.

Worth noting on the other side of the ledger: where its claims were machine-checkable, they were all
true. `tsc`, eslint and `next build` are clean exactly as it said. It did not overstate anything a
tool could verify. It overstated only the thing no tool checks, which is probably not a coincidence.

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
