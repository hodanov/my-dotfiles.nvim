FROM ubuntu:18.04
WORKDIR /myubuntu
COPY ./vimrc/.vimrc /root/
COPY ./vimrc/init.vim /root/.config/nvim/
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
    nodejs npm && \
    npm install -g yarn neovim && \
    #Golang
    wget https://dl.google.com/go/go1.12.7.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.12.7.linux-amd64.tar.gz && \
    rm go1.12.7.linux-amd64.tar.gz && \
    # Python linter, formatter and so on.
    pip3 install flake8 autopep8 python-language-server vim-vint neovim && \
    # NeoVim
    apt install -y software-properties-common && \
    add-apt-repository ppa:neovim-ppa/stable && \
    apt update && apt install -y python3-neovim && \
    # Dein.vim
    curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh && \
    sh ./installer.sh ~/.cache/dein && \
    rm ./installer.sh
ENV PATH $PATH:/usr/local/go/bin
ENV PYTHONIOENCODING utf-8
#RUN nvim +GoInstallBinaries +q
        #nvim +CocInstall coc-json coc-tsserver coc-html coc-css coc-yaml coc-python coc-emmet coc-git +q
