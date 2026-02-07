# Repository Guidelines

## Project Structure

- `environment/`: Docker build/runtime and toolchain definitions.
  - `environment/docker/`: `nvim.dockerfile` and `docker-compose.yml`.
  - `environment/tools/go/`: pinned Go tools (`go-tools.txt`, `update-go-tools.sh`).
  - `environment/tools/python/`: Python deps and config (`pyproject.toml`, `ruff.toml`).
  - `environment/tools/node/`: Node CLI tooling (`package.json`).
- `nvim/`: Neovim configuration.
  - `nvim/config/`: `init.lua` and `lua/**`.
- `docs/`: operational rules (plan to place under `docs/dev-rules/`).
- `assets/`: screenshots and static media.

## Build, Test, and Development Commands

- `docker compose -f environment/docker/docker-compose.yml up -d`: build (if needed) and start the dev container.
- `docker container exec -it nvim-dev bash --login`: enter the container with correct shell env.
- `./environment/tools/go/update-go-tools.sh`: refresh Go tool versions in `environment/tools/go/go-tools.txt`.
- Optional: `docker inspect nvim-dev | jq -r '.[0].State.Health.Log[0].Output' | sed 's/\x1b\[[0-9;]*m//g'` to check health output.

## Coding Style & Naming Conventions

- Lua config files are modular; keep new plugin configs in `nvim/config/lua/` and require them from `nvim/config/lua/plugins.lua` or `nvim/config/init.lua`.
- Tool versions are pinned and should be updated via existing workflows or the script above.
- Keep `ARG` lines in `environment/docker/nvim.dockerfile` unindented and single-line so automation can edit them.

## Testing Guidelines

- No repository-level test suite is defined. Linting/formatting is handled via Neovim (conform.nvim, nvim-lint, LSP) and pinned CLI tools.
- For Python tooling, `pytest` is included for use inside the container when needed.
- When editing TOML files:
  - Run `tombi lint` and fix errors.
  - After lint passes, run `tombi format`.
- When editing JSON or YAML files:
  - Run `prettier --check .` and fix errors.
  - After check passes, run `prettier --write .`.
- When editing Markdown files:
  - Run `markdownlint-cli2 --fix *` and fix any remaining issues.

## Commit & Pull Request Guidelines

- Recent commits follow short, conventional prefixes like `chore:` and `build(deps):` for maintenance and dependency bumps. Keep commit messages concise and action-focused.
- PRs are typically dependency updates or config changes. Include a clear summary, note the affected tools/files, and mention whether a container rebuild is required.

## Security & Configuration Tips

- This repo assumes macOS (arm64) plus Docker; adjust `environment/docker/nvim.dockerfile` for other platforms.
- Rebuild the image when changing tool versions or `environment/tools/node/package.json`.
