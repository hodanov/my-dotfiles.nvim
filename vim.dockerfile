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
    vim \
	python3 \
    python3-pip \
    build-essential cmake python3-dev && \
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim && \
    git clone https://github.com/sickill/vim-monokai.git && \
    git clone https://github.com/morhetz/gruvbox.git && \
    cp -R vim-monokai/colors ~/.vim && \
    cp gruvbox/colors/gruvbox.vim ~/.vim/colors && \
    rm -rf vim-monokai && \
	rm -rf gruvbox && \
    wget https://dl.google.com/go/go1.12.7.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.12.7.linux-amd64.tar.gz && \
    rm go1.12.7.linux-amd64.tar.gz && \
    wget http://downloads.activestate.com/Komodo/releases/11.1.0/remotedebugging/Komodo-PythonRemoteDebugging-11.1.0-91033-linux-x86_64.tar.gz && \
    mkdir /usr/lib/python3/pydbgp && \
    tar -C . -xzf Komodo-PythonRemoteDebugging-11.1.0-91033-linux-x86_64.tar.gz && \
    mv Komodo-PythonRemoteDebugging-11.1.0-91033-linux-x86_64/* /usr/lib/python3/pydbgp/ && \
    mv /usr/lib/python3/pydbgp/python3lib/* /usr/lib/python3/pydbgp/ && \
    rm Komodo-PythonRemoteDebugging-11.1.0-91033-linux-x86_64.tar.gz && \
    pip3 install flake8 autopep8 vim-vint
ENV PATH $PATH:/usr/local/go/bin
ENV PYTHONIOENCODING utf-8
RUN vim +PluginInstall +qall && \
    # vim +GoInstallBinaries +qall
    python3 /root/.vim/bundle/youcompleteme/install.py
