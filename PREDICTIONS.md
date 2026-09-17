# Predictions, sealed

**Written 2026-09-17, after the build was frozen at `v0-raw` (`b38c5b0dc51206bda7cd97fc27d0d252d6fd6a02`)
and the baseline scans were run, and BEFORE either review arm ran.**

Committed to git before arm A. Never edited afterwards. Whatever these get wrong stays wrong and
gets reported.

## What the predictor knew at the time

- The stack: Next.js 16 App Router, TypeScript, Postgres via Prisma 6.x, Tailwind v4, hand-rolled
  cookie/JWT auth with jose and bcryptjs, Docker for the database.
- 60 files, 6,985 lines, built in 12m 32s of agent work.
- The agent's own summary of what it built, including its claim of having smoke-tested the full flow.
- Baseline: `tsc`, `eslint` and `next build` all clean. No test script exists. One high-severity
  transitive dependency advisory.
- File and directory names, and what is absent: no tests, no CI, no application Dockerfile.

**The predictor had not read the source code.** No file in `src/` was opened before these predictions
were written. That is recorded because it bounds how informed these guesses are.

## No numeric prior

Asked for absolute finding counts, the conductor declined:

> "I don't have predictions lol it could've done great how should I know I'm not reading the code at
> the moment"

That is registered as-is rather than replaced with an invented number. Published baselines suggest
roughly 4 to 8 real security findings would be unsurprising in an application of this shape, but that
is a literature figure, not this predictor's belief, and it is not claimed as one.

The predictions below are therefore **directional**: claims about the comparison between arms, which
is what H1 actually asserts. They are gradeable without absolute counts.

## The five predictions

| # | Question | Prediction | How it gets graded |
| --- | --- | --- | --- |
| 1 | Does the swarm find more real findings than the single review? | **More, in all categories** | Count of adjudicated true positives per arm per domain. Note this is the strongest available form of the claim: not "more overall" but "more in every domain," which fails if the single reviewer wins even one lane. |
| 2 | Does either arm miss a critical the other caught? | **The single review misses one the swarm catches** | Any finding adjudicated critical and present in exactly one arm |
| 3 | Which lane shows the biggest gap? | **Documentation, then security** | Largest difference in adjudicated true positives by domain |
| 4 | Whose precision is higher? | **The swarm.** Stated as an expectation rather than a reasoned case: "it should be" | True positives over total findings, per arm |
| 5 | Does the single reviewer flag the missing test suite? | **No** | Does arm A's report name the absence of any automated tests, in any run |

## Why prediction 5 is the sharp one

The repository has no test script and no test file. `test-reviewer` has this in its charter and
cannot miss it. A general reviewer is reading code that exists, and noticing that an entire class of
artifact is *absent* is a different cognitive move from finding a bug in something present.

If arm A flags it, the specialization argument weakens considerably: a good general prompt noticed a
missing category without being told to look for one. If arm A does not, that is the single cleanest
illustration of what charters buy, in one line a reader can check.

## Predictions the conductor did not make

Deliberately left blank rather than filled in for completeness: absolute finding counts per arm,
false-positive rates in numbers, cost ratio between arms, and stability across the three runs per
condition. No view was held on any of these. They are measured and reported; they are not graded
against a prediction.

## The result that would falsify the hypothesis

Registered alongside, in the conductor's words from the design interview:

> "It has application for customer experience FUD, but if a genuine one prompt is that good, then
> yes, it proves an agentic review is not necessary."
