# TinyVault — 2026 Modernization Roadmap

## 1. Executive Summary

- **Passwords stored in plaintext in the database.** The `keys` table stores `password` as a plain `VARCHAR`. This is the single most critical security defect. Encrypt at rest using AES-256-GCM with per-row nonces before any other work proceeds.
- **Rails 3.0.7 (released 2011) is entirely unsupported and riddled with known CVEs.** The upgrade path spans three major Rails generations (3 → 4 → 5 → 6 → 7 → 8). Begin immediately; every day of delay widens the attack surface on a secrets-management application.
- **No CI pipeline exists.** There are no GitHub Actions workflows, no `.travis.yml`, no quality gates. Any commit ships untested. Add a minimal workflow first, then layer in security scanning.
- **Authlogic 3.0.2 uses SHA512+salt for password hashing** — a fast hash algorithm not designed for passwords. Migrate to bcrypt (cost ≥ 12) or argon2id.
- **No audit log, no structured logging, no secret-redaction policy beyond a single `filter_parameters` entry.** For a vault application, every read and write of a credential must be traceable and logs must never emit secret values.

---

## 2. Current State

| Dimension | Current |
|-----------|---------|
| Language | Ruby (version unspecified; Gemfile uses no `.ruby-version`; compatible with ~1.9.2 based on Rails 3.0 requirements) |
| Framework | Rails 3.0.7 (EOL since 2013) |
| ORM | ActiveRecord 3.0.7 |
| Auth | Authlogic 3.0.2 |
| Database | MySQL (gem `mysql` 2.x — the legacy C-extension, not `mysql2`) |
| Password hashing | SHA512+salt (Authlogic default for this era) |
| Credential storage | Plaintext `VARCHAR` in `keys.password` |
| Import | FasterCSV (replaced by stdlib `csv` in Ruby 1.9) |
| CSS pre-processing | LESS 1.x via the `less` gem |
| Pagination | will_paginate 3.0.2 |
| Test framework | Test::Unit via `ActiveSupport::TestCase` + Mocha for mocking |
| Coverage | rcov (unmaintained; does not work on Ruby >= 2.0) |
| CI | None |
| Deployment | Capistrano 2.x via `Capfile` + `config/deploy.example.rb` |
| Container | None |
| Dependency audit | None |
| Secret scanning | None |
| Lockfile source | `http://` (insecure RubyGems source in `Gemfile`) |

Notable code-level observations:
- `config/initializers/secret_token.rb` contains a hardcoded `secret_token` committed to the repository.
- `config/config.yml` contains SMTP credentials structure; the example file has email passwords in-repo.
- `User::Configuration` evals YAML + ERB from disk (`options.yml`) — a potential arbitrary code-execution vector if the config file is user-controlled.
- The CSV import path (`KeyImport#rows`) parses untrusted CSV and directly creates `Key` records with raw passwords.
- `render :text =>` (deprecated in Rails 4, removed in Rails 5) is used for JSONP responses in `KeysController#fill` — exposes a JSONP endpoint with no CSRF protection.
- Routes use `match` without verb restriction (Rails 3 pattern); many routes accept any HTTP verb.
- The `attr_protected` pattern is used (blacklist), which was removed in Rails 4+; the safe pattern is `attr_accessible` / strong parameters.

---

## 3. Recommendations

### 3.1 Language / Runtime / Framework

**Target: Ruby 3.3.x, Rails 7.2.x (upgrade to 8.0 once stable on 7.2)**

Ruby 3.3 is the current stable series (Ruby 3.2 is security-only; 3.4 is the newest). Rails 7.2 is the current supported series with security backports; Rails 8.0 reached general availability in late 2024.

**Migration path — do not attempt a single-hop upgrade:**

1. **Ruby 1.9 → 2.7**: The most painful step. Fix `Hash` ordered-iteration assumptions, replace `FasterCSV` with `CSV`, replace deprecated string encoding calls. Use `ruby-upgrade` tooling and run the test suite under 2.7 with `-W` verbose warnings.
2. **Rails 3 → 4.2**: This is a major rewrite step.
   - Replace `attr_protected` / `attr_accessible` with Strong Parameters (`ActionController::Parameters`).
   - Replace all `find(:all, ...)` / `find(:first, ...)` calls with `where(...)`, `first`, `all`.
   - Replace `with_scope` with `ActiveRecord::Relation` chaining.
   - Remove `ActiveRecord::Base.connection.execute` raw SQL patterns; use Arel or query objects.
   - Replace `before_filter` with `before_action`.
   - Replace `match` routes with explicit `get`/`post`/`patch`/`delete`.
   - Replace `render :text =>` with `render plain:`.
   - Drop vendor plugins (`vendor/plugins/`) — convert to gems.
   - Replace `rcov` with `simplecov`.
   - The `Gemfile` source must become `https://rubygems.org`.
3. **Rails 4.2 → 5.2**: Replace `render :update` (RJS/prototype) with Hotwire Turbo Streams or plain JSON. Remove Prototype.js. Address `HashWithIndifferentAccess` deprecations.
4. **Rails 5.2 → 6.1**: Enable `zeitwerk` autoloader. Add `config/credentials.yml.enc` to replace `secret_token`.
5. **Rails 6.1 → 7.2**: Enable strict loading, encryption (ActiveRecord::Encryption), and any remaining Zeitwerk fixes.

Each step should have a passing test suite before moving to the next. Budget 2–3 sprints per major version bump.

**Replace Authlogic** (unmaintained since ~2019) with **Devise 4.9** on Rails 7. Devise is actively maintained, has a large security community, and integrates with Warden. Set bcrypt cost to 12 in `config/initializers/devise.rb`:

```ruby
config.stretches = Rails.env.test? ? 1 : 12
```

---

### 3.2 Dependencies

**Immediate:**
- Change `source 'http://rubygems.org'` to `source 'https://rubygems.org'` — the current setting transmits the gem index over unencrypted HTTP.
- Run `bundle audit` (gem `bundler-audit`) against the current `Gemfile.lock`. Expect dozens of advisories across Rails 3 and its transitive dependencies.
- Pin Ruby version: add `.ruby-version` containing `3.3.7` (or whatever the latest 3.3.x is at time of migration).

**Ongoing:**
- Add **Dependabot** (`/.github/dependabot.yml`) for both `bundler` and `github-actions` ecosystems with a weekly cadence.
- Add **`bundler-audit`** as a CI step: `bundle exec bundle-audit check --update`.
- Add **`ruby-audit`** to catch Ruby interpreter CVEs.
- Commit `Gemfile.lock` for applications (already done here) and keep it in sync via CI.

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "bundler"
    directory: "/"
    schedule:
      interval: "weekly"
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

---

### 3.3 Cryptography

This is the highest-risk area for a vault application.

#### 3.3.1 Credential encryption at rest (P0)

The `keys.password` column is stored as plaintext `VARCHAR`. **This must be fixed before any other work.**

Use **ActiveRecord::Encryption** (available in Rails 7+) with AES-256-GCM:

```ruby
# app/models/key.rb (Rails 7+)
class Key < ApplicationRecord
  encrypts :password, deterministic: false
end
```

ActiveRecord::Encryption generates a unique 96-bit nonce per row, appends authentication tag (AEAD), and stores ciphertext in the same column (as base64-encoded JSON envelope). The master key lives in `config/credentials.yml.enc`, which is encrypted with a key that must come from the environment or a secrets manager — never committed to the repository.

For the migration:
1. Write a migration that adds a `password_ciphertext TEXT` column.
2. Write a data migration script that reads each row, encrypts with the new key, writes ciphertext, then drops the old column.
3. Rename the column after verification.

**Do not** use deterministic encryption for passwords (it leaks equality). Use non-deterministic (random nonce) exclusively.

#### 3.3.2 Password hashing (P0)

Authlogic 3.0.2 with default configuration uses `SHA512(password + salt)`. SHA-512 is a fast hash; an attacker with the database can brute-force it with GPUs at billions of hashes/second.

**Migrate to argon2id** (preferred, RFC 9106) or bcrypt (cost ≥ 12). With Devise, bcrypt is the default. For argon2id, add the `argon2` gem and configure Devise:

```ruby
# config/initializers/devise.rb
config.hasher = Devise::Encryptors::Argon2
```

Migration: on each successful login, check if the stored hash is legacy (SHA512), verify against old scheme, then re-hash and store in argon2id format. After a suitable period, invalidate all non-migrated accounts.

#### 3.3.3 Secret token / key management (P0)

- Remove the hardcoded `secret_token` from `config/initializers/secret_token.rb`. Generate a new token via `rails credentials:edit` and delete the initializer.
- The `config/config.yml` file with email passwords must not be committed. Move secrets to `config/credentials.yml.enc` or environment variables.
- Use a secrets manager (AWS Secrets Manager, HashiCorp Vault, or GCP Secret Manager) in production. Inject values via environment variables at runtime; never bake them into the image.

#### 3.3.4 Algorithm agility (P1)

Design the encryption envelope to be algorithm-agile from day one. ActiveRecord::Encryption supports `key_provider` customization. Store a `key_id` or `alg` field in the ciphertext envelope (the default envelope already does this) so that re-encryption to a new algorithm can happen without decrypting all rows at once.

Implement a **key rotation job** that:
1. Reads the current primary key and secondary (old) keys from the secrets manager.
2. For each encrypted row, decrypts with the matching key version, re-encrypts with the current primary key, saves.
3. Runs as a background job (Solid Queue / Sidekiq) in batches to avoid table locks.

```ruby
# app/jobs/key_rotation_job.rb
class KeyRotationJob < ApplicationJob
  def perform
    Key.find_each do |key|
      key.touch  # triggers re-encryption with current primary key
    end
  end
end
```

#### 3.3.5 CSV import (P1)

`KeyImport` parses user-supplied CSV and stores raw passwords. Add validation that the import file is well-formed, enforce a size limit, and ensure the imported passwords are subject to the same encryption-at-rest pipeline as manually entered credentials.

#### 3.3.6 JSONP endpoint (P0)

`KeysController#fill` exposes credentials via JSONP (`render :text => "%s(%s);" % [params[:callback], ...]`). JSONP is a 2008-era cross-domain hack that has been supplanted by CORS and is inherently dangerous — the callback parameter is user-controlled and can be used for data exfiltration via script injection. **Remove JSONP entirely.** Implement the browser extension interface over a proper CORS-controlled JSON endpoint with an API token.

#### 3.3.7 Side-channel considerations (P2)

- Use constant-time comparison for all token comparisons (`ActiveSupport::SecurityUtils.secure_compare`).
- Ensure password verification is not short-circuited before the hash is computed (both Argon2 and bcrypt do this correctly).
- Memory: Ruby does not provide zeroing of string contents; document this limitation and consider moving crypto operations to a native extension (e.g., `RbNaCl`) that explicitly zeroes key material.

---

### 3.4 Testing

**Current state:** Test::Unit shell tests with Mocha mocking. Most unit tests contain only `assert true`. Coverage tooling (rcov) does not run on any supported Ruby version.

**Targets:**

| Metric | Target |
|--------|--------|
| Line coverage | ≥ 90% |
| Branch coverage | ≥ 80% |
| Crypto path coverage | 100% (mandatory) |

**Steps:**

1. Replace `rcov` with **SimpleCov 0.22+**:
   ```ruby
   # test/test_helper.rb (top, before any require)
   require 'simplecov'
   SimpleCov.start 'rails' do
     minimum_coverage 90
     add_filter '/test/'
   end
   ```

2. Add **RSpec** (optional, but strongly preferred over Test::Unit for readability). If staying with Minitest, add `minitest-reporters` and `minitest-spec-rails`.

3. Add **factory_bot_rails** to replace fixtures. Fixtures are brittle and do not compose.

4. Add **property-based testing** for the encryption layer using `rantly` or `hypothesis-ruby`. Test that:
   - `decrypt(encrypt(plaintext)) == plaintext` for arbitrary bytestrings.
   - Mutating any byte of the ciphertext causes authentication failure (not silent decryption).
   - Encrypting the same plaintext twice produces different ciphertexts (non-determinism).

5. Add **fuzzing** for the CSV import path using `ffaker` for generating malformed CSVs (malformed quoting, BOM characters, excessively large fields, NULL bytes).

6. Add **integration tests** using `ActionDispatch::IntegrationTest` (or Capybara + Selenium) for the full login/create key/retrieve key flow.

7. Add a **security regression test** that asserts `keys.password` is never returned in plaintext from any controller action:
   ```ruby
   test "key password is not returned in JSON response" do
     get key_path(@key), as: :json
     refute_includes response.body, @key.plaintext_password
   end
   ```

---

### 3.5 CI/CD

There is no CI pipeline. Build one in GitHub Actions.

**Workflow file: `.github/workflows/ci.yml`**

```yaml
name: CI

on:
  push:
    branches: [master]
  pull_request:

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-24.04
    strategy:
      matrix:
        ruby: ["3.3"]
    services:
      mysql:
        image: mysql:8.4
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: tiny_vault_test
        ports: ["3306:3306"]
        options: --health-cmd="mysqladmin ping" --health-interval=10s

    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ matrix.ruby }}
          bundler-cache: true
      - run: bundle exec rails db:schema:load RAILS_ENV=test
      - run: bundle exec rails test
      - run: bundle exec bundle-audit check --update

  lint:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.3"
          bundler-cache: true
      - run: bundle exec rubocop --parallel

  codeql:
    runs-on: ubuntu-24.04
    permissions:
      security-events: write
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      - uses: github/codeql-action/init@4f3212b61783c3c68e8309a0f18a699764274376  # v3
        with:
          languages: ruby
      - uses: github/codeql-action/analyze@4f3212b61783c3c68e8309a0f18a699764274376
```

Key practices:
- **Pin all third-party actions to a full commit SHA**, not a mutable tag. This prevents tag-hijacking supply chain attacks.
- Use **OIDC** for cloud deployments (replace long-lived AWS/GCP keys with `aws-actions/configure-aws-credentials` with `role-to-assume`).
- Cache gems via `bundler-cache: true` in `ruby/setup-ruby`.
- Add a **matrix** for Ruby versions when approaching a Ruby version upgrade.

---

### 3.6 Code Quality

**Linting and formatting:**

Add **RuboCop 1.65+** with `rubocop-rails`, `rubocop-minitest` (or `rubocop-rspec`), and `rubocop-performance`:

```ruby
# Gemfile (development/test group)
gem 'rubocop', require: false
gem 'rubocop-rails', require: false
gem 'rubocop-minitest', require: false
gem 'rubocop-performance', require: false
```

Create `.rubocop.yml` with a `NewCops: enable` directive and enforce Rails-specific cops (`Rails/DangerousColumnNames`, `Rails/SkipsModelValidations`, etc.).

**Type checking:**

Add **Sorbet** or **RBS + Steep** for gradual typing. Start with core models (`Key`, `User`) and the encryption layer. Sorbet's `T::Struct` is idiomatic; RBS + Steep is the stdlib-aligned approach.

At minimum, add **`tapioca`** to generate RBI stubs for gems: `bundle exec tapioca gems`.

**Pre-commit hooks:**

Add `.pre-commit-config.yaml` with:
- `rubocop --autocorrect-all` (autocorrect-safe cops only)
- `bundle exec bundle-audit`
- A custom hook that rejects any commit touching `config/initializers/secret_token.rb` or adding raw secrets patterns

Or use **Lefthook** (`gem 'lefthook'`) for a Ruby-native alternative.

---

### 3.7 Observability

**Audit logging (security-critical):**

Every read and write of a credential must be logged with: who, what, when, from where, outcome. Passwords must never appear in these logs.

Implement a Rails concern `Auditable`:

```ruby
# app/models/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern

  included do
    after_create  { audit_log('created') }
    after_update  { audit_log('updated') }
    after_destroy { audit_log('deleted') }
  end

  private

  def audit_log(action)
    AuditLog.create!(
      actor_id:    Current.user&.id,
      actor_ip:    Current.ip,
      resource:    self.class.name,
      resource_id: id,
      action:      action,
      occurred_at: Time.current
    )
  end
end
```

Include in `Key`, `KeyImport`, `Membership`, `UserAccount`.

Add a separate `AuditLog` model backed by an append-only table (revoke `UPDATE` and `DELETE` privileges on it for the application DB user).

**Structured logging:**

Replace the default Rails logger with **`lograge`** for structured JSON output:

```ruby
# config/initializers/lograge.rb
Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.custom_options = lambda do |event|
    { user_id: event.payload[:user_id], request_id: event.payload[:request_id] }
  end
end
```

Ensure `config.filter_parameters` includes not just `:password` but also `:csv_data`, `:password_confirmation`, `:perishable_token`, `:single_access_token`, `:persistence_token`.

**Metrics:**

Expose a `/metrics` endpoint (Prometheus format via `prometheus-client` gem) with counters for:
- `tiny_vault_key_reads_total` (by account, never by key ID)
- `tiny_vault_auth_failures_total`
- `tiny_vault_key_rotations_total`

Never include credential values or user-identifiable information in metric label cardinality.

---

### 3.8 Security & Supply Chain

**Secret scanning:**
- Enable **GitHub Secret Scanning** on the repository (Settings → Security → Secret scanning).
- Add **`gitleaks`** as a pre-commit hook and CI step to catch historical and future secret commits:
  ```
  gitleaks detect --source=. --verbose
  ```
- Rotate the `secret_token` that is currently committed in `config/initializers/secret_token.rb`. Treat it as fully compromised.

**SAST:**
- Enable **CodeQL** for Ruby (see CI section above). CodeQL has Ruby support since 2022 and covers SQL injection, path traversal, and unsanitized user input patterns.
- Add **Brakeman 6.x** — the Rails-specific static analysis tool. Run it as a CI step:
  ```
  bundle exec brakeman --no-pager --format json -o brakeman-report.json
  ```
  Configure `brakeman.ignore` only for confirmed false positives with documented justification.

**SBOM:**
- Generate an SBOM on every release using **Syft**:
  ```
  syft . -o spdx-json=sbom.spdx.json
  ```
  Attach the SBOM as a release artifact and as a GitHub attestation (`actions/attest-sbom`).

**Dependabot:** See section 3.2.

**Memory safety:**
- Ruby itself is memory-safe (no buffer overflows in Ruby code), but native extensions (`mysql`, `rcov`) can be unsafe. Audit all gems with native extensions. The `mysql` gem (C extension) should be replaced with `mysql2` (safer, maintained) and eventually with the pure-Ruby `trilogy` adapter (introduced in Rails 7.1).
- Use `bundle exec bundler-leak` to detect known memory-leak advisories.

---

### 3.9 Container / Deployment

There is no Dockerfile. Add one using a multi-stage build.

```dockerfile
# syntax=docker/dockerfile:1.7
FROM ruby:3.3-slim AS base
WORKDIR /app
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

FROM base AS builder
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment true \
    && bundle config set --local without 'development test' \
    && bundle install --jobs=4

FROM base AS runtime
RUN groupadd --gid 1001 app && useradd --uid 1001 --gid app --no-create-home app
COPY --from=builder /app/vendor/bundle /app/vendor/bundle
COPY . .
RUN bundle config set --local deployment true
USER app
EXPOSE 3000
ENTRYPOINT ["bundle", "exec"]
CMD ["puma", "-C", "config/puma.rb"]
```

Key practices:
- **Non-root user** (`app`): the process runs as UID 1001.
- **Multi-stage build**: no build tools in the runtime image.
- **No secrets in image layers**: inject `RAILS_MASTER_KEY` and `DATABASE_URL` as environment variables at runtime.
- Mount the filesystem **read-only** in Kubernetes/Docker Compose; use an `emptyDir` for `tmp/`.
- **Sign images** with `cosign` (Sigstore) on every release push:
  ```
  cosign sign --key cosign.key ghcr.io/tkadauke/tiny_vault:${SHA}
  ```
- Use **Trivy** to scan the container image for OS and gem vulnerabilities:
  ```
  trivy image ghcr.io/tkadauke/tiny_vault:latest
  ```
- Replace Capistrano 2.x + Passenger (Phusion) with a Kubernetes deployment or a simple `docker compose` manifest. Capistrano 3.x is still viable for traditional deployments if Kubernetes is out of scope.

---

### 3.10 Developer Experience

**Local dev setup:**

1. Add a `.ruby-version` file and a `bin/setup` script:
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   bundle install
   bin/rails db:create db:schema:load db:seed
   ```

2. Add **Docker Compose** for local dependencies:
   ```yaml
   # compose.yml
   services:
     db:
       image: mysql:8.4
       environment:
         MYSQL_ROOT_PASSWORD: password
         MYSQL_DATABASE: tiny_vault_development
       ports: ["3306:3306"]
   ```

3. Add a **devcontainer** (`.devcontainer/devcontainer.json`) for VS Code / GitHub Codespaces, based on the `ruby:3.3` container feature. This gives contributors a reproducible environment in one click.

4. Replace LESS with **Sass (Dart Sass)** via `dartsass-rails`. LESS has no active Rails adapter post-Rails 4. If going full-modern, use **Tailwind CSS** via `tailwindcss-rails` with `importmap-rails` or `jsbundling-rails`.

5. Replace Prototype.js (included via `javascript_include_tag :defaults` in Rails 3) with **Hotwire (Turbo + Stimulus)** for the minimal JS interactions (AJAX key list refresh, autofill endpoint).

6. Add a `CONTRIBUTING.md` that documents: how to run tests, how to run the linter, how to add a migration, and the security disclosure policy.

---

### 3.11 AI / Agent Readiness

**CLAUDE.md is absent.** Any AI agent (Claude Code, Copilot, Cursor, etc.) operating on this codebase will lack context about safe patterns, forbidden operations, and sensitive data. This is especially dangerous for a secrets-management application.

Add `CLAUDE.md` at the repository root with the following sections:

```markdown
# CLAUDE.md

## Project Overview
TinyVault is a self-hosted credential/password vault. It stores sensitive secrets.

## Critical Security Rules for Agent Work
- NEVER log, print, or include in test fixtures real or realistic-looking passwords.
- NEVER commit secrets, tokens, or keys to the repository.
- NEVER generate code that queries `keys.password` and renders it to a log, console, or test assertion without redaction.
- NEVER bypass encryption: all writes to `Key#password` must go through the encrypted attribute.
- The `config/credentials.yml.enc` file must not be decrypted and its contents must not be shared.

## Conventions
- Models: `app/models/`, PascalCase. Use `encrypts :field` for sensitive columns.
- Controllers: strong parameters only; no `params.permit!`.
- Tests: Minitest, factory_bot fixtures, no real credentials in factories.
- Linting: RuboCop — run `bundle exec rubocop` before committing.

## Commands
- `bin/setup` — initial setup
- `bundle exec rails test` — run all tests
- `bundle exec rubocop` — lint
- `bundle exec brakeman` — security scan
- `bundle exec bundle-audit` — dependency CVE check

## What Agents Should NOT Do
- Do not generate data migrations that expose `key.password` in logs.
- Do not add `binding.pry` or `debugger` calls in production code paths.
- Do not change encryption keys or alter `config/credentials.yml.enc`.
- Do not add `serialize` columns that could bypass encrypted attribute callbacks.
```

**Conventions for future agent work:**
- Use short-lived feature branches; agents must not push directly to `master`.
- All agent-authored PRs must pass the full CI pipeline including Brakeman and bundle-audit.
- Sensitive column names (`password`, `token`, `secret`, `key`) should trigger a mandatory human review gate before merge.

---

## 4. Prioritized Roadmap

| Priority | Item | Effort | Impact |
|----------|------|--------|--------|
| P0 | Encrypt `keys.password` column at rest (AES-256-GCM via ActiveRecord::Encryption) | L (3–5 days) | Critical |
| P0 | Migrate password hashing to argon2id or bcrypt ≥ 12 | M (2–3 days) | Critical |
| P0 | Remove hardcoded `secret_token` from repository; rotate it | S (hours) | Critical |
| P0 | Fix Gemfile source to HTTPS | S (minutes) | High |
| P0 | Remove / replace JSONP endpoint in `KeysController#fill` | M (1–2 days) | High |
| P0 | Add basic GitHub Actions CI (test + bundle-audit) | S (1 day) | High |
| P0 | Add CLAUDE.md with agent safety rules | S (hours) | High |
| P1 | Upgrade Rails 3 → 4.2 (Strong Parameters, route verbs, deprecations) | XL (2–4 weeks) | High |
| P1 | Upgrade Ruby to 2.7 (prerequisite for Rails 5+ path) | L (1 week) | High |
| P1 | Add Brakeman to CI | S (hours) | High |
| P1 | Add CodeQL workflow | S (hours) | High |
| P1 | Enable GitHub Secret Scanning | S (minutes) | High |
| P1 | Implement audit log model and callbacks | M (2–3 days) | High |
| P1 | Replace rcov with SimpleCov; enforce 90% coverage threshold | S (hours) | Medium |
| P1 | Add Dependabot config | S (hours) | Medium |
| P1 | Implement structured logging with lograge + parameter redaction | S (1 day) | Medium |
| P1 | Replace `mysql` gem with `trilogy` adapter | S (hours) | Medium |
| P1 | Add RuboCop + rubocop-rails to CI | S (1 day) | Medium |
| P2 | Upgrade Rails 4.2 → 5.2 → 6.1 → 7.2 | XL (4–8 weeks total) | High |
| P2 | Replace Authlogic with Devise | L (1–2 weeks) | High |
| P2 | Add Dockerfile (multi-stage, non-root, read-only FS) | M (2 days) | Medium |
| P2 | Implement key rotation background job | M (3 days) | Medium |
| P2 | Add property-based tests for encryption layer | M (2–3 days) | Medium |
| P2 | Replace Prototype.js with Hotwire (Turbo + Stimulus) | L (1 week) | Medium |
| P2 | Replace LESS with Dart Sass or Tailwind CSS | M (2–3 days) | Low |
| P2 | Add devcontainer / Codespaces config | S (hours) | Low |
| P2 | Generate and publish SBOM (Syft) on releases | S (hours) | Medium |
| P2 | Image signing with cosign | S (hours) | Medium |
| P2 | Add Prometheus metrics endpoint | M (2 days) | Low |

**Effort key:** S = Small (< 1 day), M = Medium (2–3 days), L = Large (1 week), XL = Extra-large (2+ weeks)

---

## 5. Risks & Non-Goals

### Risks

- **Data migration risk**: Encrypting `keys.password` in place requires a rollback strategy. Run the migration on a staging database copy first. Keep the plaintext column in a shadow table for exactly 30 days post-migration, then drop it.
- **Authlogic → Devise session invalidation**: All existing sessions (persistence tokens) will be invalidated. Communicate this to users; time the migration for low-traffic periods.
- **Rails upgrade breaking changes accumulate**: Each major Rails version has breaking changes. Skipping steps (e.g., 3 → 7 directly) is extremely high-risk. The incremental path is mandatory.
- **JSONP endpoint is used by a browser extension**: Removing JSONP requires coordinating a replacement API with any existing browser extension consumers. If an extension exists in production use, deprecate JSONP with a sunset date rather than removing it immediately.
- **Test coverage starting at near-zero**: The existing test suite provides almost no safety net for refactoring. Write tests around existing behavior _before_ changing it ("characterization tests"), not after.

### Non-Goals

- **Feature development during the upgrade path**: Freeze new features for Rails 3 → 4 migration. New features on legacy Rails increase upgrade complexity.
- **Rewrite in another language/framework**: The codebase is small and domain-complete. A Rails upgrade is far less risky than a full rewrite.
- **Zero-knowledge architecture (at this stage)**: True zero-knowledge (where the server never sees plaintext passwords) requires end-to-end encryption in the browser. This is architecturally sound but represents a major UX and infrastructure change. Log it as a future initiative after encryption-at-rest is stable.
- **Multi-tenant HSM key management**: AWS CloudHSM or Google Cloud HSM integration is appropriate at enterprise scale but overengineered for this application's current footprint. The `config/credentials.yml.enc` + environment variable pattern is sufficient for now.
- **Full SOC 2 / compliance certification**: Out of scope for this roadmap, but the audit logging, structured logs, and SBOM work done here is a prerequisite.
