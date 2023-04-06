# Go + Neovim on docker

This is the dev-environment for Neovim on docker.

This is using the following technologies and vim-plugins:

- Environment
  - Ubuntu: 22.04
  - Neovim: latest version
  - Go: latest version
  - Python: > 3
  - Node.js: latest version
  - Terraform: latest version
- Linter
  - Go
    - goimports
    - gopls
    - golangci-lint
  - Python
    - flake8
    - autopep8
    - mypy
  - JavaScript
    - eslint
    - prettier
- Plugins
  - packer.nvim...Plugin manager
  - nvim-lspconfig...Setting LSP
  - null-ls.nvim...diagnostic, autoformatter
  - nvim-cmp...Completion
  - fern.vim...File manager
  - gruvbox...Color scheme
  - vim-airline...Status tabline
  - vim-gitgutter...Show `git diff` in the gutter(sign column)
  - vim-indent-guides...Show an indent guides
    and so on...

## Requirements

The app requires the following to run:

- Docker
- Docker Compose

## Getting Started

To use the environment, clone the repo and execute `docker-compose up`.

```
git clone git@github.com:hodanov/docker-template-nvim.git
cd docker-template-nvim
docker network create my-nvim
docker compose up -d
```

After launching containers, execute the following command to attach the "nvim" container.

```
docker compose exec nvim-dev bash --login
```

The `--login` option is required to read the `.bash_profile` file.

Thank you.

## Author

[Hoda](https://hodalog.com)
