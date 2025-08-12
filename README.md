# My dotfiles for Neovim

This is my personal Neovim configuration and dev-environment on docker.

![](assets/screenshot_nvim_window.avif)

## Introduction

This dev-env assumed to operate in a Mac(arm64) and Docker.

However, it is possible to use it on other platforms by modifying the Dockerfile.

The dotfiles will work in any environment. You can find [the dotfiles here](./config).

## Scripts

- `scripts/update-go-tools.sh`: Updates Go tools versions in `config/go-tools/go-tools.txt`. This script is automatically executed by GitHub Actions but can also be run manually if needed.

## Features

This is using the following technologies and plugins:

- Environment (versions are pinned via Dockerfile ARGs; see `nvim.dockerfile`)
  - Ubuntu (base image): 24.04
  - Neovim (built from source in builder stage)
  - Go (official tarball)
  - Python (system Python + uv-managed virtualenvs)
  - Node.js (official tarball under `/opt/node`)
  - npm (pinned during build)
  - Rust (toolchain installed in builder stage)
- Linter/Formatter
  - Go
    - goimports
    - gopls
    - golangci-lint
  - Python
    - pyright
    - ruff
  - JavaScript
    - eslint
    - prettier
  - Lua
    - stylua
  - Others
    - yamlls...LSP for yaml
    - tombi...LSP for toml
    - textlint
- Plugins
  - lazy.nvim...Plugin manager
  - copilot...AI pair programmer
  - nvim-lspconfig...Setting LSP
  - conform.nvim...Autoformatter
  - nvim-cmp...Completion
  - nvim-dap...Debug adapter protocol
  - fern.vim...File manager
  - telescope.nvim...Fuzzy finder
  - nvim-lualine...Status tabline
  - gitsigns.nvim...Show `git diff` in the gutter(sign column)
  - indent-blankline.nvim...Show indent guides
    and so on...

## Getting Started

To use the environment, clone the repo and execute `docker compose up`.

```sh
git clone git@github.com:hodanov/my-dotfiles.nvim.git
docker network create my-nvim
cd my-dotfiles.nvim
docker compose up -d
```

After launching containers, execute the following command to attach the "nvim" container.

```sh
docker container exec -it nvim-dev bash --login
```

The `--login` option is required to read the `.bash_profile` file.

### Python coding

Python environments are managed by uv. A base virtualenv is prebuilt at `/opt/python/.venv`. You can also create per-project venvs with uv.

```sh
# Use the prebuilt base venv (global tools)
source /opt/python/.venv/bin/activate

# Or create a project venv via uv
uv venv .venv
source .venv/bin/activate

# Sync dependencies from pyproject.toml (and uv.lock if present)
uv sync

# Deactivate when done
deactivate
```

### Node.js tooling

CLI tools (eslint, typescript-language-server, textlint, etc.) are managed via `config/npm-tools/package.json` and installed into `/opt/npm-tools` during the image build. They are on `PATH` via `/opt/npm-tools/node_modules/.bin`.

- To add/update tools, edit `config/npm-tools/package.json` and rebuild. Dependabot monitors this directory and will propose updates.

### Go tooling

Go-based tools (gopls, dlv, golangci-lint, etc.) are managed via `config/go-tools/go-tools.txt` and installed during the Docker image build. The versions are pinned to ensure reproducible builds.

- **Automatic update**: GitHub Actions runs weekly (Monday 03:00 UTC) to check for updates and create PRs
- **Manual execution**: GitHub Actions can be triggered manually via `workflow_dispatch`
- **Version management**: Uses Go module system to find the latest stable versions
- **Script execution**: Run `./scripts/update-go-tools.sh` directly if needed

### Dockerfile architecture (multi-stage)

The `nvim.dockerfile` is split into multiple stages to keep the final image slim and maintainable:

- `nvim-builder`: builds Neovim from source and installs to an install dir copied to the final stage
- `node-builder`: downloads the official Node.js tarball into `/opt/node` and installs npm tools from `config/npm-tools`
- `go-builder`: installs Go toolchain and Go-based tools (gopls, dlv, golangci-lint, etc.)
- `rust-builder`: installs Rust toolchain and builds `stylua`
- `python-builder`: installs uv and creates a base `.venv` from `config/dependencies/pyproject.toml`
- final stage: installs minimal runtime packages and copies only the necessary artifacts from each builder

### Version management and CI

- Versions for Node/Go/Rust/Neovim/npm are defined as `ARG` lines in `nvim.dockerfile` and hardcoded by default. Keep each `ARG` unindented and on a single line so automation can edit them.
- GitHub Actions workflows:
  - `bump-tool-versions.yml`: weekly (Mon 03:00 UTC) or manual. Resolves the latest stable versions for Node/Go/Neovim/npm (Rust stays `stable`) and opens a PR labeled `dependencies` updating the `ARG`s in `nvim.dockerfile`.
  - `update-go-tools.yml`: weekly (Mon 03:00 UTC) or manual. Updates Go tools versions in `config/go-tools/go-tools.txt` and creates PRs for version updates.
  - `pr-docker-build.yml`: on PRs that are Dependabot, labeled `dependencies`, or whose branch starts with `chore/bump-tool-versions`, builds the image with Buildx for verification (no push).
  - `lint_dockerfile.yml`: runs hadolint on changes to `nvim.dockerfile`, the workflow file itself, or `.hadolint.yml`.
- Dependabot is configured in `.github/dependabot.yml` to monitor:
  - `pip` under `config/dependencies`
  - `npm` under `config/npm-tools`
  - `docker` in the repo root
  - `github-actions` in the repo root
- Hadolint rules can be tuned via `.hadolint.yml` (some rules are intentionally ignored for this build style).
