FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Asia/Tokyo

COPY ./config/init.vim /root/.config/nvim/
COPY ./config/lua/* /root/.config/nvim/lua/
COPY ./config/.bash_profile /root/

RUN : \
    && mkdir -p /root/.vim/undo \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && apt update && apt install -y software-properties-common git silversearcher-ag tree jq wget curl unzip \
    python3 python3-pip build-essential cmake python3-dev python3-venv mysql-client \
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
    && pip3 install pylint mypy black python-lsp-server pylsp-mypy vim-vint \
    ####################
    # Terraform
    && git clone https://github.com/tfutils/tfenv.git /root/.tfenv \
    && ln -s /root/.tfenv/bin/* /usr/local/bin \
    && tfenv install latest \
    && tfenv use latest \
    ####################
    # NeoVim
    && wget https://github.com/neovim/neovim/releases/download/stable/nvim.appimage \
    && chmod u+x ./nvim.appimage \
    && ./nvim.appimage --appimage-extract \
    && git clone --depth 1 https://github.com/wbthomason/packer.nvim  ~/.local/share/nvim/site/pack/packer/start/packer.nvim \
    ####################
    # Install some linters and formatters.
    && apt install shellcheck \
    ####################
    # apt clean
    && apt autoremove -y \
    && apt clean -y

ENV PATH $PATH:/squashfs-root/usr/bin
ENV PYTHONIOENCODING utf-8

RUN : \
    ####################
    # Install yarn.
    && eval "$(nodenv init -)" \
    && npm install --global yarn typescript typescript-language-server eslint vscode-langservers-extracted \
    prettier prettier-plugin-go-template bash-language-server \
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
    && go install golang.org/x/tools/gopls@latest \
    && go install github.com/go-delve/delve/cmd/dlv@latest \
    && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest \
    && go install github.com/nametake/golangci-lint-langserver@latest \
    ####################
    # Execute `:PackerCompile`.
    && nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

WORKDIR /myubuntu
