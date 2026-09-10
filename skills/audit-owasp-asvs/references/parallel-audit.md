# Parallel audit mode - runtime recipes

Runtime-specific companions to *SKILL.md, section 5*. The protocol (coordinator
contract, worker contract, merge rules, non-destructive guardrails) is defined in the
SKILL.md; this file only covers **how to actually spawn the workers** in each agent and
provides a balanced chapter split.

Read SKILL.md section 5 before using these recipes.

## Balanced chapter split (L2/L3 full-scope, 345 requirements)

| Worker | Chapters | Requirements | Focus |
|--------|----------|-------------:|-------|
| A | V1 Encoding and Sanitization, V12 Secure Communication | 30 + 12 | injection/encoding, TLS |
| B | V2 Validation and Business Logic, V3 Web Frontend Security | 13 + 31 | validation, browser controls |
| C | V4 API and Web Service, V9 Self-contained Tokens, V10 OAuth and OIDC | 16 + 7 + 36 | API/GraphQL/WebSocket, JWT, OAuth |
| D | V5 File Handling, V11 Cryptography, V13 Configuration | 13 + 24 + 21 | files, crypto, config |
| E | V6 Authentication, V7 Session Management | 47 + 19 | auth, sessions |
| F | V8 Authorization, V14 Data Protection, V15 Secure Coding and Architecture | 13 + 13 + 21 | authz, data, architecture |
| G | V16 Security Logging and Error Handling, V17 WebRTC | 17 + 12 | logging, WebRTC |

Adjust the split per scope: for L1-only (~70 requirements) use 2-4 workers (e.g. A+B,
C+D, E+F, G), for L3 keep 7 or split the heavy E/C groups further. Trend: aim for
roughly 40-65 requirements per worker; never more than ~80.

## Common steps (both runtimes)

1. Ensure the code is available locally (existing checkout) or the coordinator clones it
   once into `git worktree` / a fresh dir first.
2. Pick the split (table above), decide the audit level (default L1).
3. Spawn one worker per group **with the worker contract in its prompt** (see the
   "Worker prompt template" below - same text for both runtimes).
4. Collect each worker's final message; if a worker's output is incomplete, resume that
   single worker (not the others) and ask it to finish.
5. Coordinator deduplicates, normalizes P0-P3, and writes the single final report.

## Worker prompt template

Use this verbatim (fill the `<...>` placeholders):

```
You are a read-only OWASP ASVS audit worker. Responsibilities:
- Scope: chapters {V1, V12} (and only these) of the repo at: <repo path>.
- Audit level: <L1 / L2 / L3>.
- Apply the audit-owasp-asvs skill workflow but ONLY on your assigned chapters.
- Hard rules (never break): read-only inspection only; never modify/edit/move/delete any
  file; never run the application, tests, builds, installs, or the project's scripts;
  never make network requests to the target; never print full secrets/credentials.
- For each scoped requirement assign a verdict: PASS / FAIL / PARTIAL / NOT-APPLICABLE /
  NOT-VERIFIABLE, and for every FAIL/PARTIAL/NOT-VERIFIABLE record evidence as
  file:line plus a short rationale.
- Assign each finding a priority P0 (Critical) / P1 (High) / P2 (Medium) / P3 (Low)
  per the skill's severity model.
- Return, as your final message: (1) one line per finding with
  `v5.0.0-Vx.y.z | <title> | <verdict> | <P#-priority> | <evidence file:line> | <impact> |
  <how to remediate>`; (2) chapter counts table (PASS/FAIL/PARTIAL/N/A/not-verifiable).
- Do not write any files. Do not duplicate other workers' chapters.
- State explicitly when an assigned chapter is NOT-APPLICABLE or NOT-VERIFIABLE.
```

## opencode recipe

- The primary agent uses the **`task` tool** (subagent) to spawn workers. Use
  `subagent_type: "general"` (built-in, suited to multi-step research tasks) - one
  `task` call per worker group.
- Launch multiple `task` calls in the same assistant turn to run workers in parallel;
  opencode executes them concurrently.
- Every worker returns its findings in its single final message; the coordinator merges
  them (if a worker's result is truncated, call `task` again with the same `task_id`
  prefixed by "resume this worker" and the missing piece).
- Workers inherit the current project working directory, so the shared clone path is the
  repo root they already see; pass the path explicitly anyway for safety.

## Claude Code recipe

- Spawn workers through the **Agent tool** (the built-in general-purpose subagent works
  with no configuration) or through custom subagents.
- Recommended: define a read-only worker subagent once in `.claude/agents/asvs-worker.md`:

```markdown
---
name: asvs-worker
description: Read-only OWASP ASVS audit worker. Audits assigned ASVS chapters and
  returns findings classified by severity. Use when running a parallel ASVS audit.
tools: Read, Glob, Grep
---

You are a read-only OWASP ASVS audit worker. Follow the worker contract passed in the
task prompt. Never edit or write files, never execute the project, never use network
tools, never print full secrets. Audit ONLY the chapters assigned to you and return
findings + chapter counts in your final message.
```

- To run workers in parallel, issue multiple Agent tool calls in a single turn (or use
  agent teams / background agents for fully async dispatch, when supported).
- `tools: Read, Glob, Grep` guarantees workers physically cannot write or run anything.
- Do not add `Task`/`Agent` to a worker's own `tools` list: subagents should not spawn
  further subagents during the audit.
- The coordinator stays in the main session and merges the results into the final report
  (only write of the whole run).

## Finishing

- Coordinator writes `<reports>/asvs-audit-<date>.md` using the template; then validates
  every cited `file:line` exists and every chapter of the target level is represented.
- If a worker flagged something as NOT-VERIFIABLE that the coordinator or another worker
  can confirm from static code, resolve it at merge time - never guess.