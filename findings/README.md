# Findings

The evidence layer. This directory is **append-only**.

## The rule

**Nothing in here is ever edited or deleted. Not by me, not by a script, not to fix a typo.**

A finding stays exactly as recorded. A verdict stays exactly as given. When something turns out to be
wrong, the correction is a **new row** that points at the old one.

The history of what I believed, and when, is part of the result. Rewriting it would destroy the only
thing that makes my scoring checkable by someone who has no reason to trust me.

This is enforced, not promised: `scripts/check-append-only.sh` fails if any previously committed line
in this directory changed or disappeared.

The guard was tested against all three ways it could be bypassed, and it catches each:

| Attempt | Result |
| --- | --- |
| Append a new row | allowed, exit 0 |
| Edit a committed verdict in place | **refused**, exit 1, names the file and prints the removed line |
| Delete a committed evidence file | **refused**, exit 1 |

One deliberate exception: editing a line you have written but not yet committed is allowed, because it
is not yet on the record. Once committed, it is permanent.

The test row used to prove this was removed in its own commit, before any real adjudication, and that
removal is visible in the history of this repository like everything else.

## Why this matters more than it sounds

I built one of the two things being compared, and I am scoring both. The only reason anyone should
believe my numbers is that they can see every judgment I made, in the order I made it, including the
ones I changed my mind about later.

An edited ledger is worth nothing. A messy append-only one is worth quite a lot.

## What lives here

| File | What | Written when |
| --- | --- | --- |
| `findings.csv` | One row per finding from either arm, raw, before any judgment | After the runs, during normalization |
| `verdicts.csv` | One row per adjudication: finding ID, verdict, corroboration, who judged, when | During adjudication |
| `corrections.csv` | Every changed verdict: which finding, old verdict, new verdict, who challenged it, why, date | Whenever a verdict changes |
| `LEDGER.md` | The running narrative of adjudication: what I decided and what it cost me to decide it | As I go |

## How a correction works

1. The original row in `verdicts.csv` stays untouched, forever.
2. A row goes into `corrections.csv` naming the finding, the old verdict, the new one, the reason, and
   who raised it.
3. Metrics are computed from `verdicts.csv` **as amended by** `corrections.csv`, and the paper reports
   how many corrections there were.

A study that had to correct fifteen verdicts and says so is more trustworthy than one that reports
zero.

## Separation from everything else

| Layer | Where | Rule |
| --- | --- | --- |
| Raw review output | `reports/` | Never touched. Exactly what each arm produced. |
| Findings and judgments | `findings/` | Append-only. This directory. |
| Running narrative | `NOTEBOOK.md` | Append-only by day. Earlier days are never rewritten. |
| Method | `PROTOCOL.md` | Frozen once the first review runs. Changes go in the deviation log. |

The layers do not mix. Analysis never edits evidence. Narrative never edits either.

## For reviewers: where the verdicts actually are

If you were sent here to check my scoring, start with this section. It is an honest map, not the tidy
one the tables above describe.

**`verdicts.csv` and `LEDGER.md` are empty.** Adjudication happened, but it happened in JSON. The
plan said one CSV; the work produced three evidence files. I am not backfilling the CSV to match the
plan, because that would be a rewrite of the record. The files that hold the judgments are:

| File | What it holds |
| --- | --- |
| `adjudication-key.json` | The 77 distinct claims after de-duplication. For each: `claim_id`, title, domain, severity as reported, file and line, description, and `seen`, the list of (arm, condition, run) where it appeared. This is the only file that says which arm found what. |
| `evidence-01.json`, `evidence-02.json`, `evidence-03.json` | One verdict per claim, checked against the frozen commit `b38c5b0` of `idea-log`. Fields: `claim_id`, `code_matches` (`yes`, `partly`, `no`), `already_prevented` (`yes` or `no`), `verifiable_by` (`tool` or `read`), `evidence` (the actual grep, command or file:line trail), `note`. |
| `adjudication-blind.json` | The same 77 claims with the arm stripped. This is what the verdicts were written against. |
| `reconciled.json`, `reconciled-summary.txt` | The merge of duplicate slugs across arms. If you think two claims are the same defect or two different ones, this is where that call was made. |
| `armA-raw.csv`, `armB-raw.csv`, `armA-tools-raw.csv`, `armB-tools-raw.csv` | Raw extraction from the twelve reports, before de-duplication. |

The verdict rules, fixed before scoring:

- `yes`: the code is as the claim describes.
- `partly`: the problem is real but something in the claim is wrong, usually the line or one half of a
  bundled claim.
- `no`: the premise is false.
- `already_prevented: yes`: true of the named file, but another part of the system blocks the failure.
  Counted as a false positive under the strict definition in `ANALYSIS.md`, counted as true under the
  lenient one. Both are reported.

**What I am asking you to check.** Pick claims, open the source at `b38c5b0`, and decide whether the
verdict is right. The one that matters most is **C26**: a user can change an idea's original scores
after its outcome has been recorded, which corrupts the calibration view the product exists to show.
It is one PATCH handler and one schema. If that verdict is wrong, the paper's main finding is wrong.

**What I am not asking.** Whether five agents is a good idea, whether the test reviewer's thirteen
items should count as one, or whether the prompt in `prompts/arm-a.txt` was fair. Those are argued in
`ANALYSIS.md` and I would rather hear them after you have read it.

**How to report a disagreement.** One line per claim, in this shape:

```
C26, partly, line is 41 not 38, otherwise as described
```

Claim ID, your verdict, one reason. Send it however you like. Each one becomes a row in
`corrections.csv` with your name or handle as `raised_by`, and the paper reports the count.

**One more ask, before you read `prompts/arm-a.txt`.** Write the one-sentence prompt you would give a
reviewer if nobody had told you what to look for. Send it with your disagreements. The largest
confound in this study is that the single reviewer's prompt was written by the person who built the
swarm. Prompts from people who were not are the fix.
