FROM ubuntu:24.04

COPY ./config/.bash_profile /root/
COPY ./config/dependencies/pyproject.toml /
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Asia/Tokyo

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends \
  software-properties-common ninja-build gettext cmake \
  curl unzip wget \
  python3 cmake python3-dev python3-venv \
  build-essential \
  mysql-client shellcheck git \
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
  && ARCH="$(dpkg --print-architecture)" \
  && case "$ARCH" in \
  amd64) GO_ARCH="linux-amd64" ;; \
  arm64) GO_ARCH="linux-arm64" ;; \
  *) echo "Unsupported arch: $ARCH" && exit 1 ;; \
  esac \
  && GO_REGEX_PATTERN="go[0-9]\.[0-9]{1,2}\.[0-9]{1,2}\.${GO_ARCH}\.tar\.gz" \
  && GO_LATEST_PACKAGE="$(curl -s https://go.dev/dl/?mode=json | grep -Eo "$GO_REGEX_PATTERN" | sort -V | tail -1)" \
  && GO_URL="https://go.dev/dl/${GO_LATEST_PACKAGE}" \
  && wget --progress=dot:giga "$GO_URL" \
  && tar -C /usr/local -xzf "$GO_LATEST_PACKAGE" \
  && rm "$GO_LATEST_PACKAGE" \
  ####################
  # Python linter, formatter and so on.
  && curl -LsSf https://astral.sh/uv/install.sh | sh \
  && export PATH="$HOME/.local/bin:$PATH" \
  && uv --version >/dev/null \
  && uv sync \
  ####################
  # Rust, stylua
  && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
  && source $HOME/.cargo/env \
  && cargo install stylua ripgrep \
  ####################
  # Auto remove and clean up.
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/local/go/bin:/root/go/bin:/root/.cargo/bin:/root/.local/bin:${PATH}"
ENV PYTHONIOENCODING=utf-8
RUN : \
  ####################
  # Install yarn, eslint, prettier.
  && eval "$(nodenv init -)" \
  && npm install --global yarn@latest typescript@latest typescript-language-server@latest eslint@latest \
  vscode-langservers-extracted@latest @fsouza/prettierd@latest prettier-plugin-go-template@latest bash-language-server@latest \
  textlint@latest yaml-language-server@latest tombi@latest textlint-rule-preset-ja-technical-writing@latest \
  textlint-rule-preset-japanese@latest \
  && nodenv rehash \
  ####################
  # Add PATH to use 'go' command.
  && export PATH="$PATH:/usr/local/go/bin" \
  ####################
  # Install some Go packages.
  && go install golang.org/x/tools/cmd/...@latest \
  && go install golang.org/x/tools/gopls@latest \
  && go install github.com/go-delve/delve/cmd/dlv@latest \
  && go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest \
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
COPY ./config/init.lua /root/.config/nvim/
COPY ./config/lua/ /root/.config/nvim/lua/
COPY ./config/ruff.toml /root/.config/ruff/
WORKDIR /neovim
RUN git checkout stable \
  && make CMAKE_BUILD_TYPE=RelWithDebInfo \
  && make install

WORKDIR /myubuntu
