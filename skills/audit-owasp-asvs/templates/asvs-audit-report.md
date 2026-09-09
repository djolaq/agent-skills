<!--
  OWASP ASVS audit report template.
  Fill out every section. Replace the <placeholders>. All findings MUST include
  evidence (file:line) and a concrete remediation. Delete this comment when done.
-->
# OWASP ASVS Security Audit Report

| | |
|---|---|
| **Project** | <project/repo name> |
| **Scope** | <repo/modules/components audited> |
| **Date** | <YYYY-MM-DD> |
| **Audit level(s)** | <L1 / L2 / L3> |
| **Standard** | OWASP ASVS v5.0.0 (official) |
| **Method** | Non-destructive static review (read-only). No code executed, no network activity. |
| **Auditor** | <agent/tooling used> |

## 1. Executive summary (for the Product Owner)

<2-4 plain-language sentences: overall security posture, the biggest risks an end-user or
the business faces, and a one-line recommendation: "address the X P0/P1 findings before
next release".>

| Severity | Count |
|----------|-------|
| P0 Critical | <n> |
| P1 High | <n> |
| P2 Medium | <n> |
| P3 Low | <n> |
| **Total findings** | **<n>** |

Compliance score (scoped requirements): **<xx>%** (PASS / (PASS+FAIL+PARTIAL)).

Top risks:
1. <risk in plain language>
2. <risk in plain language>
3. <risk in plain language>

## 2. Findings sorted by severity (P0 -> P3)

### P0 - Critical

#### 1. <Title>
- **Requirement:** `v5.0.0-V<chapter>.<section>.<req>` | **Chapter:** <name> | **Level:** L<n> | **Verdict:** FAIL
- **Evidence:** `path/to/file.py:42`
- **Impact:** <what an attacker can do>
- **How to remediate:** <concrete, project-local fix; point to the file(s) to change>

---

### P1 - High

#### 2. <Title>
- **Requirement:** `v5.0.0-V<chapter>.<section>.<req>` | **Chapter:** <name> | **Level:** L<n> | **Verdict:** PARTIAL
- **Evidence:** `path/to/file.js:17`
- **Impact:** <...>
- **How to remediate:** <...>

---

### P2 - Medium

#### 3. <Title>
...

### P3 - Low

#### 4. <Title>
...

## 3. Chapter compliance matrix

| Chapter | PASS | FAIL | PARTIAL | N/A | Not-verifiable | % |
|---------|-----:|-----:|--------:|----:|---------------:|--:|
| V1 Encoding and Sanitization | | | | | | |
| V2 Validation and Business Logic | | | | | | |
| V3 Web Frontend Security | | | | | | |
| V4 API and Web Service | | | | | | |
| V5 File Handling | | | | | | |
| V6 Authentication | | | | | | |
| V7 Session Management | | | | | | |
| V8 Authorization | | | | | | |
| V9 Self-contained Tokens | | | | | | |
| V10 OAuth and OIDC | | | | | | |
| V11 Cryptography | | | | | | |
| V12 Secure Communication | | | | | | |
| V13 Configuration | | | | | | |
| V14 Data Protection | | | | | | |
| V15 Secure Coding and Architecture | | | | | | |
| V16 Security Logging and Error Handling | | | | | | |
| V17 WebRTC | | | | | | |
| **Total (scoped)** | | | | | | `<xx>%` |

## 4. Remediation roadmap (recommended order)

| Order | Work item (turned into an issue/backlog) | Linked finding | Effort (S/M/L) |
|-------|------------------------------------------|----------------|----------------|
| 1 | <fix description> | Finding #N | S |
| 2 | <...> | ... | |
| 3 | <...> | ... | |

Suggested sprint: address all P0/P1 in the current sprint; schedule P2 in the next; backlog P3.

## 5. Not-verifiable list (require manual or dynamic testing)

| Requirement | Why not verifiable statically | Suggested check |
|-------------|-------------------------------|-----------------|
| `v5.0.0-V<x.y.z>` | <runtime-only behavior> | <manual pentest / config check / integration test> |

## 6. Limitations

- Static review only; no application execution, no active testing, no network probing.
- Absence of evidence is not evidence of control: PASS only where controls are visible in
  code or config.
- ASVS compliance is not a certification of production readiness.
- Findings are traceable to files read during this audit.