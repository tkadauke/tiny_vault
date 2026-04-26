# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TinyVault is a multi-tenant, web-based password/credential manager built as a Rails 3.0 application. It organizes credentials ("keys") under accounts and sites, supports per-user roles, group-based sharing of keys via memberships, key imports, and per-account user management. Authentication uses Authlogic, and the UI is rendered with ERB templates and styled with LESS.

## Tech Stack

- Language: Ruby (Rails 3.0.7-era; pre-bundler ruby version pinning)
- Framework: Ruby on Rails 3.0.7
- Database: MySQL (`mysql` gem)
- Auth: Authlogic (`acts_as_authentic`)
- Pagination: will_paginate 3.0.2
- Ordering: acts_as_list
- Slugs: permalink_fu
- CSV: fastercsv
- Stylesheets: LESS (via the `less` gem)
- Test framework: Test::Unit (Rails 3 `rails/test_help`) with Mocha and Authlogic test helpers
- Coverage: rcov (development task)
- Deploy: Capistrano (v2 style, see `Capfile` and `config/deploy.example.rb`)
- Localization: i18n with `en.yml` (and `i18n_tools` in development)

## Repository Structure

- `app/` - Rails app code
  - `models/` - ActiveRecord models (Account, Site, Key, Group, Membership, User, etc.); also a `role/` subdir with role mixins (`Role::User`, `Role::Admin`, `Role::Locked`, plus per-account roles in `role/account/`) and `user/configuration.rb`
  - `controllers/` - Standard resource controllers plus an `admin/` namespace and `admin_controller.rb`
  - `views/` - ERB templates per resource, plus `layouts/application.html.erb`, `shared/`, and `errors/`
  - `helpers/`, `mailers/`, `stylesheets/` (LESS sources)
- `config/` - Rails config
  - `application.rb`, `environment.rb`, `routes.rb`, `environments/`, `initializers/`, `locales/en.yml`
  - `config.yml` (app config consumed by `TinyVault::Config`), `options.yml` (user-facing soft settings)
  - `deploy.example.rb` (template for `deploy.rb`, which is gitignored), `deployments/` (per-deployment overrides applied via Rake task)
- `db/` - `schema.rb`, `migrate/` (15 migrations), `seeds.rb`
- `lib/`
  - `tiny_vault/version.rb` - app version + git build hash
  - `tiny_vault/config.rb` - YAML-backed config accessor (`TinyVault::Config.method_missing` reads `config/config.yml`)
  - `tasks/configuration.rake` - `configuration:apply` task that copies deployment-specific config files into `config/`
- `test/` - `unit/` model tests, `functional/` controller tests (including an `admin/` subdir), `test_helper.rb`
- `script/rails` - Rails 3 launcher
- `vendor/plugins/` - `dynamic_form`, `more` (legacy Rails plugins)
- `public/` - static assets, `favicon.ico`, `robots.txt`
- `doc/` - placeholder `README_FOR_APP`
- `Capfile`, `Gemfile`, `Gemfile.lock`, `Rakefile`, `config.ru`

## Common Commands

Install dependencies:

```
bundle install
```

Database setup (MySQL must be configured in `config/database.yml`):

```
bundle exec rake db:create
bundle exec rake db:schema:load
bundle exec rake db:seed
```

Run the app in development:

```
bundle exec rails server
# or
script/rails server
```

Rails console:

```
bundle exec rails console
```

Run all tests:

```
bundle exec rake test
```

Run a single test file:

```
bundle exec ruby -Itest test/unit/key_test.rb
bundle exec ruby -Itest test/functional/keys_controller_test.rb
```

Test coverage (uses rcov):

```
bundle exec rake test:coverage
```

Apply deployment-specific config (copies files from `config/deployments/<name>/` over `config/`):

```
DEPLOYMENT=ci bundle exec rake configuration:apply
```

Deploy via Capistrano (after creating `config/deploy.rb` from the example):

```
bundle exec cap deploy
```

## Architecture & Conventions

- Multi-tenant model: `Account` is the tenant. A `User` joins accounts through `UserAccount` (with a per-account role). Each user has a `current_account` they are scoped to.
- Domain hierarchy: `Account` has many `Site`s; each `Site` has many `Key`s. Keys are shared with `Group`s through `GroupKey`. Users join groups through `Membership`. So access flows: User -> Membership -> Group -> GroupKey -> Key.
- Roles & permissions: lightweight role system in `app/models/role/`. `User#extend_role` extends the user instance with a `Role::*` module based on the `role` column (defaults to `Role::User`). Per-account permissions are delegated to the user's `UserAccount` via `Role::User.delegate_to_account`. `Role::Base` provides an `allow` DSL used by role modules. `attr_protected :role` on `User` prevents mass-assignment of the global role.
- Authentication: Authlogic (`acts_as_authentic` on `User`, `UserSession` model). Login routes are `GET/POST /login`, logout is `DELETE /logout`. Password resets use `PasswordResetsMailer` and Authlogic perishable tokens.
- Routing: nested resources under `accounts` (`sites` -> `keys` -> `group_keys`, plus `groups` -> `memberships` and `user_accounts`). There is also a top-level admin namespace (`/admin`) for `footer_links`, `accounts`, and `users`. Root is `start#index`.
- Search/pagination convention: list-style class methods like `Account.paginate_for_list(filter, options)` and `Key.find_for_list(filter, find_options)` use a private `with_search_scope` helper that wraps `with_scope` around a SQL `LIKE` condition. New listable resources should follow this pattern.
- Param lookup: models implement `self.from_param!(param)` (defaults to `find(param)`) so controllers can swap to permalink lookup later without changing call sites.
- Configuration: read app-level settings via `TinyVault::Config.<key>` (backed by `config/config.yml`). User-facing soft settings are declared in `config/options.yml` and persisted via `SoftSetting`/`ConfigOption`. `config/database.yml` and `config/deploy.rb` are gitignored.
- Stylesheets: LESS sources live in `app/stylesheets/`, with partials prefixed by `_` and a single entrypoint `style.less`.
- Vendor plugins: `vendor/plugins/dynamic_form` and `vendor/plugins/more` are loaded via the legacy Rails plugin mechanism; do not move these into the Gemfile without verifying compatibility.

## Testing

- Framework: Rails 3 Test::Unit with Mocha and Authlogic's `test_case` helpers.
- Layout: `test/unit/` for models (mirrors `app/models/`, including `role/`), `test/functional/` for controllers (including an `admin/` subdir).
- All fixtures are loaded for every test (`fixtures :all` in `test/test_helper.rb`).
- Controller tests get `setup :activate_authlogic` plus helpers `login_with(user)`, `logout`, `assert_access_denied`, and `assert_login_required`. Use these instead of stubbing sessions manually.
- Run individual tests with `ruby -Itest <path>` as shown above; run the full suite with `rake test`.

## Notes / Gotchas

- This is a legacy Rails 3.0.7 codebase. Many APIs in use (`with_scope`, `find(:all, ...)`, `validates_presence_of`, `attr_protected`, `scope` with hash options, deprecated `:via` syntax in `match`) are removed or discouraged in modern Rails. Avoid "modernizing" idioms incidentally - the surrounding code expects Rails 3 semantics.
- The `mysql` gem (not `mysql2`) is pinned. The Gemfile uses `http://` rubygems and no Ruby version is specified - expect to need an older Ruby (1.9.x / early 2.x era) and an older Bundler to install cleanly.
- `Key.with_search_scope` deliberately replaces `.` with `_` in the user's filter query before building the SQL `LIKE` clause, because ActiveRecord 3.0 interprets dots as table-qualified column references. Preserve this behavior if you touch search.
- `config/database.yml`, `config/deploy.rb`, `tmp/`, `log/*.log`, and `db/*.sqlite3` are gitignored. Use `config/deploy.example.rb` and the `configuration:apply` rake task as templates.
- `lib/tiny_vault/config.rb` reloads `config.yml` on every access (no caching) - fine for low traffic, but don't assume it's memoized.
- `config/environment.rb` eager-requires every `.rb` under `lib/**/*.rb` after Rails initialization; new files dropped into `lib/` are autoloaded at boot.
