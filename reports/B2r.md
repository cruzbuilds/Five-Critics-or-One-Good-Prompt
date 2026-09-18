## swarm

**Verdict:** BLOCK
**Ran:** security-reviewer, docs-reviewer, infra-reviewer, test-reviewer, scope-reviewer
**Skipped:** none. All five installed and completed.

The diff base `4b825dc` is the empty tree, so the whole repo is the change. It is one 60-file "raw generated build, unreviewed" commit. No agent said it was too big to review, but test-reviewer put it at roughly 7,000 lines.

Two agents blocked. test-reviewer blocks on missing tests. docs-reviewer blocks on undocumented env vars and missing ADRs. security-reviewer and infra-reviewer returned WARN. scope-reviewer returned PASS only because there is no `engagement/` folder to check against.

### Blocking

**`.env.example` / `README.md`**
- `.env.example:2` (and `README.md:27`) [docs-reviewer] `JWT_SECRET` and `DATABASE_URL` are not explained. Nothing says they are required, that `src/lib/auth.ts:8-11` rejects a secret under 16 characters, or that a missing secret gives a 500 on login/register and a silent redirect to `/login` via `src/proxy.ts:12`. The README also says "or keep the defaults". Add a one-line description per variable. State that `JWT_SECRET` is required and must be replaced outside local dev. Remove "keep the defaults" for `JWT_SECRET`.

**`docs/decisions/` (does not exist)**
- [docs-reviewer] Hard-to-reverse choices have no ADR:
  - Hand-rolled JWT-cookie auth with bcrypt (`src/lib/auth.ts`, `src/lib/session.ts`).
  - Postgres with Prisma as the datastore.
  - Public sharing through a bearer token stored on the idea row (`src/app/api/ideas/[id]/share/route.ts`).
  - Scores computed on read, not stored (`README.md:43`).

  Write ADRs covering context, decision and consequences, for auth and the datastore at minimum. scope-reviewer said the same choices "would normally need ADRs" but did not evaluate them (see Noted).

**`src/lib/scoring.ts`**
- `src/lib/scoring.ts:23` [test-reviewer] The totals, hindsight total (null unless all four `h*` scores are set) and delta have no test. Ranking and the share view depend on them. Add unit tests, for example `hindsightTotal` with one null returns `null`, and `scoreDelta` for 4+4+4+4 against 5+5+5+5 returns 4.

**`src/lib/calibration.ts`**
- `src/lib/calibration.ts:14` [test-reviewer] `computeCalibration` has three branches and no test. It returns `null` with no hindsight, it uses `hindsight ?? predicted`, and it falls back to `i.delta ?? 0`. Test an empty list, one idea with and one without hindsight, and a mixed set with exact `avgDelta` and `count`.

**`src/lib/validation.ts`**
- `src/lib/validation.ts:3` [test-reviewer] The 1-5 ranges, trim/lowercase rules and the `outcomeSchema` restriction are untested. The README claims range enforcement "in the API (Zod)". Test boundaries 0, 1, 5 and 6, non-integers, email lowercasing, and `outcomeSchema` rejecting `ACTIVE`.

**`src/app/api/ideas/[id]/route.ts`**
- `src/app/api/ideas/[id]/route.ts:14` [test-reviewer] Ownership scoping (`findFirst({ id, userId })`) in GET, PATCH and DELETE (lines 14, 25, 50) is what isolates users. It is repeated in `outcome/route.ts:14` and `share/route.ts:15,38`. No test proves it. Add a test where user B reads, patches and deletes user A's idea and gets 404 with the row unchanged. Add a no-session test that asserts 401.

**`src/app/api/ideas/[id]/share/route.ts`**
- `src/app/api/ideas/[id]/share/route.ts:21` [test-reviewer] The share-token lifecycle has no test. POST is idempotent, `{regenerate:true}` issues a new token, and DELETE nulls it. Assert the token is stable across two POSTs, changes on regenerate, and 404s at `/api/share/[token]` after DELETE.

**`src/app/api/share/[token]/route.ts`**
- `src/app/api/share/[token]/route.ts:13` [test-reviewer] This unauthenticated endpoint has an allow-listed response and a 404 branch, and neither is tested. Assert a valid token returns the idea, the body has no `userId`, `id` or `shareToken`, and an unknown token returns 404.

**`src/app/api/ideas/[id]/outcome/route.ts`**
- `src/app/api/ideas/[id]/outcome/route.ts:26` [test-reviewer] Recording an outcome and hindsight scores is the core feature and has no test. Cover the happy path, `ACTIVE` status rejected with 400, and scores of 0 or 6 rejected with 400.

**`prisma/migrations/20260917213700_score_checks/migration.sql`**
- `:3` [test-reviewer] The DB CHECK constraints are half of the README's "enforced in both places" claim, and nothing exercises them. Add a DB-level test that inserting `differentiation = 6` is rejected.

**`src/app/api/auth/register/route.ts` / `login/route.ts`**
- `register/route.ts:19` and `login/route.ts:19` [test-reviewer] The register 409 (duplicate) and 400 branches, the login 401 branches (unknown user and wrong password, same body) and the session cookie on success are untested. Add tests for each.

### Should fix

**`.env.example` / `src/lib/auth.ts`**
- `.env.example:2` and `src/lib/auth.ts:9` [security-reviewer, docs-reviewer] The placeholder `JWT_SECRET` passes the 16-character check, and the README says to keep the defaults. An app run with it signs sessions with a publicly known key, so a login cookie can be forged for anyone whose user id is known. Reject the placeholder at startup or drop the default so a real value is required. Raise the minimum length to 32 (security-reviewer).

**`src/app/api/auth/login/route.ts` / `register/route.ts`**
- `login/route.ts:19` and `register/route.ts:19` [security-reviewer] There is no rate limiting or lockout. bcrypt cost 12 does not stop credential stuffing, and register allows unlimited account creation. Add per-IP and per-account throttling.
- `login/route.ts:20` [security-reviewer] An unknown email returns 401 immediately, while a known email runs bcrypt first. The timing difference reveals which emails are registered. `register/route.ts:20` also returns an explicit 409 for existing emails. Run a dummy `bcrypt.compare` on the not-found path, and decide whether the 409 is acceptable.

**`docker-compose.yml`**
- `docker-compose.yml:9-10` [security-reviewer] `"5432:5432"` binds all interfaces, and the credentials are the trivial `idealog/idealog`. Bind to `127.0.0.1`, or mark the file as dev-only.
- `docker-compose.yml:9-10` [infra-reviewer] The fixed host port fails to start if a local Postgres is already running. Make it overridable, for example `"${DB_PORT:-5432}:5432"`.

**`package.json` / `docker-compose.yml` (teardown)**
- `package.json:11` and `docker-compose.yml:15` [infra-reviewer, docs-reviewer] There is a `db:up` script but no `db:down`. The `idealog_pgdata` volume survives `docker compose down`, and nothing documents removing it. Add `db:down` (and `db:reset` using `down -v` if wanted) and document it in the README.

**`README.md`**
- `README.md:64` (and `:27-29`) [infra-reviewer, docs-reviewer] The production path is undefined. `db:migrate` is `prisma migrate dev`, so `pnpm build && pnpm start` against a fresh DB gives an app with no tables. The README also does not say which env vars the production run needs, or that the session cookie is `secure` only when `NODE_ENV=production` (`src/lib/session.ts:17`), so logins won't stick over plain HTTP. Add a `prisma migrate deploy` step and a "Running in production" section. infra-reviewer asks that the author confirm the intended production path.
- `README.md` (no section) [docs-reviewer] There is no limitations section. Missing password reset, no email verification, logout only clears the cookie so a JWT stays valid for 30 days (`src/lib/auth.ts:4`, `logout/route.ts`), and no tests. List them.
- `README.md:46-57` [docs-reviewer] The routes table covers pages only. The 10 API handlers are undocumented, including public `GET /api/share/[token]` and the `{ regenerate: true }` body at `share/route.ts:19`. Add an API table with method, path, auth and body.

**`src/lib/auth.ts`**
- `src/lib/auth.ts:41` [test-reviewer] `verifySessionToken` returns `null` on a bad signature, expiry or a bad payload, and `src/proxy.ts:12` relies on that. It is untested. Add tests for tampered, expired and wrong-secret tokens.

**`src/app/api/ideas/[id]/route.ts`**
- `src/app/api/ideas/[id]/route.ts:37` [test-reviewer] PATCH passes `parsed.data` straight to `prisma.idea.update`, and `ideaUpdateSchema` allows `status: "DONE"` with no outcome or hindsight. No test pins the intended transitions. Decide the behavior and pin it.

**`src/app/api/ideas/route.ts`**
- `src/app/api/ideas/route.ts:13` [test-reviewer] An invalid `?status=` value is silently ignored and returns everything. That path and the descending ranking sort are untested. Add tests for both.

**`src/proxy.ts`**
- `src/proxy.ts:6` [test-reviewer] The redirect for unauthenticated `/ideas/*` requests is untested, and the prefix match also covers any path starting with `/ideas`. Add a test that pins this.

### Handoffs nobody picked up
- `src/proxy.ts:5-6` [noticed by infra-reviewer, security-reviewer did not report it] The proxy matcher is `/ideas/:path*`, so only the `/ideas` prefix is covered. Whether that gives the auth coverage it claims was handed to security-reviewer. Its report does not address `proxy.ts`. It does say every mutating idea route calls `requireUser()`.

### Noted

**Tools and what could not run**
- security-reviewer: a Bash call was denied. gitleaks, semgrep, `pnpm audit` and the tracked-secret-file check did not run. It read all changed files by hand, so this was no secret scan of git history and no dependency audit. It asks that both be rerun before relying on the review.
- infra-reviewer: actionlint, tflint and hadolint are not installed. checkov is installed but was denied by the Bash permission, so it did not run. There are no workflows, Dockerfile or IaC in the change, so most infra checks had nothing to apply to.
- test-reviewer: there is no test runner, test files, `test` script or `scripts/check.sh`. Nothing was run and no coverage was measured. Everything was read only.
- docs-reviewer: `node_modules` is absent, so the README's "Node 20+" claim was not checked.
- scope-reviewer: `git ls-tree` was denied, so it checked only the working tree for `engagement/` and `docs/decisions/`.

**Scope PASS is not a scope check**
- Neither `engagement/` nor `docs/decisions/` exists. scope-reviewer's PASS means there was no document to check against, not that the change matches an agreed scope. It did not evaluate whether the capabilities are in scope, or whether decisions or dependencies needed ADRs. If a scope document lives elsewhere, point scope-reviewer at it.

**Agent conflicts**
- infra-reviewer said `postgres:16-alpine` is pinned to a major version, not `latest`. security-reviewer's handoff called the same tag "unpinned". Neither treated it as a finding.
- test-reviewer's handoff said `ls` showed no `.env.example` at the repo root, but security-reviewer and docs-reviewer both cite `.env.example:2`. It probably exists and was missed by an `ls` without `-a`. No agent reported it missing.
- security-reviewer flags the `README.md:10` phrase "unshareable/unguessable link" as a probable typo, and docs-reviewer also noted it. Its handoff to docs-reviewer is covered. infra-reviewer cites the same phrase at line 11.

**Other**
- Dependencies `next@16.3.5`, `jose@^6.2.12`, `nanoid@^6.0.1` and `zod@^4.6.5` are newer than security-reviewer could vouch for. Run `pnpm audit`.
- security-reviewer found no missing ownership checks, no injection sinks and no mass-assignment path. Share tokens are `nanoid(24)` and the public response is allow-listed. The session cookie is httpOnly and `sameSite: "lax"`. Logout does not revoke the JWT.
- `pnpm-lock.yaml` is committed and `packageManager` is pinned. `.env*` is gitignored except `.env.example`, which holds only placeholders.
- No tests were removed or skipped, because this is a single initial commit.

<!-- swarm run: 149s, agents from 7461982 -->
