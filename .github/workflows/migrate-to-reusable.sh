#!/usr/bin/env bash
# Migration script to replace repository workflows with centralized workflow callers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLES_DIR="$SCRIPT_DIR/examples"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    cat << EOF
Usage: $0 <repository-path> [options]

Migrates a repository to use centralized workflows from devops-infra/.github

Arguments:
  repository-path    Path to the repository to migrate

Options:
  --dry-run          Show what would be done without making changes
  --backup           Create backup of existing workflows (default)
  --no-backup        Skip backup creation
  --workflows        Comma-separated list of workflows to migrate (default: all)
                     Options: pr,release,cron,version,sync

Examples:
  $0 ../action-commit-push
  $0 ../docker-terragrunt --dry-run
  $0 ../action-format-hcl --workflows pr,release

EOF
    exit 1
}

# Parse arguments
REPO_PATH=""
DRY_RUN=false
CREATE_BACKUP=true
WORKFLOWS="pr,release,cron,version,sync"

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --backup)
            CREATE_BACKUP=true
            shift
            ;;
        --no-backup)
            CREATE_BACKUP=false
            shift
            ;;
        --workflows)
            WORKFLOWS="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            if [[ -z "$REPO_PATH" ]]; then
                REPO_PATH="$1"
            else
                print_error "Unknown argument: $1"
                usage
            fi
            shift
            ;;
    esac
done

if [[ -z "$REPO_PATH" ]]; then
    print_error "Repository path is required"
    usage
fi

# Validate repository path
if [[ ! -d "$REPO_PATH" ]]; then
    print_error "Repository path does not exist: $REPO_PATH"
    exit 1
fi

if [[ ! -d "$REPO_PATH/.git" ]]; then
    print_error "Not a git repository: $REPO_PATH"
    exit 1
fi

REPO_WORKFLOWS="$REPO_PATH/.github/workflows"
if [[ ! -d "$REPO_WORKFLOWS" ]]; then
    print_error "No workflows directory found: $REPO_WORKFLOWS"
    exit 1
fi

REPO_NAME=$(basename "$REPO_PATH")
print_info "Migrating repository: $REPO_NAME"

if [[ "$REPO_NAME" == "docker-okta-aws-sso" ]]; then
    print_warn "Repository '$REPO_NAME' is archived and excluded from automation; skipping."
    exit 0
fi

# Create backup if requested
if [[ "$CREATE_BACKUP" == true ]] && [[ "$DRY_RUN" == false ]]; then
    BACKUP_DIR="$REPO_WORKFLOWS.backup.$(date +%Y%m%d_%H%M%S)"
    print_info "Creating backup: $BACKUP_DIR"
    cp -r "$REPO_WORKFLOWS" "$BACKUP_DIR"
fi

# Workflow mapping
declare -A WORKFLOW_MAP=(
    ["pr"]="auto-create-pull-request.yml"
    ["release"]="auto-create-release.yml"
    ["cron"]="cron-check-dependencies.yml"
    ["version"]="manual-update-version.yml"
    ["sync"]="manual-sync-common-files.yml"
)

# Parse workflows to migrate
IFS=',' read -ra WORKFLOW_LIST <<< "$WORKFLOWS"

for workflow in "${WORKFLOW_LIST[@]}"; do
    workflow=$(echo "$workflow" | xargs) # trim whitespace
    
    if [[ ! -v WORKFLOW_MAP[$workflow] ]]; then
        print_warn "Unknown workflow: $workflow (skipping)"
        continue
    fi
    
    WORKFLOW_FILE="${WORKFLOW_MAP[$workflow]}"
    SOURCE_FILE="$EXAMPLES_DIR/$WORKFLOW_FILE"
    TARGET_FILE="$REPO_WORKFLOWS/$WORKFLOW_FILE"
    
    if [[ ! -f "$SOURCE_FILE" ]]; then
        print_error "Example workflow not found: $SOURCE_FILE"
        continue
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY-RUN] Would copy: $WORKFLOW_FILE"
    else
        print_info "Copying: $WORKFLOW_FILE"
        cp "$SOURCE_FILE" "$TARGET_FILE"
    fi
done

if [[ "$DRY_RUN" == true ]]; then
    print_warn "Dry-run mode - no changes were made"
else
    print_info "Migration complete!"
    print_info ""
    print_info "Next steps:"
    print_info "  1. Review the new workflows in: $REPO_WORKFLOWS"
    print_info "  2. Adjust inputs if needed (enable-docker, runs-on, etc.)"
    print_info "  3. Test by creating a feature branch and pushing"
    print_info "  4. If successful, delete old workflows"
    if [[ "$CREATE_BACKUP" == true ]]; then
        print_info "  5. Remove backup when confident: rm -rf $BACKUP_DIR"
    fi
fi
