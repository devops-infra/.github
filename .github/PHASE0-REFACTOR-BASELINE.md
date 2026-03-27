# Phase 0 - Baseline Contract and Agent Refactor Plan

This document is the source of truth for the large refactor across selected repositories in this workspace.

## 1) Scope

### In scope

- **github actions profile**
  - `template-action`
  - `action-commit-push`
  - `action-format-hcl`
  - `action-pull-request`
  - `action-terraform-copy-vars`
  - `action-terraform-validate`
  - `action-tflint`
- **dockerized profile**
  - `docker-okta-aws-sso`
  - `docker-simple-runner`
  - `docker-terragrunt`
- **other profile**
  - `.github`
  - `template-repository`
  - `velez`
- **static profile**
  - repositories that publish static content from `site/` (to be assigned in rollout)

### Out of scope (ignored)

- `.jit`
- `.venv`
- `org-test-repository`
- `test-repo`
- any other folder not listed in scope

## 2) Meta Repository Role (`.github`)

`.github` is the organization meta repository and must contain reusable assets for all profiles:

- profile-specific config templates
- profile-specific Taskfile templates
- reusable GitHub workflow templates
- migration docs and validation contract

Canonical template locations:

- `templates/actions/*`
- `templates/dockerized/*`
- `templates/other/*`
- `templates/static/*`

## 3) Baseline Contract by Profile

## 3.1 Common requirements (all profiles)

- Use Task runner (`Taskfile*.yml`) as the primary automation interface.
- Convert all legacy `Makefile` logic to Taskfiles.
- Keep repository documentation updated with:
  - local development commands
  - CI/CD workflow behavior
  - version/release flow
- Reusable workflow references must use **versioned refs**, not `@master`.

## 3.2 GitHub workflows required in each repo

Each in-scope repo must have callers that use reusable workflows from `.github` and pinned version tags (example: `@v1`).

Required caller workflows:

1. **Auto create pull request**
   - Trigger: push to non-default branch
   - Behavior: run checks/builds as profile requires, then create/update PR
2. **Weekly dependency check (aggregated)**
   - Trigger: weekly cron
   - Behavior: one workflow that includes all checks below and creates/updates a single issue with findings:
     - dependency update checks
     - baseline validation (`validate-repo-baseline` behavior)
     - workflow lint checks (`workflow-lint` behavior)
     - stale branches/issues checks (`stale-branch-prune` and/or `stale-issue` behavior)
3. **Manual update version**
   - Trigger: `workflow_dispatch`
   - Behavior:
     - bump or set version reference
     - optional mode to skip version bump and only build/push artifacts
     - generate release outputs according to profile

Additional required workflow for static profile repositories:

4. **Deploy pages**
   - Trigger: push to default branch (`main`/`master`)
   - Behavior: publish content from `site/` to GitHub Pages

Mandatory action usage in reusable workflows (where applicable):

- `devops-infra/action-commit-push`
- `devops-infra/action-pull-request`

## 3.3 Profile-specific Taskfile sets

- **actions profile**
  - includes action metadata/version tasks and dockerized action build/release tasks
- **dockerized profile**
  - includes multi-image or single-image docker build/push/inspect tasks, dependency checks
- **other profile**
  - includes generic linting/sync/versioning tasks, and language-specific extensions where needed (for `velez`)
- **static profile**
  - includes static-site versioning, linting, and publishing support (for example GitHub Pages deploy flow)

## 4) Workflow Versioning Policy

- Reusable workflows are published with semantic tags in `.github`.
- Callers in repositories must reference a stable major line (for example `@v1`).
- `.github` maintains release notes/changelog for workflow template versions.
- Weekly dependency check includes checking pinned reusable workflow versions and opening findings issue when updates are available.

## 5) Makefile to Taskfile Migration Contract

Current repositories with Makefile migration required:

- `docker-terragrunt/Makefile`
- `docker-okta-aws-sso/Makefile`
- `docker-simple-runner/Makefile`
- `velez/Makefile`

Rules:

- first reach behavior parity in Taskfiles
- then remove/retire Makefiles
- preserve env var interface used by CI where possible

## 6) Agent Orchestration Plan

Use one coordinator and multiple workers.

### 6.1 Coordinator responsibilities

- enforce this baseline contract
- prepare/merge template updates in `.github` first
- spawn profile workers with fixed prompts and acceptance checklist
- collect worker reports and run final compliance audit

### 6.2 Worker model

- one worker per repository
- workers run in parallel after `.github` templates are finalized
- each worker performs:
  - repo classification confirmation
  - Taskfile migration/sync from profile templates
  - workflow caller alignment to versioned reusable workflows
  - README update
  - local validation commands

### 6.3 Suggested execution waves

1. **Wave A (foundation)**: `.github` only
2. **Wave B (templates)**: `template-action`, `template-repository`
3. **Wave C (actions repos)**: all `action-*` in parallel
4. **Wave D (docker repos)**: all `docker-*` in parallel
5. **Wave E (other)**: `velez`
6. **Wave F (static repos)**: static-profile repositories (when present)
7. **Wave G (audit)**: global compliance pass

## 7) Acceptance Criteria

A repository is compliant only if all are true:

- assigned profile is correct and documented
- required Taskfiles exist and tasks run
- no Makefile remains (except explicitly approved temporary transition state)
- required workflows exist as callers to `.github` templates
- caller workflows use versioned refs (not `@master`)
- weekly aggregated dependency check opens/updates findings issue
- required actions are used in PR/commit automation flows
- README is updated and accurate

## 8) Verification Checklist for Final Audit

For each repository:

1. `task help` works
2. profile-required lint task(s) pass
3. workflow files exist and call reusable workflows with versioned refs
4. manual version workflow has build-only mode
5. weekly workflow includes dependency + baseline + lint + stale checks and issue reporting
6. docs mention new automation entry points
7. static profile repos include pages deploy workflow (`deploy-pages.yml`)

Output artifact from coordinator:

- one compliance report with status per repo (`PASS` / `FAIL`) and remediation notes

## 9) Non-goals for Phase 0

- No broad per-repo code rewrites yet
- No release publishing changes outside baseline contract definition
- No migration of out-of-scope repositories
