FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Asia/Tokyo

COPY ./config/init.vim /root/.config/nvim/
COPY ./config/lua/* /root/.config/nvim/lua/
COPY ./config/.bash_profile /root/
COPY ./config/dependencies/requirements.txt /root/

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN : \
    && mkdir -p /root/.vim/undo \
    && ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime \
    && echo "$TZ" > /etc/timezone \
    && apt-get update && apt-get install -y --no-install-recommends software-properties-common git silversearcher-ag \
    tree jq wget curl unzip python3 python3-pip build-essential cmake python3-dev python3-venv mysql-client shellcheck \
    ####################
    # Node.js, nodenv, node-build
    && git clone https://github.com/nodenv/nodenv.git /root/.nodenv \
    && ln -s /root/.nodenv/bin/* /usr/local/bin \
    && mkdir -p "$(nodenv root)"/plugins \
    && git clone https://github.com/nodenv/node-build.git "$(nodenv root)"/plugins/node-build \
    && NODE_REGEX_PATTERN='^[0-9][02468]\.[0-9]{1,2}\.[0-9]{1,2}$' \
    && NODE_LATEST_LTS_VERSION=`nodenv install -l | grep -E $NODE_REGEX_PATTERN | sort -V | tail -1` \
    && nodenv install "$NODE_LATEST_LTS_VERSION" \
    && nodenv global "$NODE_LATEST_LTS_VERSION" \
    ####################
    # Go, goenv
    && git clone https://github.com/syndbg/goenv.git /root/.goenv \
    && ln -s /root/.goenv/bin/* /usr/local/bin \
    && GO_REGEX_PATTERN='[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}$' \
    && GO_LATEST=`goenv install --list | grep -E $GO_REGEX_PATTERN | sort -V | tail -1 | xargs` \
    && goenv install "$GO_LATEST" \
    && goenv global "$GO_LATEST" \
    ####################
    # Python linter, formatter and so on.
    && pip3 install --no-cache-dir --requirement /root/requirements.txt \
    ####################
    # NeoVim
    && wget --progress=dot:giga https://github.com/neovim/neovim/releases/download/stable/nvim.appimage \
    && chmod u+x ./nvim.appimage \
    && ./nvim.appimage --appimage-extract \
    && git clone --depth 1 https://github.com/wbthomason/packer.nvim  ~/.local/share/nvim/site/pack/packer/start/packer.nvim \
    ####################
    # Install some linters and formatters.
    # && apt-get install shellcheck -y --no-install-recommends \
    ####################
    # apt-get clean
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

ENV PATH $PATH:/squashfs-root/usr/bin
ENV PYTHONIOENCODING utf-8

RUN : \
    ####################
    # Install yarn.
    && eval "$(nodenv init -)" \
    && npm install --global yarn@latest typescript@latest typescript-language-server@latest eslint@latest \
    vscode-langservers-extracted@latest prettier@latest prettier-plugin-go-template@latest bash-language-server@latest \
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
