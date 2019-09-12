# Golang + Vim/Neovim on docker

This is the dev-environment for Vim/Neovim and golang on docker.

This environment is installed flake8 and autopep8, so simple Python coding is possible too.

This is using the following technologies and vim-plugins:

- Environments
  - Docker
  - Docker Compose
  - golang:1.12.7-alpine
  - ubuntu:18.04
  - vim:8
  - Neovim:0.3.8
  - python:3
  - pip:3
  - flake8
  - autopep8
- Plugins
  - Dein.vim...Plugin manager
  - NERDTree...File manager
  - ctrlp.vim...Finder
  - gruvbox...Color scheme
  - vim-airline...Status tabline
  - vim-gitgutter...Show `git diff` in the gutter(sign column)
  - indentLine...Add indent lines
  - Dockerfile.vim...Snippet for dockerfile and docker-compose.yml
  - vim-go...Development tool for Golang
  - autopep8...Run autopep8 when saving file
  - vim-surround...Do surroundings: for example {}, (), '', "" and so on.
  - ALE...Asynchronous Lint Engine, error check 
  - coc.nvim...Auto complete engine

## Requirements

The app requires the following to run:

- Docker
- Docker Compose

## Getting Started

To use the environment, clone the repo and execute `docker-compose up`.

```
git clone git@github.com:hodanov/docker-env-for-vim.git 
cd docker-template-vim
docker-compose up -d
```

After launching containers, execute the following command to attach the "vim" container. 

```
docker-compose exec vim bash --login
```

The `--login` option is required to read the `.vimrc` file.

After attaching the container, execute the following command. This is the command that installs dependencies to use vim-go.

```
nvim +GoInstallBinaries +q
```

If you want to use auto completion, execute `CocInstall` command as necessary. 

```
nvim +CocInstall coc-python
```

Please refer to the below about `CocInstall`.

https://github.com/neoclide/coc.nvim

Thank you.

## Author

[Hoda](https://hodalog.com)
