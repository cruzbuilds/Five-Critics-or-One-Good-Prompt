# Raw reports

Exactly what each arm produced, unedited. **Nothing in here is ever changed.**

Not reformatted, not spell-corrected, not trimmed of the parts that make either arm look bad. If a run
produced a malformed report, the malformed report is what lives here, and the failure log says so.

| File | What |
| --- | --- |
| `A1.md`, `A2.md`, `A3.md` | The single general reviewer, three runs |
| `B1.md`, `B2.md`, `B3.md` | The swarm's merged verdict, three runs |
| `B1-agents/`, `B2-agents/`, `B3-agents/` | Each agent's individual raw output, including anything the orchestrator dropped when merging |
| `runs.csv` | One row per run: ID, condition, start, end, tokens, cost, tool calls, completion status |

Failed and incomplete runs are preserved with the rest. They are part of the operational evidence, and
deleting them because they are inconvenient is the most common way a study like this quietly lies.
