FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Asia/Tokyo

COPY ./config/.vimrc /root/
COPY ./config/init.vim /root/.config/nvim/
COPY ./config/dein.toml /root/.vim/
COPY ./config/dein_lazy.toml /root/.vim/
COPY ./config/.bash_profile /root/

RUN mkdir /root/.vim/servers \
    && mkdir /root/.vim/undo \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && apt update && apt install -y \
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
    sysstat \
    ####################
    # Enable sysstat
    # && sed -i 's/ENABLED="false"/ENABLED="true"/' /etc/default/sysstat \
    # && service sysstat restart \
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
    && apt install -y --no-install-recommends vim \
    ####################
    # NeoVim
    && wget https://github.com/neovim/neovim/releases/download/stable/nvim.appimage \
    && chmod u+x ./nvim.appimage \
    && ./nvim.appimage --appimage-extract \
    ####################
    # Dein.vim
    && wget "https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh" \
    && sh ./installer.sh ~/.cache/dein \
    && rm ./installer.sh \
    ####################
    # apt clean
    && apt autoremove -y \
    && apt clean -y

ENV PATH $PATH:/squashfs-root/usr/bin:/usr/local/go/bin
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
    && go install golang.org/x/tools/cmd/...@latest \
    && go get golang.org/x/tools/gopls@latest \
    && go install github.com/x-motemen/gore/cmd/gore@latest \
    && go install github.com/go-delve/delve/cmd/dlv@latest \
    && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest \
    && go install github.com/kazukousen/gouml/cmd/gouml@latest

WORKDIR /myubuntu
