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
    build-essential cmake python3-dev && \
    # Color scheme
    git clone https://github.com/morhetz/gruvbox.git && \
    mkdir -p ~/.vim/colors && \
    cp gruvbox/colors/gruvbox.vim ~/.vim/colors && \
    rm -rf gruvbox && \
    #Golang
    wget https://dl.google.com/go/go1.12.7.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.12.7.linux-amd64.tar.gz && \
    rm go1.12.7.linux-amd64.tar.gz && \
    # Python linter, formatter and so on.
    pip3 install flake8 autopep8 vim-vint neovim && \
    # NeoVim
    wget https://github.com/neovim/neovim/releases/download/v0.3.8/nvim.appimage && \
    chmod u+x nvim.appimage && ./nvim.appimage --appimage-extract && \
    cp ./squashfs-root/usr/bin/nvim /usr/bin/ && \
    cp -r squashfs-root/usr/share/nvim /usr/share/ && \
    rm -rf ./squashfs-root && \
    # Dein.vim
    curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh && \
    sh ./installer.sh ~/.cache/dein && \
    rm ./installer.sh
ENV PATH $PATH:/usr/local/go/bin
ENV PYTHONIOENCODING utf-8
RUN nvim +GoInstallBinaries +q
    #python3 /root/.cache/dein/repos/github.com/valloric/youcompleteme/install.py
