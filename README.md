# Meta repository for [devops-infra](https://github.com/devops-infra) organization

# Badge swag
[
![GitHub repo](https://img.shields.io/badge/GitHub-devops--infra%2F.github-blueviolet.svg?style=plastic&logo=github)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/devops-infra/.github?color=blueviolet&label=Code%20size&style=plastic&logo=github)
![GitHub last commit](https://img.shields.io/github/last-commit/devops-infra/.github?color=blueviolet&logo=github&style=plastic&label=Last%20commit)
![GitHub license](https://img.shields.io/github/license/devops-infra/.github?color=blueviolet&logo=github&style=plastic&label=License)
](https://github.com/devops-infra/.github "shields.io")

## Action Development Flow

Reusable workflows in this repository now enforce centralized E2E validation for action repositories via `devops-infra/triglav`.

- Pull request flow (`reusable-auto-pull-request-create.yml`): runs action-specific E2E checks for PR validation.
- Release branch prepare flow (`reusable-manual-release-branch-prepare.yml`): runs action-specific E2E checks against release-candidate images (`-rc`) and ref-oriented paths where applicable.
- Release create flow (`reusable-auto-release-create.yml`): verifies release refs (`vX.Y.Z`, `vX.Y`, `vX`) resolve to the same target, then runs action-specific E2E checks against release images/tags.

This keeps validation consistent across all `action-*` repositories without duplicating CI logic per repository.
