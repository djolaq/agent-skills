<!--
  Laravel Blue Team review report template.
  Fill every section. Every finding MUST include checklist ID, evidence (file:line) and a
  concrete remediation. Delete this comment when done.
-->
# Laravel Blue Team Review Report

| | |
|---|---|
| **Project** | <repo/name> |
| **Scope** | <modules audited> |
| **Date** | <YYYY-MM-DD> |
| **Laravel / PHP** | `<version>` / `<php>` (support status: current / security-only / EOL) |
| **Method** | Non-destructive static review (read-only). No code executed, no network activity. |
| **Auditor** | <agent/tooling> |

## 1. Executive summary (for the Product Owner)

<2-4 plain-language sentences: overall posture, framework support status (plainly:
"the app runs an EOL Laravel 11 - no security patches until upgraded"), the biggest risks
an end-user or the business faces, and a one-line recommendation.>

| Severity | Count |
|----------|-------|
| P0 Critical | <n> |
| P1 High | <n> |
| P2 Medium | <n> |
| P3 Low | <n> |
| **Total findings** | **<n>** |

Top risks:
1. <risk in plain language>
2. <risk in plain language>
3. <risk in plain language>

## 2. Findings sorted by severity (P0 -> P3)

### P0 - Critical

#### 1. <Title>
- **Checklist:** `LB-<DOMAIN>-<NN>` | **CWE:** <NN> | **Verdict:** FAIL
- **Evidence:** `app/Http/Controllers/X.php:42`
- **Impact:** <what an attacker can do>
- **How to remediate:** <concrete fix in this codebase, point at files>

---

### P1 - High

#### 2. <Title>
- **Checklist:** `LB-<DOMAIN>-<NN>` | **CWE:** <NN> | **Verdict:** PARTIAL
- **Evidence:** `routes/api.php:11`
- **Impact:** <...>
- **How to remediate:** <...>

---

### P2 - Medium

#### 3. <Title>
...

### P3 - Low

#### 4. <Title>
...

## 3. Domain compliance matrix

| Domain | PASS | FAIL | PARTIAL | N/A | Not-verifiable | % |
|--------|-----:|-----:|--------:|----:|---------------:|--:|
| LB-SEC Secure Coding & Injection | | | | | | |
| LB-AUTHZ Authorization | | | | | | |
| LB-XSS Output & Client-side | | | | | | |
| LB-CONF Secrets & Configuration | | | | | | |
| LB-DATA Data, Storage & Performance | | | | | | |
| LB-AUTHN Auth & Session | | | | | | |
| LB-APP API, App & Dependencies | | | | | | |
| **Total** | | | | | | `<xx>%` |

## 4. Remediation roadmap (recommended order)

| Order | Work item (turn into issue) | Linked finding | Effort (S/M/L) |
|-------|------------------------------------------|----------------|----------------|
| 1 | <fix description> | Finding #N | S |
| 2 | <...> | ... | |
| 3 | <...> | ... | |

Suggested sprint: all P0/P1 now; P2 next; schedule the framework upgrade into the
roadmap if the app is security-only or EOL.

## 5. Not-verifiable list (require runtime / deploy checks)

| Item | Why not verifiable statically | Suggested check |
|------|-------------------------------|-----------------|
| `LB-CONF-<NN>` | `.env` values not present in the repo | Check staging/prod `.env` + deploy pipeline (APP_DEBUG, key rotation, cookie flags) |

## 6. Limitations

- Static review only; no `php artisan`/tests/traffic executed, no production inspection.
- Findings are traceable to files read during this audit; performance items (N+1) are
  flagged as guidance, not proof of production impact.
- Passing the checklist reduces risk; it does not certify the application.