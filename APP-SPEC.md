# Application specification

**Written before generation. Committed before the coding agent saw anything, and withheld from it.**
Date: 2026-09-17. Subject: a builder's idea log.

This document exists for three reasons, and only the third is about building software.

1. It is what `scope-reviewer` holds the generated application against.
2. It is what makes "in scope" and "out of scope" decidable during adjudication, rather than a matter
   of opinion after the fact.
3. It says what the application is.

**It is not the build prompt.** The coding agent received one paragraph (Appendix A) and nothing else.
This specification is the reference the reviewers and the adjudicator use. That gap is deliberate: the
difference between what was specified and what was generated is itself a finding.

---

## 1. Purpose

A web application where a builder records ideas, scores them, and later records what actually
happened, so their own judgment becomes measurable over time.

The generic version of this is crowded. What makes this one worth building is the closed loop: not
"rank my ideas" but "here is what I predicted, here is what I built, here is whether the prediction
held." After ten entries a user has a calibration record.

**Intended user.** One builder, working alone, with ideas arriving faster than they can be built.

**Why this application, for this experiment.** It is genuinely three-tier with a real permissions
surface: accounts, private data per account, and a sharing feature that creates an authorization
question a reviewer can sink teeth into. Small enough to read end to end in an afternoon, large enough
to exercise security, infrastructure, tests, documentation and scope.

## 2. Roles and permissions

| Role | Can |
| --- | --- |
| Anonymous visitor | See the landing page. Register. Log in. Nothing else. |
| Authenticated user | Full control of their own ideas and outcomes. See nothing belonging to anyone else. |
| Recipient of a shared link | Read one idea, read-only, without an account, only if that idea was explicitly shared |

No administrator role. Nobody can read another user's ideas through the application.

## 3. Functional requirements

### Accounts

- Register with email and password. Log in, log out.
- Sessions persist across browser restarts and expire after 30 days.
- Password reset is **out of scope**. Someone who forgets their password is stuck. Recorded here so it
  counts as a known limitation rather than a missing feature.

### Ideas

An idea has: title, description, status (`open`, `building`, `built`, `dropped`), created date, and
four scores from 1 to 5 (differentiation, evidence, cost, reversibility) with a computed total.

- Create, read, update, delete.
- List own ideas, sorted by total score descending, with status filtering.
- Full-text search across title and description.
- Pagination beyond 25 ideas.

### Outcomes, the part that matters

- When an idea moves to `built` or `dropped`, the user records what actually happened and re-scores the
  same four dimensions in hindsight.
- The idea view shows predicted and actual side by side, with the difference per dimension.
- A calibration view across all closed ideas: which dimensions the user is consistently optimistic or
  pessimistic about.

### Sharing

- A read-only share link for a single idea, working without an account.
- Revocable. A revoked link stops working immediately.
- No link exists until the user creates one. Nothing is public by default.

### Validation

- Title 1 to 200 characters, required. Description up to 5,000, optional.
- Scores are integers 1 to 5, all four required, no partial scoring.
- Status transitions: `open` → `building` → `built` or `dropped`. Can return to `open` from
  `building`. Cannot leave `built` or `dropped`.
- An outcome cannot be recorded on an idea that is not `built` or `dropped`.

### Error behavior

- Validation failures name the field. Never a generic failure.
- Requesting another user's idea is indistinguishable from requesting one that does not exist, so the
  API cannot be used to discover what exists.
- No stack trace, framework version, or database error text reaches the client.

### Data deletion

- Deleting an idea deletes its outcomes and revokes its share links.
- Deleting an account deletes everything belonging to it. No soft delete.

### Explicitly excluded

Teams, workspaces, comments, notifications, email, file attachments, an admin interface, import or
export, a public directory of ideas, and any AI feature inside the product. Any of these appearing in
the code is out of scope.

## 4. Nonfunctional requirements

**None of this appeared in the build prompt.** That is the point of the section. These are the
qualities a fast generation tends to skip, and whether each reviewer notices them missing is the
measurement. Naming them to the builder would have prompted away the defects being studied.

**Security.** Passwords hashed with a current algorithm, never stored or logged recoverably. Session
tokens unguessable. Every API route touching user data checks ownership on the server, not in the
browser. Share links unguessable and revocable. No secret in the repository, in client-side code, or
in any log line.

**Privacy.** A user's ideas are visible only to that user and to holders of links they created.

**Logging.** Requests, errors and authentication events logged. Passwords, session tokens, share
tokens and full request bodies not.

**Performance.** Under two seconds for a user with 500 ideas. Not a scale problem; this exists so an
obvious N+1 query counts as a defect rather than a preference.

**Accessibility.** Keyboard reachable, labeled form fields, sufficient contrast. Not a full WCAG
commitment, and the gap is stated rather than implied.

**Documentation.** A README that lets someone clone, configure, run and tear it down without asking a
question. Every environment variable documented.

**Tests.** Automated tests covering authentication, ownership enforcement, validation, status
transitions and share-link revocation. A test that cannot fail is worse than no test.

**Running it.** Runs locally from a clean clone with documented commands. Whatever deployment
artifacts the agent chose to produce, or not produce, are reviewed as code.

## 5. Architecture constraints

**Fixed:** TypeScript throughout, no JavaScript source files. Three tiers: browser frontend, HTTP API,
persistent datastore. A relational datastore with a schema, not a JSON file. Dependencies locked with
a committed lockfile. Current Node LTS.

**Left to the agent on purpose:** framework choice on both tiers, ORM or query builder, authentication
implementation, styling, project layout, test framework, whether to containerize, and whether to write
any infrastructure or CI configuration at all. These are where a fast generation makes the decisions a
reviewer should be interested in, and constraining them would remove the thing being studied.

**Why these constraints.** TypeScript because it is readable by the author and is not the language the
swarm grew up reviewing. Three real tiers because a single-process app has no authorization boundary
and the security lane needs one. A real schema because migrations, indexes and constraints are where
infrastructure findings live.

## 6. Acceptance criteria

Checked by hand against a clean clone. The agent does not get to declare completion on its own.

- [ ] Install succeeds from a clean clone with the documented command
- [ ] The documented run command starts the application
- [ ] `tsc` reports no errors
- [ ] The test command runs and its result is recorded, whatever it is
- [ ] Register, log in, log out works
- [ ] Create, edit, delete an idea works
- [ ] Scores save and the total computes
- [ ] Status transitions follow section 3
- [ ] An outcome can be recorded on a closed idea and appears beside the prediction
- [ ] The calibration view renders with at least three closed ideas
- [ ] A share link works logged out, and stops working when revoked
- [ ] A second user's idea is not reachable by ID from the first user's session
- [ ] The final directory tree, all commands run, and all failures are recorded

**A criterion that fails is not fixed.** It is written down and the build stays frozen as it is. A
build with a failing acceptance criterion is data, both about the generation and about whether either
reviewer notices.

## 7. Nothing is deployed

The study is a static review of a repository. No cloud account, no credentials given to any agent at
any stage.

This costs nothing: every infrastructure artifact is reviewable as code with the repository sitting
still. It is also more honest, since both reviewers are reading a repository, which is what a reviewer
does, and neither is advantaged by running the system.

What the agent produced for deployment, or failed to produce, is a finding rather than a constraint.
The build prompt said nothing about deployment, so constraining the target would have decided in
advance how much infrastructure existed to review.

A demo deployment may happen later, by hand, from the remediated build, never the raw one. It is not
part of this study.

---

## Appendix A: the build prompt

Everything the coding agent received, issued once:

> Build me a web app where I can log ideas I have as a builder, score each one from 1 to 5 on
> differentiation, evidence, cost and reversibility, and see them ranked by total score. When I finish
> or abandon an idea I want to record what actually happened and score it again in hindsight, so I can
> see over time where my predictions were off. It needs accounts so my ideas are private, and I want
> to be able to share a single idea with someone by link without them signing up. Use TypeScript for
> everything, a real API and a real database, not a toy. Make it look decent.

### Why the prompt says what it says

**The rule: name the features, never name the qualities.**

The prompt is the contract the reviewers judge against. Anything whose absence should count as a
defect has to be in it, which is why the paragraph names private accounts and share links: ownership
enforcement is the security lane's main target, and a missing check is only a defect if privacy was
asked for.

Nothing about security, testing, documentation, accessibility, error handling, logging, performance or
deployment appears anywhere in it. Those are section 4, and section 4 is for the reviewers, not the
builder.

The one soft phrase, "make it look decent," is a feature request, not a quality bar. It stays because
a real person would write it.

### Rules the generation session followed

- This specification was not shown to the coding agent, nor was the protocol, nor any mention that the
  output would be reviewed.
- Fresh session, no project context, no repository conventions file.
- One session. The agent stopped when it said it was finished. No turn or token cap, because "one
  session, agent declares done" is reproducible and an arbitrary cap is not.
- **Answer, never steer.** Direct questions got short factual answers, recorded verbatim. Nothing
  volunteered, no choice corrected, no "have you considered." Anything the paragraph did not cover got
  "your call."
- No second pass. No "keep going," no "clean that up," no "add tests."
- Anything broken was left broken.

What actually happened in that session, including the one human action it required, is in
`sessions/01-build.md`.
