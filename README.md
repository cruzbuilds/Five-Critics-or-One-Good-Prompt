# Five critics or one good prompt

## AI is not wrong. It needs direction.

That is what I am trying to show, and this is the experiment I am using to find out whether I am
right.

On day one of this study, the coding agent that built my subject application told me it was "tested
end-to-end." It was telling the truth. It had run a real test plan against a live server, unprompted,
including the cross-user privacy checks that matter most in that app. It left behind no test file, no
framework, no test script. All of that work happened in a terminal session that no longer exists.

**The capability was there. The instruction was not.** That is not an AI problem. That is the same
thing that happens when an engineer tests carefully and writes nothing down: the work was real, and
six months later nobody can prove it happened, so in practice it did not.

If that is right, then the useful question is not whether AI can write good code. It is what kind of
direction turns what it does into something a person can verify. This study measures one version of
that question.

Status: **the subject is built and frozen, no reviews have run yet.** Results are not in. Nothing here
concludes anything.

---

## The claim, stated so it can lose

"AI needs direction" is too comfortable to be a thesis on its own. Any result confirms it, which means
it says nothing. So here is the sharper version, written before the results:

**Direction is what converts capability into evidence, and the amount required is an empirical
question.** My swarm is a lot of direction: five written charters saying what must be checked and what
must be reported. A single good prompt is less direction. This study measures whether the extra buys
anything real.

It can lose, and here is how: if five charters produce no more valid findings than one strong prompt,
then a paragraph of direction is enough, my charters are over-engineering, and I will say exactly that
here. I wrote that commitment down before running anything.

---

## Why I am doing this

I kept hearing the same sentence at a conference, from people in different industries and different
sized companies who had no reason to be comparing notes.

> "We can't trust AI and we don't want our dev team using AI coding tools, because we can't trust the
> output."

My first thought was to build agentic development, agents that write the code. I dropped that fast,
because the tools are already good at writing code. Generation is not the gap. If the code is fine and
the blocker is that nobody trusts it, then the thing worth building is whatever makes a customer
comfortable with their own developers using these tools. That is a review problem, not a writing
problem.

So I built [agentic-review-swarm](https://github.com/cruzbuilds/agentic-review-swarm): five reviewers,
each with a written charter saying what it blocks on and what it stays out of. It has reviewed every
pull request on a real project of mine, 37 findings, none overridden, and by my own count I would have
missed 21 of the 33 actionable ones reading the diff alone.

Here is the problem with that number. There is no control group. I never checked what one good
"review this carefully" prompt would have found on the same code. If the answer is most of it, then my
charters are decoration and the honest conclusion is that any careful AI review works.

That is worth knowing, so I am checking.

## The thing being tested: agentic-review-swarm

**Repository: [cruzbuilds/agentic-review-swarm](https://github.com/cruzbuilds/agentic-review-swarm)**

The swarm is five AI reviewers that read the same change at once, each from one angle, each with a
written charter naming what it blocks on and what it must stay out of. Their findings merge into one
verdict, and any single BLOCK is a BLOCK.

| Agent | Blocks on |
| --- | --- |
| `security-reviewer` | Credentials in source, untrusted input reaching a query or shell, mutating endpoints with no auth check, over-broad permissions, critical dependency vulnerabilities |
| `test-reviewer` | New behavior with no test, a test that cannot fail, tests removed or skipped to go green, coverage dropped on changed lines |
| `docs-reviewer` | README behind the code, undocumented environment variables, decisions with no record, resources with no teardown, "not production ready" with no specifics |
| `infra-reviewer` | Hardcoded resource identifiers, static cloud keys in CI, mutable action versions on deploy steps, jobs with no permissions block, infrastructure with no teardown |
| `scope-reviewer` | Work that was not agreed, work explicitly excluded, constraining decisions with no ADR, dependencies with no justification |

Three things about it matter for this study.

**The charter is the agent.** Each one is a page of English saying what to block on, what to warn on,
and what to leave alone, not a tuned prompt nobody can read. That is what "direction" means here, and
it is what is on trial.

**Every agent is proven against planted defects before it reviews anything real.** 35 seeded cases,
including clean ones, because an agent that blocks everything is as useless as one that passes
everything.

**It has a track record with a hole in it.** It reviewed every pull request on
[shelflife](https://github.com/cruzbuilds/shelflife): 37 findings, none overridden, and by my own
count I would have missed 21 of the 33 actionable ones reading the diff alone. It has also blocked
changes to itself, twice in one afternoon, and was right both times.

The hole is that there is no control group anywhere in that record. Which is this experiment.

**Version under test:** pinned at a specific commit before arm B runs and frozen there. If the swarm
changes mid-study, the study restarts or each version is reported separately.

## What the experiment is

One application, generated fast from a single paragraph, frozen. Two ways of reviewing it:

- **Arm A**: one general reviewer, one strong prompt, no roles.
- **Arm B**: the swarm, five narrow reviewers, merged into one verdict.

Same commit, same model, same day, three runs each, neither seeing the other's output. Then I mark
every finding real or not, count what each one found and missed, and publish the lot.

## What I did to keep myself honest

I built one of the two contestants and I am scoring both. That cannot be removed, so here is what it
is constrained by, all of it decided before any review ran:

**The headline number does not depend on my opinion.** Every finding records how it was corroborated:
a `tsc` error, an eslint rule, `npm audit`, a failing test, or a reproduction anyone can run. Findings
with machine corroboration are counted separately, and that subset is the result I lead with. My own
judgment calls are reported second and labeled.

**Predictions are sealed and public.** [`PREDICTIONS.md`](PREDICTIONS.md) went into this public repo
before either arm ran. They can be wrong and they will stay there if they are.

**I score blind, arm A first.** Labels stripped, arm A's whole list scored before I open arm B's.

**A second judge that is not me.** Adjudication runs again on a different model than the reviewers,
its verdicts publish beside mine, and the disagreement rate is a result I report.

**Verdicts are open and versioned.** If you think I scored something wrong, say so. I will change it
and log the change. I am not hiding the data, so you do not have to take my word for any of it.

**I wrote down what would prove me wrong.** If one prompt gets close to five agents, the paper says
the swarm is unnecessary and I will have spent a month of evenings learning something simple.

## What is in here

| Path | What |
| --- | --- |
| [`NOTEBOOK.md`](NOTEBOOK.md) | The running story, written the same day things happen, including the parts that went wrong |
| [`PREDICTIONS.md`](PREDICTIONS.md) | What I predicted, sealed before any review |
| [`PROTOCOL.md`](PROTOCOL.md) | The method. Locked once the first review runs; every change after that is logged |
| [`APP-SPEC.md`](APP-SPEC.md) | The specification the reviewers are judged against. The builder never saw it |
| [`PROVENANCE.md`](PROVENANCE.md) | Four repositories, one commit hash, shown not claimed |
| [`ARM-A-PROMPT.md`](ARM-A-PROMPT.md) | Arm A's prompt, verbatim, plus why it is not a strawman |
| [`findings/`](findings/) | The evidence layer: findings, verdicts, corrections, and the adjudication ledger. Append-only, enforced by `scripts/check-append-only.sh` |
| [`reports/`](reports/) | Raw review output, unedited, plus per-run cost and timing. Empty until the runs happen |
| `baseline/` | Raw output from every free scanner, run once against the frozen commit |
| `sessions/` | What happened in each session, with every prompt and answer |

## What I expected versus what I got

I expected to open the repository and find that the agent had skipped testing. That is the easy story
about fast AI code.

What I found is better than that, and more useful.

It told me the app was "fully smoke-tested" and "tested end-to-end, and ready." Then it described the
test plan it had run, unprompted: register and login, cross-user privacy, create and rank ideas,
record hindsight, share and revoke a link, unauthenticated requests redirected or rejected. That is a
real plan, and it covers the thing that matters most in this app. Nobody asked it to do any of it.

There is also no test file, no test framework, and no test script. `pnpm test` exits 1 with nothing to
run. Every one of those checks happened in a terminal session that no longer exists.

**So the gap is not capability. Nothing told it to leave the work behind.**

That is a process problem, and it is the same one people have. I have worked with engineers who tested
carefully, fixed what they found, and wrote none of it down. The work was real. Six months later
nobody can prove it happened, so in practice it did not.

It matters twice over. An engineer inheriting this repo sees no tests and concludes either that
nothing was tested or that nothing can be reproduced, and the agent's own summary makes that worse,
because "tested end-to-end" in a handoff means a suite you can run. And it is the argument for this
whole project in one story: agents do not need to be smarter to produce evidence, they need rules,
the same way people do. A charter is a written rule about what gets checked and what gets recorded.
This is what the absence of one looks like.

One thing on the other side of the ledger: everything it claimed that a tool could verify was true.
`tsc`, eslint and `next build` are clean exactly as promised. It overstated only the thing no tool
checks, which is probably not a coincidence.

Whether either reviewer notices is the sharpest thing I predicted, and my guess is on the record.

## What this will not tell you

One app, one stack, one model, one author. Three runs per arm describes stability, not statistics, and
I make no statistical claim. No seeded defects, so anything both arms missed is invisible to me. The
the swarm's scope agent needs a scope document and this repository has none, so only four charters do
substantive code-review work here.

On the name: "five critics" is still fair. The fifth critic is part of the system under evaluation,
and the fact that it cannot operate without scope artifacts is a result rather than an exclusion. A
team adopting this swarm for a fast-generated repository would get exactly what I got, and they should
know that before they try it. I am learning TypeScript, which is why nothing
counts as real on my reading alone.

## The rest

- [agentic-review-swarm](https://github.com/cruzbuilds/agentic-review-swarm) - the five reviewers
- [shelflife](https://github.com/cruzbuilds/shelflife) - the project whose review log started this
- [project-starter](https://github.com/cruzbuilds/project-starter) - the template both came from

Personal project. No employer or customer material anywhere in it.

## License

MIT, see [LICENSE](LICENSE). The findings, verdicts and raw reports are published so they can be
checked and challenged; if you think a verdict is wrong, open an issue and it gets logged in
`findings/corrections.csv` whether I agree or not.
