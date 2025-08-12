####################
# Base image with common dependencies and Japanese fonts
FROM ubuntu:24.04 AS base

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Asia/Tokyo
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
  # Common tools
  curl unzip wget ca-certificates git build-essential pkg-config \
  # Japanese fonts and locales
  fonts-noto-cjk fonts-noto-cjk-extra language-pack-ja \
  locales locales-all \
  && update-ca-certificates \
  # Japanese local settings
  && locale-gen ja_JP.UTF-8 \
  && update-locale LANG=ja_JP.UTF-8 \
  # TimeZone settings
  && ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime \
  && echo "$TZ" > /etc/timezone \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

ENV LANG=ja_JP.UTF-8
ENV LANGUAGE=ja_JP:ja
ENV LC_ALL=ja_JP.UTF-8

####################
# Stage 1: Build Neovim from source
FROM base AS nvim-builder

ARG NEOVIM_VERSION=0.11.3
RUN apt-get update && apt-get install -y --no-install-recommends \
  ninja-build gettext cmake \
  && git clone https://github.com/neovim/neovim /neovim \
  && cd /neovim \
  && git checkout "v$NEOVIM_VERSION" \
  && make -j"$(nproc)" CMAKE_BUILD_TYPE=RelWithDebInfo \
  && make install DESTDIR=/neovim-install \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

####################
# Stage 2: Build Node runtime and npm tools
FROM base AS node-builder

ARG NODE_VERSION=22.18.0
ARG NPM_VERSION=11.5.2
ENV NODE_HOME="/opt/node"
ENV PATH="${NODE_HOME}/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends xz-utils \
  && ARCH="$(dpkg --print-architecture)" \
  && case "$ARCH" in \
    amd64) NODE_ARCH="linux-x64" ;; \
    arm64) NODE_ARCH="linux-arm64" ;; \
    *) echo "Unsupported arch: $ARCH" && exit 1 ;; \
  esac \
  && cd /tmp \
  && NODE_TARBALL="node-v${NODE_VERSION}-${NODE_ARCH}.tar.xz" \
  && NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/${NODE_TARBALL}" \
  && curl -fsSL "$NODE_URL" -o "$NODE_TARBALL" \
  && tar -xJf "$NODE_TARBALL" \
  && mkdir -p "$NODE_HOME" \
  && mv "/tmp/node-v${NODE_VERSION}-${NODE_ARCH}"/* "$NODE_HOME"/ \
  && rm -rf "/tmp/node-v${NODE_VERSION}-${NODE_ARCH}" "$NODE_TARBALL" \
  && npm install -g npm@"$NPM_VERSION" \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

COPY ./config/npm-tools/ /opt/npm-tools/
RUN cd /opt/npm-tools && npm install --omit=dev --no-audit --no-fund

####################
# Stage 3: Build Go toolchain and tools
FROM base AS go-builder

ARG GO_VERSION=1.24.6

RUN ARCH="$(dpkg --print-architecture)" \
  && case "$ARCH" in \
    amd64) GO_ARCH="linux-amd64" ;; \
    arm64) GO_ARCH="linux-arm64" ;; \
    *) echo "Unsupported arch: $ARCH" && exit 1 ;; \
  esac \
  && GO_TARBALL="go${GO_VERSION}.${GO_ARCH}.tar.gz" \
  && GO_URL="https://go.dev/dl/${GO_TARBALL}" \
  && wget --progress=dot:giga "$GO_URL" \
  && tar -C /usr/local -xzf "$GO_TARBALL" \
  && rm "$GO_TARBALL"

ENV PATH="/usr/local/go/bin:${PATH}"
RUN go install golang.org/x/tools/cmd/...@latest \
  && go install golang.org/x/tools/gopls@latest \
  && go install github.com/go-delve/delve/cmd/dlv@latest \
  && go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest \
  && go install github.com/nametake/golangci-lint-langserver@latest

####################
# Stage 4: Build Rust-based tools
FROM base AS rust-builder

ARG RUST_TOOLCHAIN=stable
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain "$RUST_TOOLCHAIN"
ENV PATH="/root/.cargo/bin:${PATH}"
RUN cargo install stylua

####################
# Stage 5: Build Python venv with uv
FROM base AS python-builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-venv \
  && curl -LsSf https://astral.sh/uv/install.sh | sh \
  && export PATH="$HOME/.local/bin:$PATH" \
  && uv --version >/dev/null \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

COPY ./config/dependencies/pyproject.toml /opt/python/
WORKDIR /opt/python
RUN export PATH="$HOME/.local/bin:$PATH" \
  && uv sync --project .
WORKDIR /

####################
# Final stage
FROM base

COPY ./config/.bash_profile /root/

RUN apt-get update && apt-get install -y --no-install-recommends \
  ripgrep python3 mysql-client shellcheck \
  && mkdir -p /root/.local/state/nvim/undo \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

ENV PYTHONIOENCODING=utf-8

####################
# Bring toolchains and Neovim from builders
COPY --from=node-builder /opt/node/ /opt/node/
COPY --from=node-builder /opt/npm-tools/ /opt/npm-tools/
COPY --from=go-builder /usr/local/go/ /usr/local/go/
COPY --from=go-builder /root/go/bin/ /root/go/bin/
COPY --from=rust-builder /root/.cargo/bin/stylua /usr/local/bin/stylua
COPY --from=python-builder /opt/python/.venv/ /opt/python/.venv/
COPY --from=nvim-builder /neovim-install/ /
COPY --from=python-builder /root/.local/bin/uv /usr/local/bin/uv
COPY --from=python-builder /root/.local/bin/uvx /usr/local/bin/uvx

ENV PATH="/opt/python/.venv/bin:/opt/node/bin:/opt/npm-tools/node_modules/.bin:/usr/local/go/bin:/root/go/bin:${PATH}"
ENV NODE_PATH="/opt/npm-tools/node_modules"

####################
# Copy Neovim configs after build for better caching
COPY ./config/init.lua /root/.config/nvim/
COPY ./config/lua/ /root/.config/nvim/lua/
COPY ./config/ruff.toml /root/.config/ruff/

WORKDIR /myubuntu

HEALTHCHECK --interval=10m --timeout=30s --start-period=5m --retries=1 \
  CMD nvim --headless -c 'lua vim.health.check("checkhealth")' -c 'qa!' 2>/dev/null || exit 1
