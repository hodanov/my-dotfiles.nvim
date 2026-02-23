# Plan

`agents/` のサブエージェントファイルを Claude Code, Cursor, Codex CLI の
ユーザーレベルディレクトリへコピーする make コマンドを実装する。
Claude/Cursor は Markdown をそのままコピー、
Codex CLI は TOML 形式への変換が必要なため専用ファイルを用意する。

## Scope

- In:
  - Makefile への agents-copy ターゲット追加（全ツール対応）
  - Codex CLI 用 TOML エージェントファイルの作成（`agents/codex/`）
  - README.md / README.ja.md のドキュメント更新
- Out:
  - 既存の link / skills-copy ターゲットの変更
  - Codex CLI の config.toml 自体の新規生成

## Codex CLI のサブエージェント配置方式

Codex CLI は `~/.codex/config.toml` の `[agents.<name>]` セクションで定義する。

```toml
# ~/.codex/config.toml に追記
[agents.investigation-scout]
description = "Phase.1 investigation agent: broad scanning, returns Scout Report"
config_file = "agents/investigation-scout.toml"
```

```toml
# ~/.codex/agents/investigation-scout.toml
model = "gpt-5.3-codex"
model_reasoning_effort = "medium"
sandbox_mode = "read-only"
developer_instructions = "..."
```

### Claude/Cursor との対応表

| 機能 | Claude/Cursor | Codex CLI |
| --- | --- | --- |
| ファイル形式 | Markdown + YAML frontmatter | TOML |
| 配置先 | `~/.claude/agents/`, `~/.cursor/agents/` | `~/.codex/agents/` + `config.toml` 登録 |
| model: sonnet | そのまま | `gpt-5.3-codex` |
| permissionMode: plan | そのまま | `sandbox_mode = "read-only"` |
| memory: project | そのまま | 非対応（プロンプトから削除） |
| tools 制限 | frontmatter で指定 | 非対応（developer_instructions に記述） |

## Action items

- [ ] `agents/codex/investigation-scout.toml` を作成する
- [ ] `agents/codex/investigation-diver.toml` を作成する（memory 関連の記述は除外）
- [ ] Makefile に新規変数を追加する（AGENTS_MD_SRC, CODEX_AGENTS_SRC 等）
- [ ] Makefile に `copy_agents_md` define を追加する（Claude/Cursor 用）
- [ ] Makefile に `codex-agents-copy` ターゲットを追加する（TOML コピー + config.toml 登録）
- [ ] Makefile に `claude-agents-copy`, `cursor-agents-copy`, `agents-copy` ターゲットを追加する
- [ ] README.md / README.ja.md に agents-copy セクションを追加する
- [ ] 動作検証する

## 新規ターゲット一覧

| ターゲット | 動作 |
| --- | --- |
| `agents-copy` | 全ツール向け一括コピー |
| `claude-agents-copy` | `agents/*.md` → `~/.claude/agents/` |
| `cursor-agents-copy` | `agents/*.md` → `~/.cursor/agents/` |
| `codex-agents-copy` | `agents/codex/*.toml` → `~/.codex/agents/` + `config.toml` 登録 |

## Open questions

- なし（Codex モデルは gpt-5.3-codex に決定済み）
