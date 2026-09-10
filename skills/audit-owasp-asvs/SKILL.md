---
name: audit-owasp-asvs
description: >-
  Conduct a non-destructive application security audit of a codebase against the official
  OWASP Application Security Verification Standard (ASVS) and produce a Markdown report,
  prioritized by severity, readable by product owners and security engineers. Use when the
  user asks to run an "owasp asvs audit", "security audit", "appsec review", "security
  code review", "ASVS compliance check", or wants findings classified by severity with
  remediation priorities. Triggers: asvs, audit, security, vuln, vulnerability, appsec,
  pentest report, compliance, securite.
compatibility: opencode, claude
metadata:
  read-only: "true"
  parallel-mode: "true"
  asvs-version: "5.0.0"
---

# OWASP ASVS Security Audit

Audit software (frontend, backend, API, mobile/web session handling, config) against the
official **OWASP Application Security Verification Standard (ASVS) v5.0.0** and produce a
**read-only, evidence-based, severity-prioritized Markdown report** that a product owner or
security engineer can read and act on.

## 1. Hard operational rules (non-destructive)

This skill **never modifies anything**. Follow these rules without exception:

- **Read-only inspection only.** Use read/find tools (read, list, glob, grep) and
  read-only shell commands (`ls`, `rg`, `git log`, `git show`, `git status`, `git diff`,
  `find`). Do **not** use edit, write, move, delete, or patch tools on project files.
- **Never run the audited application.** No `npm run`, `make`, `docker run`, `python
  app.py`, tests, compilers, or scripts from the project. Do **not** install packages.
- **No network activity against the target.** Do not `curl`/`wget`/probe the application,
  its API, or its hosts. No active pentesting, fuzzing, or scanning.
- **No side effects.** Do not start servers, daemons, or background jobs. Do not touch
  `.git` index (no `git add`/`commit`/`reset`).
- **Secrets handling.** If credentials or keys are found, do **not** log or reproduce the
  full value; record the location (file:line) and that a secret of type X was found.
- **Report is the only artifact.** Produce the report as a **new** Markdown file, never
  overwriting an existing file. Default target: `reports/` at the repo root with a unique
  name (e.g. `reports/asvs-audit-<yyyy-mm-dd>.md`) or the exact path the user supplied.
  If the user did not give a path and you are unsure, present the report in chat first and
  ask before writing it.

If a requested action would violate a rule, refuse and explain which rule blocks it.

## 2. ASVS essentials

- ASVS v5.0.0 groups requirements into **17 chapters** (V1-V17) and **345 requirements**,
  each identified `V<chapter>.<section>.<requirement>` (e.g. `V6.2.1`).
- **Levels** (from the standard):
  - **Level 1 (L1, 70 reqs)** - against opportunistic, low-effort attacks. Baseline for
    most applications.
  - **Level 2 (L2, 183 reqs)** - defense in depth against sophisticated attacks. Now the
    common best practice (roughly the old L2 recommended default).
  - **Level 3 (L3, 92 reqs)** - advanced/APT-grade controls for high-value targets
    (financial, health, security infrastructure).
- **Default audit level: L1**, unless the user asks for L2/L3.
- Cite requirements as **`v5.0.0-V6.2.1`** in reports so IDs survive standard changes.
- Full machine-readable requirement list: `references/asvs-v5.0.0-requirements.md`.

## 3. Workflow

### Phase 0 - Scope and parameters
Ask or confirm only what is not inferable from the project:
1. **Audit level** (L1/L2/L3; default L1) or full L1+L2.
2. **Scope**: whole repo, or specific modules/components (e.g. "the auth module", "the
   public API").
3. **Report destination** path (default `reports/asvs-audit-<date>.md`).
4. **Applicability hints**: web frontend? REST/GraphQL API? WebSocket? Mobile backend?
   OAuth/OIDC? WebRTC? - use to mark non-applicable chapters.
Do not stall: if the user said "just go", pick sensible defaults (L1, full repo) and start.
A scope is not required; proceed and note assumptions.

### Phase 1 - Read-only reconnaissance
- Map the repo: language, frameworks, package manifests (package.json, requirements.txt,
  go.mod, Cargo.toml, Gemfile), entry points (routes, controllers, handlers, middlewares).
- Identify: web-facing surfaces, auth mechanism, session handling, ORM/SQL usage, template
  engine, file upload code, crypto usage, logging, secrets/config files.
- Record a short tech-stack note for the report.

### Phase 2 - Applicability triage
Mark each chapter `NOT-APPLICABLE` when the component does not exist in scope (e.g.
`V17` WebRTC absent, `V10` OAuth/OIDC unused). Keep all others as `SCOPED`.

### Phase 3 - Requirement-by-requirement verification
For every scoped requirement (from L1 up to the chosen level):
- Gather **evidence** with read-only searches: `rg`/grep for patterns (e.g. `${query}`/
  string concatenation into SQL, `innerHTML`, `eval(`), read the relevant handler, review
  config (CSP/headers, cookie flags, TLS), auth/session code, crypto usage, log calls.
- Assign one verdict per `references/asvs-v5.0.0-requirements.md` requirement:
  - `PASS` - control present and effective (cite code).
  - `FAIL` - control absent or clearly ineffective.
  - `PARTIAL` - control exists but incomplete/weakly enforced.
  - `NOT-APPLICABLE` - component not in scope.
  - `NOT-VERIFIABLE` - cannot determine from static code alone (dynamic behavior, runtime
    config, external service). List these explicitly; do **not** guess.
- Record **evidence** as `path:line` pairs plus a 1-3 sentence rationale for every
  `FAIL`/`PARTIAL`/`NOT-VERIFIABLE`.
- Do not fabricate findings from templates; each FAIL must trace to observed code.

### Phase 4 - Severity and priority scoring
Each `FAIL`/`PARTIAL` finding gets a priority **P0-P3**, then findings are sorted by
priority (then by ASVS level) in the report.

| Priority | Label | Typical conditions |
|----------|-------|--------------------|
| **P0** | Critical | Remote exploitable without authentication; leads to account take-overs, RCE, injection (SQLi/XSS/SSTI) on sensitive surfaces, plaintext credential storage, leaked production secrets. |
| **P1** | High | Exploitable but requires some precondition (an authenticated role, a specific action); direct exposure of sensitive data, broken authorization on sensitive operations, weak/obsolete crypto on sensitive data. |
| **P2** | Medium | Defense-in-depth gaps and L2 failures: missing rate limiting/anti-automation, missing security logging/L2 session controls, weak TLS config, missing security headers, client-side data exposure. |
| **P3** | Low | L3/hardening only: paranoid controls, minor leakage, missing documentation/versioning of security design. |

Adjust by **likelihood × impact** in the actual context (an L1 failure on a non-sensitive
public page may drop to P2; an L3 control protecting PII can still be P1). Add the ASVS
level (L1/L2/L3) next to the requirement ID in every finding so readers see the standard's
own weight.

### Phase 5 - Generate the report
Use `templates/asvs-audit-report.md`. Required sections:
1. Header: project, date, scope, level(s), methodology, tooling (read-only static audit).
2. **Executive summary** (product-owner readable): overall posture, compliance %, count per
   severity, top 3-5 risks in plain language.
3. **Findings list, sorted P0 -> P3**: each with priority badge, `v5.0.0-Vx.y.z`, chapter,
   level, title, verdict, evidence `path:line`, impact, and **"How to remediate"** (concrete,
   project-local fix steps).
4. Compliance matrix per chapter (PASS/FAIL/PARTIAL/NA/NV counts + %).
5. **Remediation roadmap** (ordered work items the team can turn into issues).
6. Limitations: what static analysis cannot prove (NOT-VERIFIABLE list), and any
   out-of-scope areas.

## 4. Chapter inspection map (what to look for)

| Chapter | Focus of read-only checks |
|---------|---------------------------|
| V1 Encoding & Sanitization | Output encoding on template/render paths; SQL/NoSQL/OS/command injection sinks; deserialization of untrusted data; memory/string handling; canonical decoding before validation. |
| V2 Validation & Business Logic | Server-side input validation (length/type/range/format); business rule and limits enforcement; anti-automation (rate limit, captcha intent, nonce/seq). |
| V3 Web Frontend | XSS sinks (`innerHTML`, `eval`, `document.write`); `target=_blank` safety; cookie flags (HttpOnly, Secure, SameSite, `__Host-`); CSP/HSTS/X-Frame-Options/referrer-policy headers; CORS; origin checks; SRI for CDN assets. |
| V4 API & Web Service | HttpOnly structured validation; content-type enforcement; GraphQL depth/aliasing limits; WebSocket origin checks. |
| V5 File Handling | Upload type/size/magic-number validation; storage outside webroot; download path traversal & content-type; archive bomb handling. |
| V6 Authentication | Password storage (KDF: Argon2/scrypt/bcrypt/PBKDF2, no MD5/SHA1, no plaintext); password policy documentation; auth failure messaging; MFA policy; recovery flows; rate limiting; IdP integration. |
| V7 Session Management | Cookie attributes + random session id (CSPRNG); timeout/absolute timeout; logout revocation server-side; re-auth on sensitive actions; session fixation resistance. |
| V8 Authorization | Deny-by-default; object-level checks on every operation; no reliance on client-supplied roles; admin/privileged function protection; no missing checks on mutation endpoints. |
| V9 Self-contained Tokens | JWT/JWS: signature verification, alg allowlist (no `none`/`HS256` confusion), `alg`+`typ` header checks, expiry/`aud`/`iss` validation, no secret in payload. |
| V10 OAuth & OIDC | PKCE; code exchange validations; token storage; redirect URI allowlist; scope minimization; consent; DPoP/mTLS for L3; introspection; authorization server config. |
| V11 Cryptography | No weak/hardcoded algorithms (DES, RC4, MD5, SHA1 for security, ECB) in use; CSPRNG for tokens/IVs; KDF strength; key management (no keys in source); at-rest & in-use encryption intent. |
| V12 Secure Communication | TLS only for external; modern TLS 1.2+/1.3 config; HSTS; service-to-service mutual auth; no downgrade to cleartext. |
| V13 Configuration | Default credentials; debug/test endpoints disabled; env-based config; secret management (no secrets in repo/env files committed); `robots.txt`/`.git`/`.svn` exposure; info leakage (stack traces, verbose errors); DB admin interfaces not exposed. |
| V14 Data Protection | Classify data; encrypt sensitive data at rest; PII minimization; cache headers (`Cache-Control: no-store`); client-side storage of sensitive data avoided. |
| V15 Secure Coding & Architecture | Dependencies current (SBOM/manifests; known-vuln scan notes); thread safety; integer overflow handling; no use of insecure functions; architecture follows trusted patterns. |
| V16 Security Logging & Error Handling | Security events logged (success/failure of auth/authz, input validation failures); log content doesn't include secrets/passwords; logs protected against injection/tampering; generic error messages to users, detailed internal logging. |
| V17 WebRTC | TURN config security; media permission handling; signaling authentication/origin checks. |

## 5. Parallel audit mode (multiple agents)

For large codebases or full L2/L3 audits, split the work across **multiple read-only
agents** that audit different ASVS chapters in parallel and report back to one
**coordinator** agent, which produces the single final report.

When to use: repo is large, many chapters are in scope, or the user explicitly asks to
"run the audit in parallel" / "split across agents". For small projects or L1-only,
Parallel mode is optional; single-agent remains the default.

### Coordinator contract
1. **Acquire the code once.** If the project is already local, use it. If it only lives
   on GitHub or another remote, clone it **once into a fresh local directory or git
   worktree** (executed by the coordinator; the only network/write operation in the whole
   audit). Record the clone location and the commit/branch SHA audited. Servers must not
   be probed by workers.
2. **Split chapters.** Group the scoped ASVS chapters (see `references/parallel-audit.md`
   for a balanced default split). Aim for roughly equal requirement counts per worker;
   heavy chapters (V6 Authentication, V10 OAuth and OIDC) can stand alone; very small
   chapters (V9) can be joined with adjacent ones. L1-only: 2-4 workers suffices.
3. **Dispatch one worker per group**, each with this identical contract:
   - Scope: exact chapter IDs, audit level(s), and the repo path (the shared clone).
   - Rules: apply the same non-destructive rules (section 1) - read-only, no execution,
     no network, no writes, no secrets in output.
   - Method: Phase 1-4 of the workflow scoped to the assigned chapters.
   - Deliverable: return in the final message the findings for the assigned chapters in a
     structured form: per finding `v5.0.0-Vx.y.z`, chapter, title, verdict,
     evidence `path:line`, impact, P0-P3 priority, and a "How to remediate" line. Plus the
     per-chapter PASS/FAIL/PARTIAL/N/A/not-verifiable counts.
4. **Merge and produce the report.** Combine worker results: deduplicate overlapping
   findings (e.g. the same flag reported by two chapter agents), normalize priorities,
   fill `templates/asvs-audit-report.md`, and write the single report file. Workers never
   write files; only the coordinator writes the report (new path only).
5. **Validate.** Ensure every cited `path:line` exists in the repo, every priority has a
   rationale consistent with Phase 4, and no chapter of the chosen level is missing.

### Worker guardrails (apply to every worker)
- Re-read the hard rules of section 1; a worker that would modify, execute, or contact
  the audited project must stop and report back instead.
- Workers answer only their assigned chapters; do not duplicate other agents' scope.
- Return findings even when a chapter is entirely `NOT-APPLICABLE` or `NOT-VERIFIABLE`
  (state so explicitly with counts).

Runtime-specific recipes to spawn workers (opencode vs Claude Code) are kept in
`references/parallel-audit.md`; the recipes differ between agents, not the protocol.

## 6. Remediation guidance in the report

Every FAIL/PARTIAL finding must end with a concrete "How to remediate" paragraph that maps
to the project's own stack (e.g. "switch parameterized queries in `src/db/`", "add
`HttpOnly; Secure; SameSite=Strict` to the session cookie in middleware X", "move vault
secrets in `docker-compose.yml` to the secrets manager Y", "add rate limiting middleware in
`src/middleware/`"). Point at the exact file(s) that need changes so findings become
trackable work items (issue/backlog).

## 7. Limitations and honesty

- This is a **static, at-rest review**; runtime behavior, live configuration, and external
  dependencies are not executed. Mark such requirements `NOT-VERIFIABLE` rather than
  guessing.
- Absence of evidence is not evidence of control; only PASS when the control is visible in
  code/config.
- ASVS compliance is not an authorization of production readiness; state so in the report.
- All findings must be traceable to files read during the audit. Never invent file paths.

## 8. Skills resources

- `references/asvs-v5.0.0-requirements.md` - full requirement text for mapping/citing.
- `references/parallel-audit.md` - runtime-specific recipes (opencode / Claude Code) to
  run the parallel audit mode, plus a balanced chapter split.
- `templates/asvs-audit-report.md` - the report skeleton to fill in.