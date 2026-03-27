# Copilot Instructions for devops-infra

This is a local working directory containing checked-out repositories from the [devops-infra](https://github.com/devops-infra) GitHub organization. Each subdirectory is a separate git repository.

## Repository Structure

The directory contains four main categories of repositories:

### GitHub Actions (action-*)
Docker-based GitHub Actions for DevOps automation:
- `action-commit-push` - Commits and pushes changes to repository
- `action-format-hcl` - Formats Terraform/Terragrunt HCL files
- `action-pull-request` - Creates and manages pull requests
- `action-terraform-copy-vars` - Copies Terraform variables between environments
- `action-terraform-validate` - Validates Terraform configurations
- `action-tflint` - Runs TFLint on Terraform code

### Docker Images (docker-*)
Containerized tools for CI/CD pipelines:
- `docker-terragrunt` - Multi-arch (amd64/arm64) IaC framework with Terraform, OpenTofu, Terragrunt, and cloud CLIs (AWS, Azure, GCP)
- `docker-simple-runner` - Lightweight CI/CD runner image

### Excluded Repository
- `docker-okta-aws-sso` is archived and must be ignored completely (do not read, edit, sync, or automate).

### Templates & Tools
- `template-action` - Template for creating new GitHub Actions
- `template-repository` - Template for new repositories
- `velez` - Python CLI tool for Terragrunt/Terraform automation (formerly pygrunt)

### Static Sites
- Repositories using static-site baseline with GitHub Pages deploy workflow (`templates/static/*`)

### Meta Repository
- `.github/` - Organization-wide GitHub settings, templates, and workflows

## Build & Development Commands

### GitHub Actions
Each action repository includes:
```bash
# Lint Dockerfile
docker run --rm -i hadolint/hadolint < Dockerfile

# Build action locally
docker build -t action-name:test .

# Pre-commit hooks (where .pre-commit-config.yaml exists)
pre-commit run --all-files
```

### Docker Images
Taskfiles provide standardized tasks:
```bash
# Build image
task docker:build

# Build and push
task docker:push

# Inspect built image
task docker:push:inspect

# Check available tasks
task --list
```

### Velez (Python CLI)
```bash
# Install for development
pip3 install -r requirements.txt

# Build and install
python3 -m build --wheel
pip3 install dist/*.whl

# Run tests
pytest -v --tb=short

# Clean build artifacts
rm -rf dist build *.egg-info
```

## Reusable Workflows (CI/CD)

The `.github` repository serves as a **meta repository** containing centralized workflows for the entire organization:

### Available Reusable Workflows
Located in profile folders under `templates/*/workflows/`:
- `auto-create-pull-request.yml` - Auto-create PRs for feature branches
- `auto-create-release.yml` - Create releases from `release/**` branches
- `cron-check-dependencies.yml` - Scheduled aggregated repository health check
- `manual-update-version.yml` - Manual version bumps or build-only mode
- `manual-sync-common-files.yml` - Sync common files from `.github` (taskfiles: `templates/actions/taskfiles`, configs: `templates/actions/configs`)

Static profile repositories also use:
- `deploy-pages.yml` - Publish `site/` to GitHub Pages

### Using Reusable Workflows
Individual repositories call these workflows instead of duplicating logic:

```yaml
jobs:
  call-workflow:
    uses: devops-infra/.github/templates/actions/workflows/auto-create-pull-request.yml@v1
    with:
      runs-on: ubuntu-24.04-arm
      enable-docker: true
    secrets:
      DOCKER_TOKEN: ${{ secrets.DOCKER_TOKEN }}
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

See `.github/.github/workflows/` for caller examples and `.github/.github/workflows/README.md` for detailed documentation.

### Workflow Requirements
All repositories using these workflows must have profile-appropriate Taskfiles with:
- `lint`, `git:get-pr-template`, `git:set-config`, `version:*`
- Docker tasks (`docker:cmds`, `docker:push`, `docker:push:inspect`) for action/dockerized profiles only
- Static repositories should also include `deploy-pages.yml` for GitHub Pages deployment

Configured secrets vary by profile:
- `GITHUB_TOKEN` (required)
- `DOCKER_TOKEN` (required for docker build/push flows)
- `DOCKER_USERNAME` (optional, for Docker Hub description update)

## Key Conventions

### Branch Naming
Per `.github/CONTRIBUTING.md`:
- `bugfix/*` - Bug fixes
- `dependency/*` - Dependency updates
- `documentation/*` - Documentation changes
- `feature/*` - New features
- `test/*` - Testing changes (use for draft PRs to test CI/CD)
- `release/*` - Release branches (trigger release workflow when merged)

### Commit Messages
- Start with past tense verb: `Added...`, `Fixed...`, `Changed...`, `Updated...`
- Brief description of purpose
- Optional longer description in commit body

### Dockerfiles
- Base image: `ubuntu:questing-20251217` (common across most actions)
- Shell: `/bin/bash` with `-euxo pipefail`
- Entrypoint: `/entrypoint.sh` or `entrypoint.sh`
- Always use `DEBIAN_FRONTEND=noninteractive`
- Clean apt cache: `apt-get clean && rm -rf /var/lib/apt/lists/*`
- Follow hadolint recommendations (`.hadolint.yaml` present in action repos)

### GitHub Actions (action.yml)
- Author: `Krzysztof Szyper / ChristophShyper / shyper.pro`
- Docker images published to both Docker Hub (`devopsinfra/*`) and GitHub Packages (`ghcr.io/devops-infra/*`)
- Common inputs include `github_token` and `debug` flags
- Entry scripts are bash with `set -e` and comprehensive error handling

### Taskfile.yml (Task Runner)
Repositories use [Task](https://taskfile.dev) for build automation. Templates are split by category in `templates/`:

- **actions/**: `Taskfile.yml`, `Taskfile.cicd.yml`, `Taskfile.docker.yml`, `Taskfile.variables.yml` (for action-* repos and template-action)
- **dockerized/**: `Taskfile.yml`, `Taskfile.cicd.yml`, `Taskfile.docker.yml`, `Taskfile.scripts.yml`, `Taskfile.variables.yml` (for docker-* repos)
- **static/**: `Taskfile.yml`, `Taskfile.cicd.yml`, `Taskfile.scripts.yml`, `Taskfile.variables.yml` (for GitHub Pages/static sites)
- **other/**: `Taskfile.yml`, `Taskfile.cicd.yml`, `Taskfile.scripts.yml`, `Taskfile.variables.yml` (for non-Docker repos)

Common tasks include:
- `lint` (actionlint/yamllint and hadolint/shellcheck where applicable)
- `git:get-pr-template`, `git:set-config`
- Docker tasks (`docker:*`) only in the actions template
- Version tasks (`version:*`) only in the actions template

The `.github` meta repository uses `templates/other` as the default sync source for configs and taskfiles.

### Multi-Arch Images
`docker-terragrunt` supports both `amd64` and `arm64` architectures. Version tags include dependency versions (e.g., `tf-1.13.4-tg-0.93.0`).

### Pre-commit Hooks
Action repositories use `.pre-commit-config.yaml` with:
- Standard pre-commit-hooks (trailing whitespace, EOF fixes, JSON/YAML checks)
- `actionlint` via Docker for workflow validation
- `no-commit-to-branch` protecting `master` and `main`

## Repository Navigation

Each repository is independent with its own:
- `.git/` directory (separate git history)
- `.github/workflows/` for CI/CD
- `README.md` with usage documentation
- `LICENSE` (individual licensing)

When working across repositories, navigate to the specific subdirectory first. There is no root-level git repository.

## Updating Workflows Across All Repositories

To update CI/CD logic for all repositories:
1. Edit the centralized workflow in `.github/.github/workflows/*.yml`
2. Commit and push to `.github` repository master branch
3. Changes automatically apply to all repositories using it
4. No need to update individual repositories (unless changing inputs)

## Important Context

- Organization: `devops-infra` on GitHub
- Docker Hub: `devopsinfra/*`
- GitHub Packages: `ghcr.io/devops-infra/*`
- Maintainer: Krzysztof Szyper (@ChristophShyper)
- Most repositories use Task runner (Taskfile.yml) for build automation
- Repositories call centralized workflows from `.github` meta repository
- `velez` repository maps to `github.com/devops-infra/pygrunt` (renamed project)
