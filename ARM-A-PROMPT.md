# Arm A: the single general reviewer

**Published verbatim. This is the entire input to arm A, besides the repository itself.**

## How to run it

```
cd /tmp/armA            # already at v0-raw
claude
```

Fresh session, Sonnet (matching the swarm's pinned `model: sonnet`), same tool access as arm B:
read, grep, glob, and a shell. Paste the prompt below, let it work, save the raw output unedited to
`reports/A1.md`. Repeat for A2 and A3 in fresh sessions.

Do not answer questions with guidance. If it asks what the application is supposed to do, the answer
is "everything you know about it is in the repository." That is true for arm B as well.

---

## The prompt

> You are reviewing a web application before it goes to production. Read the repository thoroughly —
> the source, the configuration, the database schema and migrations, the dependency manifest and the
> documentation — and report everything wrong with it.
>
> Be comprehensive. Consider correctness, security, authentication and authorization, data handling,
> input validation, error handling, dependencies, database design, infrastructure and deployment
> configuration, tests, and documentation. Consider what is missing as well as what is present: an
> absent safeguard, an untested path, or an undocumented requirement is a finding.
>
> You may run commands to investigate. Do not change any file.
>
> For every finding, give:
> - a short title
> - the severity: critical, high, medium, low, or informational
> - the file and line
> - what is actually wrong, in one or two sentences
> - the concrete failure it allows: the inputs or conditions, and the result
> - how to fix it
>
> Group the findings by severity, most severe first. If you are unsure whether something is a real
> problem, include it and say what you would need to confirm it. If you checked something and it was
> fine, do not list it.

---

## Why this prompt, and why it is not a strawman

The most common way a comparison like this gets rigged is by giving the single reviewer a weak
prompt. This one is written to be strong, and specifically to be strong in the places where the
swarm's charters would otherwise have an unearned advantage.

**It names breadth explicitly.** Security, tests, infrastructure, documentation, data handling and
dependencies are all called out by name. The swarm gets those domains through five charters; arm A
gets them in one sentence. If the swarm still wins, it wins on the depth of its instructions rather
than on arm A never having been told where to look.

**It asks for absences, not just defects.** "Consider what is missing as well as what is present"
is in there deliberately, because the sharpest pre-registered prediction in this study is whether a
general reviewer notices there are no tests. That prediction is only worth anything if arm A was
invited to look for missing things and still did not.

**It requires the same output fields the swarm's contract requires**: title, severity, file and line,
the mechanism, the concrete failure, and a fix. The comparison is then about substance rather than
formatting.

**It permits investigation.** Arm A can run commands, same as the swarm's agents can. A reviewer that
can only read is a weaker reviewer, and the point is not to weaken it.

**It discourages padding.** "If you checked something and it was fine, do not list it" keeps the
count honest on both sides, since precision is a measured outcome and a reviewer that lists its
successes inflates its apparent output.

What the prompt deliberately does **not** do: name the five agent lanes as roles, supply a checklist
of specific vulnerability classes, or hand over the application specification. Arm B gets none of
those either.
