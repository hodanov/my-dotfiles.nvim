# Go + Vim/Neovim on docker

This is the dev-environment for Vim/Neovim on docker.

This is using the following technologies and vim-plugins:

- Environment
  - Ubuntu: 18.04
  - Vim: > 8
  - Neovim: > 0.3.8
  - Go: > 1.13
  - Python: > 3
- Linter
  - Go
    - gofmt
    - go vet
    - goimports
    - golint
  - Python
    - flake8
    - autopep8
    - mypy
- Vim plugins
  - dein.vim...Plugin manager
  - NERDTree...File manager
  - gruvbox...Color scheme
  - vim-lsp...LSP plugin
  - vim-lsp-settings...auto configurations for vim-lsp
  - vim-airline...Status tabline
  - vim-gitgutter...Show `git diff` in the gutter(sign column)
  - Dockerfile.vim...Snippet for dockerfile and docker-compose.yml
  - autopep8...Run autopep8 when saving file
  - emmet-vim...Support coding HTML/CSS
  - vim-surround...Do surroundings: for example {}, (), '', "" and so on.
  - ALE...Asynchronous Lint Engine, error check
  and so on...

## Requirements

The app requires the following to run:

- Docker
- Docker Compose

## Getting Started

To use the environment, clone the repo and execute `docker-compose up`.

```
git clone git@github.com:hodanov/docker-template-vim.git
cd docker-template-vim
docker-compose up -d
```

After launching containers, execute the following command to attach the "vim" container.

```
docker-compose exec vim-dev bash --login
```

The `--login` option is required to read the `.vimrc` file.

Thank you.

## Author

[Hoda](https://hodalog.com)
