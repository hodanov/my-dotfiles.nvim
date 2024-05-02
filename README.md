# Go + Neovim on docker

This is the dev-environment for Neovim on docker.

This is using the following technologies and vim-plugins:

- Environment
  - Ubuntu: 24.04
  - Neovim: latest version
  - Go: latest version
  - Python: > 3
  - Node.js: latest version
- Linter/Formatter
  - Go
    - goimports
    - gopls
    - golangci-lint
  - Python
    - pycodestyle
    - mypy
    - black
    - isort
  - JavaScript
    - eslint
    - prettier
- Plugins
  - copilot...AI pair programmer
  - packer.nvim...Plugin manager
  - nvim-lspconfig...Setting LSP
  - none-ls.nvim...diagnostic, autoformatter
  - nvim-cmp...Completion
  - fern.vim...File manager
  - nvim-lualine...Status tabline
  - gitsigns.nvim...Show `git diff` in the gutter(sign column)
  - indent-blankline.nvim...Show indent guides
    and so on...

## Requirements

The app requires the following to run:

- Docker
- Docker Compose

## Getting Started

To use the environment, clone the repo and execute `docker compose up`.

```sh
git clone git@github.com:hodanov/docker-template-nvim.git
cd docker-template-nvim
docker network create my-nvim
docker compose up -d
```

After launching containers, execute the following command to attach the "nvim" container.

```sh
docker compose exec nvim-dev bash --login
```

The `--login` option is required to read the `.bash_profile` file.

## Python coding

When writing Python code with static analysis and a linter enabled, switch environments using venv beforehand.

```sh
source /root/.venv/bin/activate
python3 -m pip install --no-cache-dir --requirement /root/requirements.txt
```
