# Neovim Rules

## Scope

- This file applies to changes under `nvim/`.

## General

- Keep configuration modular; place new modules under `nvim/config/lua/`.
- Wire new modules from `nvim/config/init.lua` or `nvim/config/lua/plugins.lua`.
- Prefer small, focused files over large monolithic configs.

## Plugins

- Add plugin specs in `nvim/config/lua/plugins.lua`.
- Configure plugins in dedicated files under `nvim/config/lua/`.
- When adding a plugin, include minimal config and document why it is needed.

## LSP / Diagnostics / Formatting

- Keep LSP settings under `nvim/config/lua/lsp/`.
- Avoid hardcoding local paths; use portable defaults.
- When changing diagnostics/formatters, verify the related tool exists in the container image.

## UI / Editor Behavior

- UI-focused changes should stay isolated (e.g., lualine, treesitter, cmp).
- Avoid changing keymaps without updating any related comments or docs.

## Formatting

- When editing Lua files, run `stylua .`.
