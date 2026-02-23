[![English](https://img.shields.io/badge/lang-English-blue)](README.md) [![日本語](https://img.shields.io/badge/lang-日本語-orange)](README.ja.md)

# ai-agent-config

This repository manages my AGENTS.md file for Codex CLI, and can also generate a CLAUDE.md symlink for Claude Code.

## Structure

- agents.xml: The actual content backing `AGENTS.md` and `CLAUDE.md`. Create a symlink from `~/.codex/AGENTS.md` or `~/.claude/CLAUDE.md` to this file.
- agents/: Subagent definitions for investigation workflows (Markdown for Claude/Cursor, TOML for Codex CLI).
- Makefile: Provides commands to create and remove the symlink(s).
- skills/: Shared Skills for Codex CLI, Claude Code, and Cursor.

## Usage

Create a symlink from `~/.codex/AGENTS.md` to `agents.xml`:

```sh
cd ai-agent-config
make codex-link
```

To remove the symlink:

```sh
make codex-unlink
```

Create a symlink from `~/.claude/CLAUDE.md` to `agents.xml`:

```sh
cd ai-agent-config
make claude-link
```

To remove the symlink:

```sh
make claude-unlink
```

Copy skills into user-level directories for Codex/Claude/Cursor:

```sh
make skills-copy
```

Per-tool options:

```sh
make codex-skills-copy
make claude-skills-copy
make cursor-skills-copy
```

Legacy alias (copy for Codex only):

```sh
make codex-skills-install
```

Copy agents into user-level directories for Codex/Claude/Cursor:

```sh
make agents-copy
```

Per-tool options:

```sh
make codex-agents-copy
make claude-agents-copy
make cursor-agents-copy
```

For Codex CLI, `agents-copy` also registers `[agents.*]` entries in `~/.codex/config.toml`.

## Why define AGENTS.md in XML

According to the GPT-5 for Coding Cheatsheet (PDF), using XML-like tags to structure instructions is recommended. The cheatsheet clearly states “XML-like syntax to help structure instructions” and provides concrete examples.

The `agents.xml` in this repository was authored with that cheatsheet as a reference.

## References

- [GPT-5 for Coding Cheatsheet (PDF)](https://cdn.openai.com/API/docs/gpt-5-for-coding-cheatsheet.pdf)
- [GPT-5 prompting guide](https://cookbook.openai.com/examples/gpt-5/gpt-5_prompting_guide)
