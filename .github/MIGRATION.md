# Migration to Centralized Reusable Workflows

## Summary

This setup establishes the `.github` repository as a centralized meta repository for all devops-infra workflows, eliminating duplication across ~14 repositories.

## What Was Created

### 1. Reusable Workflows (`.github/workflows/reusable/`)

Five centralized workflows:

| Workflow                                | Purpose                                 | Replaces                       |
|-----------------------------------------|-----------------------------------------|--------------------------------|
| `reusable/auto-create-pull-request.yml` | Auto-create PRs for feature branches    | `auto-create-pull-request.yml` |
| `reusable/auto-create-release.yml`      | Create releases from merged PRs         | `auto-create-release.yml`      |
| `reusable/cron-check-dependencies.yml`  | Scheduled dependency testing            | `cron-check-dependencies.yml`  |
| `reusable/manual-update-version.yml`    | Manual version bumps                    | `manual-update-version.yml`    |
| `reusable/manual-sync-common-files.yml` | Sync common files from template sources | `manual-sync-common-files.yml` |

### 2. Example Caller Workflows (`.github/workflows/examples/`)

Ready-to-use examples showing how repositories call the centralized workflows:
- `auto-create-pull-request.yml`
- `auto-create-release.yml`
- `cron-check-dependencies.yml`
- `manual-update-version.yml`
- `manual-sync-common-files.yml`

### 3. Reusable Taskfiles (`.github/taskfiles/`)

Shared Taskfile templates used by the sync-files workflow:
- `Taskfile.yml`
- `Taskfile.cicd.yml`
- `Taskfile.docker.yml`
- `Taskfile.variables.yml`

### 4. Reusable Configs (`.github/configs/`)

Shared config files synced by `sync:configs` and `sync:ignores`:
- `.editorconfig`
- `.hadolint.yaml`
- `.pre-commit-config.yaml`
- `.shellcheckrc`
- `.yamllint.yml`
- `.gitignore`
- `.dockerignore`

### 5. Documentation

- `README.md` - Complete guide to centralized workflows, migration process, and troubleshooting
- Updated `copilot-instructions.md` - Added centralized workflow section and Task runner info

### 6. Migration Script

`migrate-to-reusable.sh` - Automated script to migrate repositories with:
- Dry-run mode for testing
- Automatic backup creation
- Selective workflow migration
- Clear next-steps guidance

## Migration Process

### Step 1: Commit and Push to .github Repository

```bash
cd /Users/christoph/IdeaProjects/devops-infra/.github
git add .github/workflows/*.yml
git add .github/workflows/reusable/*.yml
git add .github/workflows/examples/
git add .github/workflows/README.md
git add .github/workflows/migrate-to-reusable.sh
git add .github/configs/
git add .github/taskfiles/
git add copilot-instructions.md
git commit -m "feat: Add centralized workflows for organization"
git push origin master
```

### Step 2: Migrate Individual Repositories

Choose one of these approaches:

#### Option A: Manual Migration (Recommended for first repo)

1. **Pick a test repository** (suggest `action-format-hcl` as it's simpler)

2. **Copy example workflows:**
   ```bash
   cd /Users/christoph/IdeaProjects/devops-infra/action-format-hcl
   
   # Backup existing workflows
   cp -r .github/workflows .github/workflows.backup
   
   # Copy examples
   cp ../. github/.github/workflows/examples/*.yml .github/workflows/
   ```

3. **Remove old workflows:**
   ```bash
   # Keep only the new caller workflows
   ls .github/workflows/
   ```

4. **Test:**
   ```bash
   git checkout -b test/central-workflows
   git add .github/workflows/
   git commit -m "test: Migrate to centralized workflows"
   git push origin test/central-workflows
   ```

5. **Verify in GitHub Actions UI** that the workflow runs correctly

#### Option B: Automated Migration

```bash
cd /Users/christoph/IdeaProjects/devops-infra/.github/.github/workflows

# Dry-run first
./migrate-to-reusable.sh ../../action-format-hcl --dry-run

# If looks good, run for real
./migrate-to-reusable.sh ../../action-format-hcl

# Migrate specific workflows only
./migrate-to-reusable.sh ../../docker-terragrunt --workflows pr,release
```

### Step 3: Rollout to All Repositories

Once verified with one repository, migrate the rest:

**Repositories to migrate:**
- action-commit-push
- action-format-hcl ✓ (use as test)
- action-pull-request
- action-terraform-copy-vars
- action-terraform-validate
- action-tflint
- docker-simple-runner
- docker-terragrunt
- template-action

**Repositories that may need customization:**
- `velez` - Uses Python/pytest, not Docker (may need different workflow)

**Archived repositories (excluded from automation):**
- `docker-okta-aws-sso`

### Step 4: Cleanup

After successful migration and testing:

```bash
# In each repository
rm -rf .github/workflows.backup*
```

## Benefits After Migration

### Before
- ~70 duplicate workflow files across 14 repositories
- Bug fixes require updating 14 repos individually
- Inconsistent workflow versions between repos
- High maintenance burden

### After
- 5 centralized workflows + ~14 small caller workflows
- Update logic once in `.github`, applies everywhere
- Guaranteed consistency across all repos
- Minimal maintenance

## Customization Examples

### Disable Docker for non-Docker repos
```yaml
jobs:
  call-workflow:
    uses: devops-infra/.github/.github/workflows/reusable/auto-create-pull-request.yml@master
    with:
      enable-docker: false
      enable-lint: true
```

### Use different runner
```yaml
jobs:
  call-workflow:
    uses: devops-infra/.github/.github/workflows/reusable/auto-create-pull-request.yml@master
    with:
      runs-on: ubuntu-latest
```

### Single-arch builds
```yaml
jobs:
  call-workflow:
    uses: devops-infra/.github/.github/workflows/reusable/auto-create-pull-request.yml@master
    with:
      docker-platforms: amd64
```

## Rollback Plan

If issues occur:

1. **Individual repository:** Restore from `.github/workflows.backup`
2. **Organization-wide:** Temporarily pin to old workflow files until fixed
3. **Revert .github changes:** `git revert <commit>` in `.github` repository

## Future Enhancements

1. **Version tagging:** Pin workflows to tags instead of `@master` for stability
   ```yaml
   uses: devops-infra/.github/.github/workflows/reusable/auto-create-pull-request.yml@v1.0.0
   ```

2. **Python-specific workflow:** Create centralized workflow for `velez` and similar Python projects

3. **Makefile-specific workflow:** Create centralized workflow for repos still using Make

4. **Auto-sync workflow:** Create workflow that automatically updates caller workflows in all repos when examples change

5. **Workflow testing:** Add tests to validate centralized workflows before deployment

## Support

For issues or questions:
- Check `README.md` in `.github/.github/workflows/`
- Review examples in `examples/` directory
- Test with `--dry-run` flag first
- Start with one simple repository before migrating all

## Checklist

- [ ] Commit and push centralized workflows to `.github` repository
- [ ] Test migration with `action-format-hcl` (or similar simple repo)
- [ ] Verify GitHub Actions run successfully
- [ ] Migrate remaining action-* repositories
- [ ] Migrate docker-* repositories (may need customization)
- [ ] Handle special cases (velez)
- [ ] Skip archived repositories (docker-okta-aws-sso)
- [ ] Clean up backup directories
- [ ] Update any documentation referencing old workflows
- [ ] Consider implementing version tagging for workflows
