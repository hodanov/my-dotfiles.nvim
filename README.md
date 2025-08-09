# My dotfiles for Neovim

This is my personal Neovim configuration and dev-environment on docker.

![](assets/screenshot_nvim_window.avif)


## Introduction

This dev-env assumed to operate in a Mac(arm64) and Docker.

However, it is possible to use it on other platforms by modifying the Dockerfile.

The dotfiles will work in any environment. You can find [the dotfiles here](./config).


## Features

This is using the following technologies and plugins:

- Environment
  - Ubuntu: 24.04
  - Neovim: latest version
  - Go: latest version
  - Python: latest version
  - Node.js: latest version
  - Rust: latest version
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

When writing Python code with static analysis and a linter enabled, switch environments using venv beforehand.

```sh
source /.venv/bin/activate # Activte
deactivate # Deactivate
```
