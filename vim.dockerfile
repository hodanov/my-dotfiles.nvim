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
    # Plugin manager
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim && \
    # Color scheme
    git clone https://github.com/sickill/vim-monokai.git && \
    git clone https://github.com/morhetz/gruvbox.git && \
    cp -R vim-monokai/colors ~/.vim && \
    cp gruvbox/colors/gruvbox.vim ~/.vim/colors && \
    rm -rf vim-monokai && \
	rm -rf gruvbox && \
    # Golang
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
    rm -rf ./squashfs-root
ENV PATH $PATH:/usr/local/go/bin
ENV PYTHONIOENCODING utf-8
RUN vim +PluginInstall +qall && \
    # vim +GoInstallBinaries +qall
    python3 ~/.vim/bundle/youcompleteme/install.py
