# Predictions, sealed

**Written 2026-09-17, after the build was frozen at `v0-raw` (`b38c5b0dc51206bda7cd97fc27d0d252d6fd6a02`)
and the baseline scans were run, and BEFORE either review arm ran.**

Committed to git before arm A. Never edited afterwards. Whatever these get wrong stays wrong and
gets reported.

## What I knew when I wrote these

- The stack: Next.js 16 App Router, TypeScript, Postgres via Prisma 6.x, Tailwind v4, hand-rolled
  cookie/JWT auth with jose and bcryptjs, Docker for the database.
- 60 files, 6,985 lines, built in 12m 32s of agent work.
- The agent's own summary of what it built, including its claim of having smoke-tested the full flow.
- Baseline: `tsc`, `eslint` and `next build` all clean. No test script exists. One high-severity
  transitive dependency advisory.
- File and directory names, and what is absent: no tests, no CI, no application Dockerfile.

**I had not read the source code.** I did not open a single file in `src/` before writing these. That
is recorded because it bounds how informed the guesses are.

## I would not make up a number

I was asked for absolute finding counts and I would not give one:

> "I don't have predictions lol it could've done great how should I know I'm not reading the code at
> the moment"

That is registered as I said it rather than replaced with an invented number. Published baselines
suggest 4 to 8 real security findings would be unsurprising in an application of this shape, but that
is a figure from the literature, not something I believed, and I am not claiming it as a prediction.

So the predictions below are **directional**. They are claims about the comparison between the arms,
which is what H1 actually asserts, and they can be graded without absolute counts.

## The five predictions

| # | Question | Prediction | How it gets graded |
| --- | --- | --- | --- |
| 1 | Does the swarm find more real findings than the single review? | **More, in all categories** | Count of adjudicated true positives per arm per domain. Note this is the strongest available form of the claim: not "more overall" but "more in every domain," which fails if the single reviewer wins even one lane. |
| 2 | Does either arm miss a critical the other caught? | **The single review misses one the swarm catches** | Any finding adjudicated critical and present in exactly one arm |
| 3 | Which lane shows the biggest gap? | **Documentation, then security** | Largest difference in adjudicated true positives by domain |
| 4 | Whose precision is higher? | **The swarm.** This is an expectation, not a reasoned case. My actual words were "it should be" | True positives over total findings, per arm |
| 5 | Does the single reviewer flag the missing test suite? | **No** | Does arm A's report name the absence of any automated tests, in any run |

## Why prediction 5 is the sharp one

The repository has no test script and no test file. `test-reviewer` has this in its charter and
cannot miss it. A general reviewer is reading code that exists, and noticing that an entire class of
artifact is *absent* is a different cognitive move from finding a bug in something present.

If arm A flags it, the specialization argument weakens considerably: a good general prompt noticed a
missing category without being told to look for one. If arm A does not, that is the single cleanest
illustration of what charters buy, in one line a reader can check.

## Predictions I did not make

Left blank on purpose rather than filled in for completeness: absolute finding counts per arm,
false-positive rates as numbers, the cost ratio between arms, and stability across the three runs. I
had no view on any of them. They get measured and reported. They do not get graded against a
prediction I invented afterwards.

## The result that would falsify the hypothesis

Registered alongside, from the design interview:

> "It has application for customer experience FUD, but if a genuine one prompt is that good, then
> yes, it proves an agentic review is not necessary."
