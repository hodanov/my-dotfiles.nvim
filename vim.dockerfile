FROM ubuntu:18.04

WORKDIR /myubuntu

COPY ./config/.vimrc /root/
COPY ./config/init.vim /root/.config/nvim/
COPY ./config/dein.toml /root/.vim/
COPY ./config/dein_lazy.toml /root/.vim/
COPY ./config/.bash_profile /root/

RUN mkdir /root/.vim/servers \
    && mkdir /root/.vim/undo \
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
    nodejs npm \
    && npm install -g yarn \
    ####################
    # Go, goenv
    && git clone https://github.com/syndbg/goenv.git /root/.goenv \
    && ln -s /root/.goenv/bin/* /usr/local/bin \
    # && GO_LATEST=`goenv install --list | sort -V | tail -1 | xargs` \
    # && goenv install ${GO_LATEST} \
    # && goenv global ${GO_LATEST} \
    # && export PATH="$PATH:/root/.goenv/versions/${GO_LATEST}/bin" \
    && GO_REGEX_PATTERN='go[0-9]\.[0-9]{1,2}\.[0-9]{1,2}\.linux-amd64\.tar\.gz' \
    && GO_LATEST=`curl -s https://golang.org/dl/ | egrep -o ${GO_REGEX_PATTERN} | sort -V | tail -1` \
    && GO_URL="https://dl.google.com/go/${GO_LATEST}" \
    && wget ${GO_URL} \
    && tar -C /usr/local -xzf ${GO_LATEST} \
    && rm ${GO_LATEST} \
    ####################
    # Python linter, formatter and so on.
    && pip3 install flake8 autopep8 mypy python-language-server vim-vint \
    ####################
    # eslint, eslint-plugin-vue
    && npm install -g eslint eslint-plugin-vue eslint-plugin-react eslint-plugin-node eslint_d \
    ####################
    # Terraform
    && git clone https://github.com/tfutils/tfenv.git /root/.tfenv \
    && ln -s /root/.tfenv/bin/* /usr/local/bin \
    && tfenv install latest \
    && tfenv use latest \
    ####################
    # Vim
    && add-apt-repository ppa:jonathonf/vim \
    && apt install -y vim \
    ####################
    # NeoVim
    && add-apt-repository ppa:neovim-ppa/stable \
    && apt install -y neovim python3-neovim \
    ####################
    # Dein.vim
    && wget "https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh" \
    && sh ./installer.sh ~/.cache/dein \
    && rm ./installer.sh

ENV PATH $PATH:/usr/local/go/bin
ENV PYTHONIOENCODING utf-8

RUN /bin/bash -c 'nvim -c ":silent! call dein#install() | :q"' \
    && go get golang.org/x/tools/cmd/... \
    && go get golang.org/x/lint/golint \
    && go get github.com/motemen/gore/cmd/gore \
    && go get github.com/mdempsky/gocode \
    && go get github.com/k0kubun/pp
