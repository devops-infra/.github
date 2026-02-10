# Centralized Workflows for devops-infra Organization

This directory contains centralized workflows that can be called from any repository in the devops-infra organization. This eliminates workflow duplication and simplifies maintenance.

## Available Workflows

### 1. `auto-create-pull-request.yml`
**Purpose:** Automates pull request creation for feature branches  
**Triggers:** Push to non-master branches  
**Steps:**
- Runs linters (optional)
- Builds and pushes Docker image with multi-arch support
- Inspects image
- Creates pull request with template

**Inputs:**
- `runs-on` (default: `ubuntu-24.04-arm`)
- `task-version` (default: `3.x`)
- `enable-docker` (default: `true`)
- `enable-lint` (default: `true`)
- `docker-platforms` (default: `amd64,arm64`)

**Required Secrets:** `DOCKER_TOKEN`, `GITHUB_TOKEN`

---

### 2. `auto-create-release.yml`
**Purpose:** Creates releases when release branches are merged  
**Triggers:** PR merge from `release/**` branches  
**Steps:**
- Tags release
- Builds and pushes production Docker images
- Creates GitHub release with notes
- Updates Docker Hub description

**Inputs:**
- `runs-on` (default: `ubuntu-24.04-arm`)
- `task-version` (default: `3.x`)
- `docker-platforms` (default: `amd64,arm64`)
- `version-suffix` (default: `''`)
- `update-dockerhub-description` (default: `true`)

**Required Secrets:** `DOCKER_TOKEN`, `GITHUB_TOKEN`, `DOCKER_USERNAME` (optional)

**Outputs:** `version` - The created release version

---

### 3. `cron-check-dependencies.yml`
**Purpose:** Scheduled dependency testing  
**Triggers:** Cron schedule (e.g., weekly)  
**Steps:**
- Runs linters
- Builds test image to verify dependencies still work
- Inspects image

**Inputs:**
- `runs-on` (default: `ubuntu-24.04-arm`)
- `task-version` (default: `3.x`)
- `docker-platforms` (default: `amd64,arm64`)

**Required Secrets:** `DOCKER_TOKEN`, `GITHUB_TOKEN`

---

### 4. `manual-update-version.yml`
**Purpose:** Manual version bump workflow  
**Triggers:** Manual workflow dispatch  
**Steps:**
- Bumps version (patch/minor/major) or sets explicit version
- Creates release branch
- Creates pull request

**Inputs:**
- `runs-on` (default: `ubuntu-24.04-arm`)
- `task-version` (default: `3.x`)
- `bump-type` (required: `patch`, `minor`, `major`, `set`)
- `explicit-version` (optional, for `type=set`)

**Required Secrets:** `GITHUB_TOKEN`

**Outputs:** `version` - The updated version

---

### 5. `manual-sync-common-files.yml`
**Purpose:** Sync common files from template sources  
**Triggers:** Manual workflow dispatch  
**Steps:**
- Syncs specified file types (configs, ignores, taskfiles)
- Taskfiles are sourced from `devops-infra/.github/.github/taskfiles`
- Configs/ignores are sourced from `devops-infra/.github/.github/configs`
- Creates branch with changes
- Creates pull request

**Inputs:**
- `runs-on` (default: `ubuntu-24.04-arm`)
- `task-version` (default: `3.x`)
- `sync-type` (required: `all`, `configs`, `ignores`, `taskfiles`)

**Required Secrets:** `GITHUB_TOKEN`

---

## Usage in Individual Repositories

To use these workflows in your repository, create minimal caller workflows in `.github/workflows/`.

Archived repositories (e.g., `docker-okta-aws-sso`) are excluded from syncing and automation.

### Example: Auto-create PR workflow

```yaml
name: (Auto) Create Pull Request

on:
  push:
    branches-ignore:
      - master
      - dependabot/**

permissions:
  contents: read
  packages: write
  pull-requests: write

jobs:
  call-auto-create-pull-request:
    uses: devops-infra/.github/.github/workflows/auto-create-pull-request.yml@master
    with:
      runs-on: ubuntu-24.04-arm
      enable-docker: true
    secrets:
      DOCKER_TOKEN: ${{ secrets.DOCKER_TOKEN }}
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

See the [`examples/`](./examples/) directory for complete examples of all workflows.

---

## Migration Guide

### Step 1: Push centralized workflows to .github repository
Ensure all workflows in this directory are committed and pushed to the `master` branch of `devops-infra/.github`.

### Step 2: Update individual repositories
For each repository (e.g., `action-commit-push`, `docker-terragrunt`):

1. **Backup existing workflows** (optional)
   ```bash
   cp -r .github/workflows .github/workflows.backup
   ```

2. **Replace workflows with callers**
   - Copy examples from `.github/.github/workflows/examples/`
   - Adjust inputs if needed (e.g., disable Docker for non-Docker repos)
   - Commit and push

3. **Test the workflow**
   - Create a test branch
   - Push changes to trigger the PR workflow
   - Verify it works correctly

### Step 3: Clean up
Once verified, remove old workflow files and the backup.

---

## Benefits

✅ **Single source of truth** - Update workflow logic once, applies everywhere  
✅ **Reduced duplication** - Dozens of files reduced to ~5 centralized workflows  
✅ **Easier maintenance** - Fix bugs or add features in one place  
✅ **Consistency** - All repos use identical CI/CD patterns  
✅ **Flexibility** - Inputs allow customization per repository  

---

## Requirements

All repositories must have:
- `Taskfile.yml` with standard tasks: `lint`, `docker:cmds`, `docker:push`, `docker:push:inspect`, `git:get-pr-template`
- Standard branch naming: `release/**` for releases
- Secrets configured: `DOCKER_TOKEN`, `GITHUB_TOKEN`, optionally `DOCKER_USERNAME`

---

## Troubleshooting

### "Workflow not found" errors
- Ensure workflows are pushed to the `master` branch of `devops-infra/.github`
- Verify the path: `devops-infra/.github/.github/workflows/<workflow>.yml@master`

### Permission errors
- Ensure caller workflow has required `permissions` section
- Verify secrets are configured in repository settings

### Task errors
- Ensure your `Taskfile.yml` includes all required tasks
- Check task names match exactly (case-sensitive)

---

## Updating Workflows

When you need to update workflow logic:

1. Edit the centralized workflow in `.github/.github/workflows/`
2. Commit and push to `.github` repository
3. Changes automatically apply to all repositories using it
4. No need to update individual repositories (unless changing inputs)

---

## Future Enhancements

- [ ] Add centralized workflow for Python packages (velez)
- [ ] Add centralized workflow for Makefile-based Docker repos (active ones)
- [ ] Implement workflow versioning with tags instead of `@master`
- [ ] Add status badges to repositories
- [ ] Create workflow for automated sync of these workflows to all repos
