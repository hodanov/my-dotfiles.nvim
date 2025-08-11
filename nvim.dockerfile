####################
# Stage 1: Build Neovim from source
FROM ubuntu:24.04 AS nvim-builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends \
  ninja-build gettext cmake curl unzip git build-essential ca-certificates \
  && update-ca-certificates \
  && git clone https://github.com/neovim/neovim /neovim \
  && cd /neovim \
  && git checkout stable \
  && make CMAKE_BUILD_TYPE=RelWithDebInfo \
  && make install DESTDIR=/neovim-install \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

####################
# Stage 2: Runtime and tooling
FROM ubuntu:24.04

COPY ./config/.bash_profile /root/
COPY ./config/dependencies/pyproject.toml /
COPY ./config/npm-tools/ /opt/npm-tools/
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Asia/Tokyo

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV NODENV_ROOT="/root/.nodenv"
ENV PATH="/root/.nodenv/shims:/root/.nodenv/bin:/usr/local/go/bin:/root/go/bin:/root/.cargo/bin:/root/.local/bin:/opt/npm-tools/node_modules/.bin:${PATH}"
ENV NODE_PATH="/opt/npm-tools/node_modules"
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl unzip wget ca-certificates ripgrep build-essential \
  python3 python3-dev python3-venv \
  mysql-client shellcheck git \
  ####################
  # Set up timezone and locale.
  && mkdir -p /root/.local/state/nvim/undo \
  && ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime \
  && echo "$TZ" > /etc/timezone \
  && update-ca-certificates \
  ####################
  # Node.js, nodenv, node-build
  && git clone https://github.com/nodenv/nodenv.git "$NODENV_ROOT" \
  && mkdir -p "$NODENV_ROOT/plugins" \
  && git clone https://github.com/nodenv/node-build.git "$NODENV_ROOT/plugins/node-build" \
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
  && cargo install stylua \
  ####################
  # Auto remove and clean up.
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

ENV NODENV_ROOT="/root/.nodenv"
ENV PATH="/root/.nodenv/shims:/root/.nodenv/bin:/usr/local/go/bin:/root/go/bin:/root/.cargo/bin:/root/.local/bin:/opt/npm-tools/node_modules/.bin:${PATH}"
ENV PYTHONIOENCODING=utf-8
RUN : \
  ####################
  # Install pinned npm tools with package.json
  && eval "$(nodenv init -)" \
  && npm --version >/dev/null \
  && cd /opt/npm-tools && npm install --omit=dev --no-audit --no-fund \
  && nodenv rehash \
  && apt-get purge -y build-essential \
  ####################
  # Add PATH to use 'go' command.
  && export PATH="$PATH:/usr/local/go/bin" \
  ####################
  # Install some Go packages.
  && go install golang.org/x/tools/cmd/...@latest \
  && go install golang.org/x/tools/gopls@latest \
  && go install github.com/go-delve/delve/cmd/dlv@latest \
  && go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest \
  && go install github.com/nametake/golangci-lint-langserver@latest

####################
# Bring Neovim artifacts from builder
COPY --from=nvim-builder /neovim-install/ /

####################
# Copy Neovim configs after build for better caching
COPY ./config/init.lua /root/.config/nvim/
COPY ./config/lua/ /root/.config/nvim/lua/
COPY ./config/ruff.toml /root/.config/ruff/

WORKDIR /myubuntu
