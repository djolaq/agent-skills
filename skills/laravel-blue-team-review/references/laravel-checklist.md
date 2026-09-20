# Laravel Bad Practices Checklist (Blue Team)

Authoritative catalog used by the `laravel-blue-team-review` skill. Read-only review only.
For every item: run the suggested searches, read the relevant code, assign a verdict
(PASS / FAIL / PARTIAL / NOT-APPLICABLE / NOT-VERIFIABLE), record `file:line` evidence,
and grade P0-P3.

Baseline severity is a starting point; adjust for likelihood x impact in the audited app.

## LB-SEC - Secure Coding & Injection

### LB-SEC-01 Raw SQL / string-built queries
- **Detection:** `DB::raw(`, `DB::select(`, `DB::statement(`, `whereRaw(`, `orWhereRaw(`,
  `selectRaw(`, `orderByRaw(`, `groupByRaw(`, `havingRaw(`; heredoc/concatenated SQL
  strings containing `$request->...`, `$input`, `$var`.
- **CWE:** 89 (SQL injection).
- **Baseline severity:** P0 if user input reaches the raw string; P1 otherwise.
- **Fix:** prefer the query builder / query bindings (`where('col', $value)`), Eloquent,
  or `DB::table()->->where()`; if raw SQL is required, use query bindings
  (`whereRaw('col = ?', [$input])`) and never interpolate values.

### LB-SEC-02 Mass assignment
- **Detection:** `Model::create($request->all())`, `->update($request->all())`,
  `->forceFill($request->input())`, empty `$fillable` combined with `$guarded = []`,
  `$request->only([...])` feeding a create/update with sensitive keys (e.g. `is_admin`,
  `role_id`).
- **CWE:** 915.
- **Baseline severity:** P1 (P0 if privilege fields are writable).
- **Fix:** define explicit `$fillable`; use Form Requests with `->validated()`; never
  mass-assign from raw request input.

### LB-SEC-03 Missing/weak input validation
- **Detection:** controllers taking `$request->input(...)` with no validation; inline
  `$request->validate()` without Form Request classes; trust of client-provided arrays
  used in DB writes.
- **CWE:** 20 (Improper Input Validation).
- **Baseline severity:** P2 (P1 on sensitive writes).
- **Fix:** typed Form Requests per action, explicit rules, whitelist values.

### LB-SEC-04 Command injection
- **Detection:** `exec(`, `shell_exec(`, `system(`, `proc_open(`, `passthru(`, backticks in
  PHP, `Artisan::call` with user input, Symfony Process with variable command with
  interpolation of request data.
- **CWE:** 78 (OS Command Injection).
- **Baseline severity:** P0.
- **Fix:** remove shell execution; if unavoidable, use arguments arrays / `escapeShellArg`
  and strict allowlists, never string-interpolate user input.

### LB-SEC-05 Server-Side Request Forgery (SSRF)
- **Detection:** `file_get_contents($url)`, `Http::get($input)`, Guzzle `$client->get($url)`
  where `$url` derives from request parameters; redirect/URL-fetch features.
- **CWE:** 918.
- **Baseline severity:** P1 (P0 on cloud/private-network contexts).
- **Fix:** allowlist schemes/hosts/ports, block metadata endpoints (`169.254.169.254`,
  localhost), validate and normalize the URL, resolve DNS and pin IPs.

### LB-SEC-06 Unsafe file uploads / storage
- **Detection:** `Store::put('/uploads', $file)` / `Storage::disk('public')` with
  user-controlled filenames; no extension/MIME/size validation; serving uploaded files
  without content-type whitelist.
- **CWE:** 434 (Unrestricted Upload).
- **Baseline severity:** P1.
- **Fix:** validate extension + MIME + magic bytes + size, generate server-side random
  filenames, store outside the webroot or on a private disk with signed download routing.

## LB-AUTHZ - Authorization & Access Control

### LB-AUTHZ-01 Missing authorization checks
- **Detection:** CRUD controllers where the resource model is fetched and acted on with no
  `$this->authorize(...)`, no Policy/Gate call, no `->where('user_id', auth()->id())`; only
  `auth()` middleware on some routes.
- **CWE:** 862 / 863.
- **Baseline severity:** P1 (P0 on destructive actions).
- **Fix:** authorize in controllers/services (policy-per-resource), check ownership
  server-side on every object-level operation.

### LB-AUTHZ-02 Insecure Direct Object Reference (IDOR)
- **Detection:** `$model = Model::find($request->id)` / `findOrFail($id)` with no ownership
  check before read/update/delete; routes like `GET /users/{id}/profile`.
- **CWE:** 639.
- **Baseline severity:** P1 (P0 when PII/records exposed).
- **Fix:** scope queries to the authenticated user, use policies with ownership checks.

### LB-AUTHZ-03 Privileged operations without checks
- **Detection:** "admin" endpoints or mutation actions (role change, export, delete)
  guarded only by UI, by a `role`/`is_admin` field writable by the user, or by
  `middleware('auth')` alone; no `Gate::authorize('...')`.
- **CWE:** 285 (Improper Authorization).
- **Baseline severity:** P1.
- **Fix:** explicit `can:` middleware / Gates on admin routes, server-side role checks.

### LB-AUTHZ-04 Route protection gaps
- **Detection:** `routes/api.php` / `routes/web.php` groups missing
  `auth:sanctum|auth:api` middleware while their controllers act on user data; public
  mutations; forgotten debug/backup routes.
- **CWE:** 306 (Missing Authentication for Critical Function).
- **Baseline severity:** P1.
- **Fix:** attach/auth middleware per route group, add tests asserting 401/403.

## LB-XSS - Output & Client-side

### LB-XSS-01 Unescaped Blade output
- **Detection:** `{!! $var !!}` in `resources/views` where `$var` can be user-controlled
  (request input, DB field edited by users); raw echo in `@php echo ... ; @endphp`;
  `->toHtml()` / `new HtmlString` built from input.
- **CWE:** 79 (Cross-site Scripting).
- **Baseline severity:** P1 (P0 on stored user content).
- **Fix:** use `{{ $var }}` (auto-escaped); sanitize with an allowlist library (HTMLPurifier)
  if raw HTML is a requirement; validate on input and encode on output.

### LB-XSS-02 Unsafe bridge to client-side JS
- **Detection:** passing PHP values into `<script>` / Inertia / Vue via string
  interpolation or `{{ }}` inside a `<script>` tag without `JSON_HEX_*` flags /
  `@json()`; `window.Conf = {{ $conf }}` patterns.
- **CWE:** 79.
- **Baseline severity:** P1.
- **Fix:** use `@json($var)` (Jsonable) with hex-encoding flags; keep user data out of
  inline `<script>`.

### LB-XSS-03 Missing escaping in error/partial views
- **Detection:** error messages, query values re-echoed in views (`{{ request('q') }}`
  used as pre-filled input value without escaping - note `{{ }}` escapes, but values placed
  in `value="..."` attributes must be escaped for the attribute context).
- **CWE:** 79.
- **Baseline severity:** P2.
- **Fix:** always output through Blade's `{{ }}`, use `@safe`-style helpers for attributes.

## LB-CONF - Secrets & Configuration

### LB-CONF-01 Committed secrets / .env
- **Detection:** `.env` tracked in git (`.gitignore` missing `/.env`); real credentials in
  `.env.example`; `APP_KEY`, DB passwords, API keys, `MAIL_PASSWORD`, `AWS_SECRET`, Stripe
  keys in committed config or code.
- **CWE:** 798 (Hard-coded Credentials).
- **Baseline severity:** P0 (rotating).
- **Fix:** remove from repo and history, add `/.env` to `.gitignore`, use a secrets manager
  / CI vault, rotate all exposed credentials.

### LB-CONF-02 APP_DEBUG enabled in production
- **Detection:** `.env.example` with `APP_DEBUG=true` as default; config referencing
  `env('APP_DEBUG', true)`; no CI/deploy override forcing false in prod.
- **CWE:** 489 (Active Debug Code) / 200 (Information Disclosure).
- **Baseline severity:** P1.
- **Fix:** default `APP_DEBUG=false`, gate by `APP_ENV`, enforce in deployment pipeline.

### LB-CONF-03 Weak or missing APP_KEY / encryption key
- **Detection:** no `APP_KEY` with `base64:` prefix; default/unset key; `crypt()`/signed
  URLs/`Crypt::` used without a strong key; `php artisan key:generate` never run in CI.
- **CWE:** 310 (Cryptographic Issues) / 320.
- **Baseline severity:** P1.
- **Fix:** generate via `php artisan key:generate`, store in env, unique per environment.

### LB-CONF-04 Insecure session/cookie configuration
- **Detection:** `config/session.php` with `'secure' => env('SESSION_SECURE_COOKIE', false)`
  not enforced behind an env default, `'http_only' => false`, `'same_site' => 'lax'` for
  sensitive actions; cookies without `Secure; HttpOnly; SameSite`.
- **CWE:** 614 (Sensitive Cookie without Secure/HttpOnly).
- **Baseline severity:** P2.
- **Fix:** `SESSION_SECURE_COOKIE=true`, `SESSION_HTTP_ONLY=true`, `same_site` per flow,
  and `__Host-`-style naming where supported.

### LB-CONF-05 Environment misuse
- **Detection:** `env(...)` called outside `config/` files (in controllers, models,
  routes, blade); `config()` bypassed for env; hardcoded domain/IP lists used as config.
- **CWE:** - (misconfiguration).
- **Baseline severity:** P3 (P2 when a secret is read via `env()` in app code - e.g.
  `env('DB_PASSWORD')` in a controller).
- **Fix:** access config via `config('...')`, keep `env()` calls inside `config/*`,
  ensure `config:cache` in deploy.

## LB-DATA - Data, Storage & Performance

### LB-DATA-01 N+1 queries
- **Detection:** loops calling `$model->relation` / `->get()`/`->first()` per iteration
  outside `->with(...)`; no `with()`/`load()` eager loading in listing/index controllers;
  raw relationship fetches (`$owner->posts`).
- **CWE:** - (performance).
- **Baseline severity:** P2 on hot paths, P3 on cold paths.
- **Fix:** eager load (`with('orders')`, `load(...)`), use `cursor()` for big sets, query
  counts via `withCount`.

### LB-DATA-02 Sensitive data at rest without encryption
- **Detection:** PII/card-like/token/credentials stored as plain attributes; `casts`
  `'encrypted'`/`'encrypted:array'` not used where appropriate; full credit-card digits /
  documents stored.
- **CWE:** 312 (Cleartext Storage of Sensitive Information).
- **Baseline severity:** P1 on regulated data (PII), P2 otherwise.
- **Fix:** cast to encrypted / application-layer encryption, minimize collection,
  document retention.

### LB-DATA-03 Public storage exposure
- **Detection:** `Storage::disk('public')` storing user/documents; symlink
  `public/storage` exposing private files; files served by URL without auth/z.
- **CWE:** 552 (Files or Directories Accessible to External Parties).
- **Baseline severity:** P1 (P0 on regulated documents).
- **Fix:** private disk + controller serving files with ACL/policy checks, signed/cacheable
  discovery disabled.

### LB-DATA-04 Unbounded queries / missing pagination
- **Detection:** `Model::all()`, `->get()` on tables without `->paginate()/->limit()`;
  large exports/dumps without chunking.
- **CWE:** - (performance/availability).
- **Baseline severity:** P3 (P2 if denial-of-service plausible).
- **Fix:** paginate, `chunkById`, add limits, index the queried columns.

## LB-AUTHN - Authentication & Session

### LB-AUTHN-01 Weak password storage
- **Detection:** `md5(`, `sha1(`, `crypt` without algorithm, custom hashing without
  randomness, storing plaintext `password` columns; bcrypt cost < 10 / no KDF upgrade path.
- **CWE:** 916.
- **Baseline severity:** P1 (P0 on plaintext).
- **Fix:** `Hash::make` / Argon2id, migrate legacy hashes on login, enforce min length +
  breach check policy.

### LB-AUTHN-02 Missing brute-force protection
- **Detection:** login/OTP/reset endpoints with no `throttle:...` middleware, no lockout,
  no `RateLimiter`; `Auth::attempt` directly.
- **CWE:** 307 (Improper Restriction of Excessive Authentication Attempts).
- **Baseline severity:** P2 (P1 on admin login).
- **Fix:** `Route::post(...)->middleware('throttle:5,1')`, custom `RateLimiter` on
  credentials, lockout + monitoring.

### LB-AUTHN-03 CSRF protection disabled
- **Detection:** middleware excluding `web` group; `$except = ['*']` / routes listed in
  `VerifyCsrfToken::$except`; API-style POSTs handled under `web` without token; react/vue
  calls posting without XSRF headers.
- **CWE:** 352.
- **Baseline severity:** P1.
- **Fix:** keep `VerifyCsrfToken` for session-based routes, use `sanctum` CSRF flow for
  SPA/API, require `Origin`/`Sec-Fetch-Site` checks on state-changing endpoints.

### LB-AUTHN-04 Missing session regeneration after login
- **Detection:** `Auth::login()`/`attempt` without `$request->session()->regenerate()`;
  forged/`session_start` reuse across privilege changes.
- **CWE:** 384 (Session Fixation).
- **Baseline severity:** P2.
- **Fix:** regenerate the session ID on successful login and on privilege change.

### LB-AUTHN-05 Insecure "remember me" / persistent auth
- **Detection:** `Auth::attempt($c, true)` storing a static remember token without
  rotation/revocation on password change; remember tokens not invalidated on logout.
- **CWE:** 287 / 613.
- **Baseline severity:** P3.
- **Fix:** rotate remember tokens on login/logout/password change, expire them.

## LB-APP - API, Application & Dependencies

### LB-APP-01 Unprotected API routes
- **Detection:** `routes/api.php` groups not wrapped in `auth:sanctum`/`auth:api`,
  exposing user data/mutations; no `Sanctum`/`Passport` configured but token-based routes
  used; API keys in query strings.
- **CWE:** 306.
- **Baseline severity:** P1.
- **Fix:** middleware per route group, authenticate API clients, require tokens for
  anything user-scoped.

### LB-APP-02 API rate limiting absent
- **Detection:** API routes without `throttle:` and no `RateLimiter::for('api')`; costly
  endpoints (search, export) unthrottled.
- **CWE:** 770 / 799.
- **Baseline severity:** P2.
- **Fix:** default `throttle:api`, granular limits per route, per-IP and per-user.

### LB-APP-03 Multi-step writes without transactions
- **Detection:** several `->save()`/`create()` calls not wrapped in
  `DB::transaction(...)` / `transaction(function () { ... })` in features that must be
  atomic (payments, signup, inventory).
- **CWE:** - (integrity).
- **Baseline severity:** P3 (P2 on money-involved flows).
- **Fix:** wrap in transactions, add lockForUpdate where needed.

### LB-APP-04 Unsupported / outdated framework & PHP
- **Detection:** `composer.json` `laravel/framework` version, `php` requirement, and
  `composer.lock` presence vs. the official support policy (security fixes ~2 years).
  Reference (Sep 2026): 13 = current (sec until 2028-03), 12 = security-only (until
  2027-02), **11 and older = EOL**. PHP 8.1 and lower = EOL.
- **CWE:** 1104 / 637 (use of unsupported components).
- **Baseline severity:** P1 for EOL framework/PHP, P2 for security-only, P3 for pinned
  known-vulnerable packages without `composer.lock`.
- **Fix:** upgrade to a supported major, run `composer audit` / `composer update` in CI,
  commit `composer.lock`, subscribe to security advisories.

### LB-APP-05 Missing lock file / dependency hygiene
- **Detection:** no `composer.lock` committed; `composer require` without version bounds;
  abandoned/unmaintained packages in `composer.json`.
- **CWE:** - (supply chain).
- **Baseline severity:** P3 (P2 if PHP packages with known vulns).
- **Fix:** commit `composer.lock`, pin versions, `composer audit` in CI, replace abandoned
  packages.

## Summary table (for the report matrix)

| Domain | Items | Severity range |
|--------|-------|----------------|
| LB-SEC | LB-SEC-01..06 | P0 - P1 |
| LB-AUTHZ | LB-AUTHZ-01..04 | P1 - P2 |
| LB-XSS | LB-XSS-01..03 | P1 - P2 |
| LB-CONF | LB-CONF-01..05 | P0 - P2 |
| LB-DATA | LB-DATA-01..04 | P1 - P3 |
| LB-AUTHN | LB-AUTHN-01..05 | P0 - P2 |
| LB-APP | LB-APP-01..05 | P1 - P3 |