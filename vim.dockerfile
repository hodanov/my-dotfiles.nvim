FROM ubuntu:18.04
WORKDIR /myubuntu
COPY ./vimrc /root
RUN apt update && apt install -y \
    git \
    silversearcher-ag \
    tree \
    jq \
    wget \
    curl \
    vim && \
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim && \
    git clone https://github.com/sickill/vim-monokai.git && \
    git clone https://github.com/morhetz/gruvbox.git && \
    cp -R vim-monokai/colors ~/.vim && \
    cp gruvbox/colors/gruvbox.vim ~/.vim/colors && \
    rm -rf vim-monokai && \
	rm -rf gruvbox && \
    wget https://dl.google.com/go/go1.12.7.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.12.7.linux-amd64.tar.gz && \
    rm go1.12.7.linux-amd64.tar.gz
ENV PATH $PATH:/usr/local/go/bin
RUN vim +PluginInstall +qall
    # vim +GoInstallBinaries +qall
