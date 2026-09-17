# Provenance of the experimental artifact

## Four repositories: one specimen, two copies, one study

Three of them hold the code under test. The fourth holds the experiment and never contains a line of
the subject application.

| Repository | Role | Holds | Visibility |
| --- | --- | --- | --- |
| `idea-log` | **The specimen.** Frozen, sealed, never worked in by anyone. | The generated application at `v0-raw` | Private until publication |
| `idea-log-armA` | Working copy for the single general reviewer | Identical tree, own history | Private until publication |
| `idea-log-armB` | Working copy for the swarm | Identical tree, own history | Private until publication |
| `review-experiment-001` | **The study.** Not code under test. | Protocol, specification, predictions, baseline output, raw reports, findings, notebook, this file | Public from the start |

The separation between the first three and the fourth is what lets the build session be called clean:
the coding agent worked in `idea-log` and had no path to `review-experiment-001`, where the
specification and the reviewers' criteria live.

The original is not a workspace. Nobody opens it, reviews in it, or fixes anything in it. Each arm
gets a copy, and whatever happens to that copy is recorded in that copy's own git history.

At review time the two copies are byte-identical to the original, so they prove nothing on their own
beyond the hash below. They earn their existence at the remediation stage, when a coding agent fixes
arm A's findings in one and arm B's in the other. Those two repositories then diverge, and the
difference between them is the result of that half of the study. Creating them now means they were
forked from the frozen tag rather than assembled afterwards to fit a story.

## The check

Run 2026-09-17, after both copies were created and before any review:

```
$ for r in idea-log idea-log-armA idea-log-armB; do printf "%-18s " $r; git -C ~/dev/$r rev-parse HEAD; done
idea-log           b38c5b0dc51206bda7cd97fc27d0d252d6fd6a02
idea-log-armA      b38c5b0dc51206bda7cd97fc27d0d252d6fd6a02
idea-log-armB      b38c5b0dc51206bda7cd97fc27d0d252d6fd6a02
```

Three repositories, one commit hash. Both arms review identical trees, and that is demonstrated
rather than asserted.

Each copy keeps a `forked-from` remote pointing at the original it was cloned from, so the lineage is
readable from inside the repository as well as from this document.

## The frozen artifact

- Commit: `b38c5b0dc51206bda7cd97fc27d0d252d6fd6a02`
- Tag: `v0-raw`
- Message: "raw generated build, unreviewed"
- 60 files, 6,985 insertions, root commit
- Generated 2026-09-17 between 21:31:53Z and 21:51:07Z
- Nothing was fixed, tidied or reordered before the commit

## What anyone can verify independently

1. That all three repositories share one commit hash, from the command above.
2. That the frozen tree is what the build produced, since the freeze commit is the root commit and
   there is nothing before it.
3. That the predictions were sealed before any review, from the commit date on `PREDICTIONS.md` in
   this public repository.
4. That the baseline scans were run against the frozen commit, from the raw output in `baseline/`.
