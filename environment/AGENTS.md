# Environment Rules

## Scope

- This file applies to changes under `environment/`.

## General

- Keep version pins in `environment/docker/nvim.dockerfile` as single-line, unindented `ARG` entries.
- Prefer updating tool versions via existing workflows or `environment/tools/go/update-go-tools.sh`.
- When paths change, update CI workflows, Dependabot config, and `.dockerignore`.

## Docker

- Use `docker compose -f environment/docker/docker-compose.yml`.
- After changing `environment/docker/nvim.dockerfile` or compose config, verify:
  - `hadolint environment/docker/nvim.dockerfile`
  - `docker compose -f environment/docker/docker-compose.yml build`

## Tools

- Go tools: update `environment/tools/go/go-tools.txt` via script or workflow.
- Python tools: update `environment/tools/python/pyproject.toml` and keep `ruff.toml` in the same dir.
- Node tools: update `environment/tools/node/package.json` and rebuild the image.

## Safety

- Avoid deleting tool pins or moving directories without updating docs/CI configs.
