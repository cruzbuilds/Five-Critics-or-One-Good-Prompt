# Session 01 — generation

## Metadata
- UTC start:                 2026-09-17T21:31:53Z
- UTC end:                   2026-09-17T21:51:07Z  (19m 14s wall clock from start)
- Tool:                      Claude Code v2.1.274
- Model:                     Sonnet 5
- Plan / billing:            Claude Pro
- Approvals:                 auto mode on (permission prompts handled automatically)
- Internet access:           yes
- Working directory:         ~/dev/idea-log
- OS / node / npm:           macOS 14.5 (23F79), arm64 / node v24.6.0 / npm 11.5.2
- Repo:                      idea-log
- Starting commit:           (empty, git init only)
- Ending commit:             b38c5b0dc51206bda7cd97fc27d0d252d6fd6a02
- Tag:                       v0-raw

### Note on the model
Before `/login` the client reported "Opus 5 (1M context), API Usage Billing". After `/login` it
reported "Sonnet 5, Claude Pro", which is the account default and the model that actually ran.
Recorded because the pre-login banner is misleading and someone reading a screenshot would get it
wrong.

Consequence for the review arms: the swarm's Claude adapters pin `model: sonnet`, so arm B runs on
Sonnet. Arm A must therefore also run on Sonnet, or the study measures Opus against Sonnet rather
than one reviewer against five.

## Isolation of the build session

What the builder could and could not see, and how each was established.

| Channel | State | How verified |
| --- | --- | --- |
| Experiment material (protocol, spec, paper, playbook) | Not reachable | Those live in a claude.ai Project and in `review-experiment-001`. The build ran in a terminal with no project attachment and a working directory of `~/dev/idea-log`. |
| This conversation's history | Not reachable | Separate session, separate surface, no shared context |
| Repository-level instructions (`CLAUDE.md`, `AGENTS.md`, `.kiro/`) | None existed | `~/dev/idea-log` contained only `.git` at session start |
| Prior session history for this directory | None | The directory was created the same evening |
| User-level agents (`~/.claude/agents/`) | Empty | `ls -la ~/.claude/agents/` returned nothing |
| User-level instructions (`~/.claude/CLAUDE.md`) | Does not exist | `cat ~/.claude/CLAUDE.md` returned nothing |
| Browser access | Declined | Client offered the Chrome extension mid-run; answered "Not now" |

**Honest note on timing.** The two user-level checks were run shortly after the build began, not
before it. They are reported as verified-late rather than verified-first. Both came back empty, so
nothing reached the builder, but the checks belonged before the first prompt and did not happen
there.

**The one thing that cannot be ruled out from the outside:** whatever the model carries from its own
training about applications of this kind. That is true of any study of this shape and is not a
contamination of this experiment specifically.

## The prompt issued
(verbatim, exactly as pasted)

## Exchange log
Every question and answer, in order, verbatim.

- [~21:4x] AGENT ASKED: to log in to Docker Desktop so it could continue.
- [~21:4x] I DID: logged in to Docker Desktop. No guidance given, no other exchange.
  Note: this is a human action inside the build, not an answer to a design question. It is recorded
  as an intervention because the build could not proceed without it. Nothing about the application
  was discussed.
- [HH:MM] AGENT ASKED:
- [HH:MM] I ANSWERED:

- [~21:5x] CLIENT OFFERED: "Claude wants to use your browser" — an offer to install the Claude in
  Chrome extension so the session could navigate sites, click buttons and fill forms.
- [~21:5x] I CHOSE: "Not now." Declined, and did not choose "Don't ask again," which would have
  written a persistent setting outside the experiment.
  Note: a client capability offer, not a design question, so declining is not steering. Recorded
  because the tool set available to the builder is a condition of the run: this build had no browser
  access, so it could not navigate documentation or verify its own work through a browser.

### Unprompted choices observed
- Chose to containerize. The build prompt says nothing about Docker, deployment, or infrastructure.
  The agent decided on its own that this application needed containers, which means the
  infrastructure lane has real artifacts to review rather than nothing.

## What it did

Duration: "Cogitated for 12m 32s", finished 5:48 PM local.

### The agent's own summary, quoted verbatim

> The app is built and fully smoke-tested. Summary:
>
> **Stack:** Next.js 16 (App Router) + TypeScript, PostgreSQL via Prisma (pinned to stable 6.x —
> Prisma 7 just shipped and requires driver adapters, not worth the churn here), Tailwind v4, and
> hand-rolled cookie/JWT auth (jose + bcryptjs) rather than pulling in a full auth library.
>
> **What's there:**
> - Accounts (register/login/logout), private ideas scoped per-user, enforced in every API route and
>   again in src/proxy.ts (Next's new middleware convention).
> - Ideas scored 1–5 on differentiation, evidence, cost, reversibility — validated by Zod *and*
>   Postgres CHECK constraints — ranked by total score on /ideas, with a "Calibration" panel showing
>   where your hindsight scores diverge from predictions, per dimension.
> - Hindsight flow: mark an idea Done/Abandoned, write what happened, re-score the same four
>   dimensions, see the delta.
> - Share-by-link (/s/[token]) — no signup needed, revocable, rotatable, and scoped to only the
>   fields the owner wrote (no user IDs, emails, or tokens leaked).
>
> I tested the full flow with curl against a live dev server: register/login, cross-user privacy
> (404s, not leaky 403s), create/rank ideas, record hindsight, share/revoke a link, and confirmed
> unauthenticated requests get redirected or 401'd correctly. tsc, eslint, and next build are all
> clean.
>
> **To run it:** Postgres is already up in Docker (idea-log-db-1). pnpm dev and go to
> localhost:3000. .env is already populated with a generated JWT_SECRET; .env.example is
> committed-ready for anyone else setting this up.
>
> Nothing is committed to git yet, per your call — it's all sitting as untracked files whenever
> you're ready to review and commit.

Earlier, at the commit prompt, it also claimed: "The app is built, tested end-to-end, and ready."

### Claims to check, not to trust

Every line above is the builder's account of its own work. None of it is evidence. The ones worth
checking against the frozen repository and the baseline scans:

| Claim | How it gets checked |
| --- | --- |
| "fully smoke-tested" / "tested end-to-end" | The testing described is manual curl against a dev server. Does any automated test suite exist in the repository? Is there a test script at all? A build with no repeatable tests is a very different artifact from what "tested end-to-end" suggests. |
| "enforced in every API route and again in src/proxy.ts" | Every route, or most routes. This is the security lane's central question. |
| "cross-user privacy (404s, not leaky 403s)" | Verifiable by hand against the acceptance criteria. |
| "revocable, rotatable, and scoped to only the fields the owner wrote" | Check what the share endpoint actually serializes. |
| "tsc, eslint, and next build are all clean" | Re-run all three in the baseline scan and record exit codes. |
| "hand-rolled cookie/JWT auth rather than pulling in a full auth library" | Its own choice, unprompted, and the highest-risk decision in the build. |
| ".env is already populated with a generated JWT_SECRET" | Is `.env` gitignored? Whether the agent protected the secret it generated is itself a finding. |

- Architecture it chose: Next.js 16 App Router, TypeScript throughout, PostgreSQL via Prisma 6.x,
  Tailwind v4, Docker for the database. Containerization and the database choice were unprompted.
- Reason it gave for a version pin: Prisma 7 "just shipped and requires driver adapters, not worth
  the churn here." Unprompted reasoning about dependency churn.
- Major dependencies: next, react, typescript, prisma, tailwind, jose, bcryptjs, zod.
- Did it test its own work before stopping: yes, by hand, with curl against a running dev server.
  Whether it wrote automated tests is a separate question the freeze will answer.
- Did it review its own work before stopping: no review pass was requested or reported.
- Commands it ran that failed, and what it did next: FILL IN if any were observed.
- Retries, loops, restarts: FILL IN.

## Things I noticed and did not say
(the whole point of this section is that it stays empty of actions)
- [HH:MM]

## Freeze result

- Commit: `b38c5b0dc51206bda7cd97fc27d0d252d6fd6a02`, message "raw generated build, unreviewed"
- Tag: `v0-raw`
- 60 files, 6,985 insertions, root commit
- Working tree clean after commit, nothing untracked left behind
- `.env` correctly excluded by `.gitignore` (`.env*` with `!.env.example`). The agent protected the
  JWT_SECRET it generated. Recorded as a point in its favour.
- Nothing was fixed, tidied or reordered before the commit.

### What is in the repository

API routes (9): auth register, login, logout, me; ideas list and detail; outcome; share create;
share read by token.
Pages (7): landing, login, register, ideas list, idea detail, shared idea view, layout.
Components (10). Library modules (9): api-auth, auth, calibration, prisma, scoring, serialize-idea,
session, types, validation. Plus `src/proxy.ts`.
Database: Prisma schema and two migrations, `init` and `score_checks`.
Config: docker-compose for Postgres, eslint, postcss, next, tsconfig, pnpm lockfile.
Docs: README, and an `AGENTS.md` and `CLAUDE.md` the agent wrote for itself, unprompted.

### What is not in the repository

- **No tests of any kind.** No test directory, no test file, no test framework, no test script.
  The agent's claims of "fully smoke-tested" and "tested end-to-end" refer to curl commands run by
  hand against a dev server during the session. Nothing in the repository can reproduce them.
- No CI. No `.github/` directory at all.
- No Dockerfile for the application. `docker-compose.yml` runs the database only.
- No LICENSE.

These absences are recorded now, before either review arm runs, because "did the reviewer notice
what is missing" is one of the study's questions and the answer has to be established in advance.

## Cost and effort
- Wall clock:                19m 14s total session; agent reported 12m 32s of its own work
- Active human time:
- Input tokens / output tokens:
- Estimated cost:
- Number of prompts I sent:  1 (the build paragraph). Plus one Docker Desktop login, one declined browser-extension offer, and one menu choice to leave the work uncommitted.

## Freeze
- Commit hash:               b38c5b0dc51206bda7cd97fc27d0d252d6fd6a02
- Tag:                       v0-raw
- Working tree clean:        yes
- Untracked files left:      none
- Lockfile committed:        yes (pnpm-lock.yaml)

## Acceptance criteria
| # | Criterion | Pass/Fail | Note |
| --- | --- | --- | --- |

## Baseline scans

Run once against `v0-raw` (`b38c5b0`), 2026-09-17, before either review arm. Raw output in
`baseline/`.

| Tool | Command | Exit | Result | File |
| --- | --- | --- | --- | --- |
| TypeScript 5.9.3 | `pnpm exec tsc --noEmit` | 0 | clean, no output | `baseline/tsc.txt` |
| ESLint 9 (eslint-config-next 16.3.5) | `pnpm exec eslint .` | 0 | clean, no output | `baseline/eslint.txt` |
| Next.js 16.3.5 build | `pnpm exec next build` | 0 | compiled, 16 routes, static generation succeeded | `baseline/build.txt` |
| pnpm test | `pnpm test` | 1 | **no test script exists in package.json** | `baseline/tests.txt` |
| pnpm audit 10.29.1 | `pnpm audit` | 1 | **1 high severity**: deepmerge-ts <8.0.0 stack exhaustion on recursive object graphs, via `prisma > @prisma/config > deepmerge-ts`, GHSA-ggr8-5vv4-36mx | `baseline/audit.txt`, `audit.json` |
| tracked-secret scan | `git ls-files \| grep -Ei '.env\|.pem\|.key\|credential'` | 0 | only `.env.example`. No secret material tracked. | `baseline/secret-scan.txt` |

### What the baseline establishes

**The agent's verifiable claims held.** It said `tsc`, `eslint` and `next build` were all clean, and
all three are. That is worth stating plainly: where the claim was machine-checkable, it was true.

**The unverifiable claim did not.** "Fully smoke-tested" and "tested end-to-end" describe curl
commands typed during the session. `package.json` has no `test` script and the repository contains no
test file, so `pnpm test` exits 1 with nothing to run. Both statements are true in the sense the
agent meant them and false in the sense a reader would take them. This is the single most
interesting artifact of the build so far.

**The floor.** The dependency advisory is free: `pnpm audit` finds it in two seconds. If either
review arm reports it, the finding is recorded but does not count as evidence that arm found
anything a scanner would not have. Same for any type error or lint hit, of which there are none.

### Correction to the record

The first run of these scans, at 21:52Z, captured exit codes with `$?` after a `tee` pipeline, which
reports `tee`'s status rather than the command's. Every code came back `0`, including for commands
that had failed. The scans were re-run at 22:0xZ with the status captured directly. Both sets of raw
output are on disk; the table above is from the corrected run.

Recorded rather than silently overwritten, because a study that hides its own measurement bugs has
no standing to report anyone else's.

## Deviations from the protocol
(if none, write "none")
