FROM ubuntu:24.04

COPY ./config/.bash_profile /root/
COPY ./config/dependencies/requirements.txt /root/
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Asia/Tokyo

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends software-properties-common ninja-build gettext cmake \
    curl unzip build-essential wget python3 python3-pip build-essential cmake python3-dev python3-venv mysql-client \
    shellcheck git silversearcher-ag \
    ####################
    # Set up timezone and locale.
    && mkdir -p /root/.vim/undo \
    && ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime \
    && echo "$TZ" > /etc/timezone \
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
    && GO_REGEX_PATTERN='go[0-9]\.[0-9]{1,2}\.[0-9]{1,2}\.linux-arm64\.tar\.gz' \
    && GO_LATEST_PACKAGE=`curl -s https://go.dev/dl/?mode=json | grep -Eo $GO_REGEX_PATTERN | sort -V | tail -1` \
    && GO_URL="https://go.dev/dl/$GO_LATEST_PACKAGE" \
    && wget --progress=dot:giga $GO_URL \
    && tar -C /usr/local -xzf $GO_LATEST_PACKAGE \
    && rm $GO_LATEST_PACKAGE \
    ####################
    # Python linter, formatter and so on.
    && python3 -m venv /root/.venv \
    && source /root/.venv/bin/activate \
    && python3 -m pip install --no-cache-dir --requirement /root/requirements.txt \
    ####################
    # Install some linters and formatters.
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

ENV PATH $PATH:/nvim-linux64/bin
ENV PYTHONIOENCODING utf-8
RUN : \
    ####################
    # Install yarn.
    && eval "$(nodenv init -)" \
    && npm install --global yarn@latest typescript@latest typescript-language-server@latest eslint@latest \
    vscode-langservers-extracted@latest @fsouza/prettierd@latest prettier-plugin-go-template@latest bash-language-server@latest \
    ####################
    # Add PATH to use 'go' command.
    && export PATH="$PATH:/usr/local/go/bin" \
    ####################
    # Install some Go packages.
    && go install golang.org/x/tools/cmd/...@latest \
    && go install golang.org/x/tools/gopls@latest \
    && go install github.com/go-delve/delve/cmd/dlv@latest \
    && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest \
    && go install github.com/nametake/golangci-lint-langserver@latest \
    ####################
    # Clone neovim.
    && git clone https://github.com/neovim/neovim

####################
# Build Neovim
# The nvim-linux64 is not compatible with the ARM64 architecture at May 4, 2024.
# So, we need to build Neovim from the source code.
# https://github.com/neovim/neovim/blob/master/BUILD.md#quick-start
# https://github.com/neovim/neovim/issues/15143
# https://github.com/neovim/neovim/pull/15542
COPY ./config/init.vim /root/.config/nvim/
COPY ./config/lua/* /root/.config/nvim/lua/
WORKDIR /neovim
RUN git checkout stable \
    && make CMAKE_BUILD_TYPE=RelWithDebInfo \
    && make install \
    && git clone --depth 1 https://github.com/wbthomason/packer.nvim  ~/.local/share/nvim/site/pack/packer/opt/packer.nvim \
    && nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

WORKDIR /myubuntu
