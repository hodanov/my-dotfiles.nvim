# My dotfiles for Neovim

This is my personal Neovim configuration and dev-environment on Docker.

![screenshot_nvim_window](assets/screenshot_nvim_window.avif)

## Introduction

This dev-env is designed to operate on Mac (arm64) and Docker.

However, it is possible to use it on other platforms by modifying the Dockerfile.

The dotfiles will work in any environment. You can find [the dotfiles here](./nvim/config).

## Getting Started

Clone the repo and start the container:

```sh
git clone git@github.com:hodanov/my-dotfiles.nvim.git
docker network create my-nvim
cd my-dotfiles.nvim
docker compose -f environment/docker/docker-compose.yml up -d
```

Attach to the container:

```sh
docker container exec -it nvim-dev bash --login
```

The `--login` option is required to read the `.bash_profile` file.

## Features

- **LSP / Linter / Formatter**: Go (gopls, golangci-lint), Python (pyright, ruff), JavaScript (eslint, prettier), Lua (stylua), YAML, TOML, Markdown, etc.
- **Completion**: nvim-cmp
- **Fuzzy Finder**: telescope.nvim
- **File Manager**: fern.vim
- **Debugger**: nvim-dap
- **Plugin Manager**: lazy.nvim

Versions for Neovim, Go, Python, Node.js, Rust are pinned as `ARG`s in `environment/docker/nvim.dockerfile`. Tool versions are automatically updated via GitHub Actions and Dependabot.

## AI Bridge

Neovim (Docker container) from selected code to host-side AI CLI (Claude Code, Cursor, etc.) with context. See [docs/ai-bridge.md](docs/ai-bridge.md) for setup and usage.

## Language-specific notes

### Python

Python environments are managed by uv. A base virtualenv is prebuilt at `/opt/python/.venv`.

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

### Node.js

CLI tools (eslint, typescript-language-server, textlint, etc.) are managed via `environment/tools/node/package.json` and installed into `/opt/npm-tools` during the image build. To add/update tools, edit the `package.json` and rebuild.

### Go

Go-based tools (gopls, dlv, golangci-lint, etc.) are managed via `environment/tools/go/go-tools.txt` and installed during the image build. Versions are automatically updated weekly by GitHub Actions.
