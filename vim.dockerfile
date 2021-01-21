FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /myubuntu

COPY ./config/.vimrc /root/
COPY ./config/init.vim /root/.config/nvim/
COPY ./config/dein.toml /root/.vim/
COPY ./config/dein_lazy.toml /root/.vim/
COPY ./config/.bash_profile /root/

RUN mkdir /root/.vim/servers \
    && mkdir /root/.vim/undo \
    && apt-get update && apt-get install -y \
    software-properties-common \
    git \
    silversearcher-ag \
    tree \
    jq \
    wget \
    curl \
    unzip \
    python3 \
    python3-pip \
    build-essential cmake python3-dev python3-venv \
    # nodejs npm \
    ####################
    # Node.js, nodenv, node-build
    && git clone https://github.com/nodenv/nodenv.git /root/.nodenv \
    && ln -s /root/.nodenv/bin/* /usr/local/bin \
    && mkdir -p "$(nodenv root)"/plugins \
    && git clone https://github.com/nodenv/node-build.git "$(nodenv root)"/plugins/node-build \
    && NODE_REGEX_PATTERN='^[0-9][02468]\.[0-9]{1,2}\.[0-9]{1,2}$' \
    && NODE_LATEST_LTS_VERSION=`nodenv install -l | egrep -o ${NODE_REGEX_PATTERN} | sort -V | tail -1` \
    && nodenv install ${NODE_LATEST_LTS_VERSION} \
    && nodenv global ${NODE_LATEST_LTS_VERSION} \
    ####################
    # Go, goenv
    && git clone https://github.com/syndbg/goenv.git /root/.goenv \
    && ln -s /root/.goenv/bin/* /usr/local/bin \
    && GO_REGEX_PATTERN='[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}$' \
    && GO_LATEST=`goenv install --list | egrep -o ${GO_REGEX_PATTERN} | sort -V | tail -1 | xargs` \
    && goenv install ${GO_LATEST} \
    && goenv global ${GO_LATEST} \
    #&& GO_REGEX_PATTERN='go[0-9]\.[0-9]{1,2}\.[0-9]{1,2}\.linux-amd64\.tar\.gz' \
    #&& GO_LATEST=`curl -s https://golang.org/dl/ | egrep -o ${GO_REGEX_PATTERN} | sort -V | tail -1` \
    #&& GO_URL="https://dl.google.com/go/${GO_LATEST}" \
    #&& wget ${GO_URL} \
    #&& tar -C /usr/local -xzf ${GO_LATEST} \
    #&& rm ${GO_LATEST} \
    ####################
    # Python linter, formatter and so on.
    && pip3 install flake8 autopep8 mypy python-language-server vim-vint \
    ####################
    # Terraform
    && git clone https://github.com/tfutils/tfenv.git /root/.tfenv \
    && ln -s /root/.tfenv/bin/* /usr/local/bin \
    && tfenv install latest \
    && tfenv use latest \
    ####################
    # Vim
    && add-apt-repository ppa:jonathonf/vim \
    && apt-get install -y --no-install-recommends vim \
    ####################
    # NeoVim
    && add-apt-repository ppa:neovim-ppa/stable \
    && apt-get install -y --no-install-recommends neovim python3-neovim \
    ####################
    # Dein.vim
    && wget "https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh" \
    && sh ./installer.sh ~/.cache/dein \
    && rm ./installer.sh

ENV PATH $PATH:/usr/local/go/bin
ENV PYTHONIOENCODING utf-8

RUN : \
    ####################
    # Add PATH to use 'go' command.
    && export GOENV_ROOT="$HOME/.goenv" \
    && export PATH="$GOENV_ROOT/bin:$PATH" \
    && eval "$(goenv init -)" \
    && export PATH="$GOROOT/bin:$PATH" \
    && export PATH="$PATH:$GOPATH/bin" \
    ####################
    # Install some packages.
    && go get golang.org/x/tools/cmd/... \
    && go get golang.org/x/lint/golint \
    && go get github.com/motemen/gore/cmd/gore \
    && go get github.com/mdempsky/gocode \
    && go get github.com/k0kubun/pp
