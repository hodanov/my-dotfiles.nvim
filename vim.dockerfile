FROM ubuntu:18.04
ENV GO_VERSION='1.13.1'
ENV GO_NAME="go${GO_VERSION}.linux-amd64.tar.gz"
ENV GO_URL="https://dl.google.com/go/${GO_NAME}"
WORKDIR /myubuntu
COPY ./config/.vimrc /root/
COPY ./config/init.vim /root/.config/nvim/
COPY ./config/coc-settings.json /root/.config/nvim/
COPY ./config/dein.toml /root/.vim/
COPY ./config/dein_lazy.toml /root/.vim/
RUN apt update && apt install -y \
    git \
    silversearcher-ag \
    tree \
    jq \
    wget \
    curl \
    vim \
    python3 \
    python3-pip \
    build-essential cmake python3-dev \
    nodejs npm \
    && npm install -g yarn neovim \
    # Golang
    && wget ${GO_URL} \
    && tar -C /usr/local -xzf ${GO_NAME} \
    && rm ${GO_NAME} \
    # Python linter, formatter and so on.
    && pip3 install flake8 autopep8 mypy python-language-server vim-vint neovim \
    # NeoVim
    && apt install -y software-properties-common \
    && add-apt-repository ppa:neovim-ppa/stable \
    && apt update && apt install -y python3-neovim \
    # Dein.vim
    && curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh \
    && sh ./installer.sh ~/.cache/dein \
    && rm ./installer.sh
ENV PATH $PATH:/usr/local/go/bin
ENV PYTHONIOENCODING utf-8
RUN /bin/bash -c 'nvim -c ":silent! call dein#install() | :q"' \
    && nvim -c "CocInstall -sync coc-json coc-tsserver coc-html coc-css coc-yaml coc-python coc-emmet coc-git|q"
    # && nvim +GoInstallBinaries +q
    # && nvim -c "execute 'silent! GoInstallBinaries' | execute 'quit'"
    # Use vim's execute command to pipe commands
    # This helps avoid "Press ENTER or type command to continue"
    # vim -c "execute 'silent GoUpdateBinaries' | execute 'quit'"
