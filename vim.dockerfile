FROM ubuntu:18.04

ENV GO_VERSION='1.13.1'
ENV GO_NAME="go${GO_VERSION}.linux-amd64.tar.gz"
ENV GO_URL="https://dl.google.com/go/${GO_NAME}"

WORKDIR /myubuntu

COPY ./config/.vimrc /root/
COPY ./config/init.vim /root/.config/nvim/
# COPY ./config/coc-settings.json /root/.config/nvim/
# COPY ./config/coc-settings.json /root/.vim/
COPY ./config/dein.toml /root/.vim/
COPY ./config/dein_lazy.toml /root/.vim/
COPY ./config/.bash_profile /root/

RUN mkdir /root/.vim/servers \
    && apt update && apt install -y \
    software-properties-common \
    git \
    silversearcher-ag \
    tree \
    jq \
    wget \
    python3 \
    python3-pip \
    build-essential cmake python3-dev \
    nodejs npm \
    && npm install -g yarn \
    ####################
    # Golang
    && wget ${GO_URL} \
    && tar -C /usr/local -xzf ${GO_NAME} \
    && rm ${GO_NAME} \
    ####################
    # Python linter, formatter and so on.
    && pip3 install flake8 autopep8 mypy python-language-server vim-vint \
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
    && go get golang.org/x/tools/cmd... \
    && go get golang.org/x/lint/golint
    # && nvim -c "CocInstall -sync coc-json coc-tsserver coc-html coc-css coc-yaml coc-python coc-emmet coc-git | q"
    # && nvim -c "execute 'silent! GoInstallBinaries' | q"
    # nvim -c "CocInstall -sync coc-json coc-tsserver coc-html coc-css coc-yaml coc-python coc-emmet coc-git | q"
    # && nvim +GoInstallBinaries +q
    # Use vim's execute command to pipe commands
    # This helps avoid "Press ENTER or type command to continue"
    # vim -c "execute 'silent GoUpdateBinaries' | execute 'quit'"
