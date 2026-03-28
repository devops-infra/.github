# Centralized Workflows for devops-infra

This directory documents reusable workflow architecture in the `.github` meta repository.

## Profile model

Reusable callers exist for four profiles:

- `templates/actions/workflows/*`
- `templates/dockerized/workflows/*`
- `templates/other/workflows/*`
- `templates/static/workflows/*`

`actions` contains base implementations. `dockerized`, `other`, and `static` wrap base workflows with profile-specific defaults.

## Required workflows per repository

Each in-scope repository should expose these caller workflows in `.github/workflows/`:

1. `auto-create-pull-request.yml`
2. `cron-check-dependencies.yml`
3. `manual-update-version.yml`
4. `manual-sync-common-files.yml` (recommended)

Static profile repositories should also expose:

5. `auto-deploy-pages.yml` (publish `site/` to GitHub Pages)

## Workflow versioning policy

- Reusable workflows must be referenced with version tags (for example `@v1`).
- Do not reference reusable workflows with `@master`.
- Update callers to newer tags through migration PRs.

Example:

```yaml
jobs:
  call:
    uses: devops-infra/.github/.github/workflows/reusable-auto-create-pull-request.yml@v1
```

## Weekly health workflow behavior

`cron-check-dependencies` is the aggregated weekly check. It combines:

- dependency checks
- baseline validation
- workflow linting
- stale branch and stale issue detection

The workflow creates or updates one repository issue with findings and auto-closes it when clean.

## Manual version update behavior

`manual-update-version` supports two modes:

- bump or set version (and open release PR)
- build/push only without version bump (`build_only: true`)

## Required action usage

Reusable workflows that create commits/PRs use:

- `devops-infra/action-commit-push`
- `devops-infra/action-pull-request`

## Migration notes

- Finalize reusable templates in `.github` first.
- Then roll out profile-specific caller workflows to each repository.
- Validate that caller files reference `@v1` and that Taskfile tasks exist.
