# Findings

The evidence layer. This directory is **append-only**.

## The rule

**Nothing in here is ever edited or deleted. Not by me, not by a script, not to fix a typo.**

A finding, once recorded, stays exactly as recorded. A verdict, once given, stays exactly as given.
When something turns out to be wrong, the correction is a **new row** that references the old one.
The history of what I believed and when is part of the result, and rewriting it would destroy the only
thing that makes the scoring checkable by someone who does not trust me.

This is enforced, not promised: `scripts/check-append-only.sh` fails if any previously committed line
in this directory changed or disappeared. CI runs it, and so does any commit I make by hand.

## Why this matters more than it sounds

I built one of the two things being compared and I am scoring both. The only reason anyone should
believe my numbers is that they can see every judgment I made, in the order I made it, including the
ones I later changed my mind about. An edited ledger is worth nothing. A messy append-only one is
worth quite a lot.

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
