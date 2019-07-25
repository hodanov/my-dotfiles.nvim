# Golang + Vim on docker

This is the dev-environment for vim and golang on docker.

This is using the following technologies and vim-plugins:

- Docker
- Docker Compose
- golang:1.12.7-alpine
- ubuntu:18.04
- vim
- vundle
- NERDTree
- Monokai
- vim-go


## Requirements

The app requires the following to run:

- Docker
- Docker Compose

## Getting Started

To use the environment, clone the repo and execute `docker-compose up`.

```
git clone git@github.com:hodanov/docker-env-for-vim.git 
cd docker-env-for-vim
docker-compose up -d
```

After launching containers, execute the following command to attach the "vim" container. 

```
docker-compose exec vim bash --login
```

The `--login` option is required to read the `.vimrc` file.

Thank you.

## Author

[Hodaka Sakamoto](https://hodalog.com)
