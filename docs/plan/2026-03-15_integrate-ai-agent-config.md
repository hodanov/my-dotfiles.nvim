# Plan: ai-agent-config リポジトリの統合

`ai-agent-config` リポジトリを `my_dotfiles_nvim` に統合し、Neovim + Docker + AI Bridge + AIエージェント設定を単一のPDEモノレポとして管理する。CI/ワークフローの重複解消と AGENTS.md/CLAUDE.md 管理の一元化が主な動機。

## Background

- `my_dotfiles_nvim` はNeovimを中心に据えた個人開発環境（PDE）であり、Docker環境・AI Bridge（Go実装）・CI/CDを含む
- `ai-agent-config` はClaude Code / Codex CLI / Cursor 向けのエージェント定義・スキル・settings・hooksを一元管理するリポジトリ
- 両リポジトリで markdownlint / prettier / shfmt / shellcheck 等のlint設定が重複している
- AI Bridgeの開発と、それが呼び出すAIエージェントの定義が別リポジトリに分かれている
- `yaritaikoto.md` にもあるように、CLAUDE.md と AGENTS.md の整合性管理が課題になっている

## Current structure

### my_dotfiles_nvim

```text
my_dotfiles_nvim/
├── environment/          # Docker環境（Dockerfile, docker-compose）
├── nvim/                 # Neovim設定（init.lua, plugins, LSP）
├── scripts/ai-bridge/    # AI Bridge デーモン（Go実装）
├── docs/                 # plan/, log/
├── .github/workflows/    # CI（lint, test, Docker build）
├── .claude/              # Claude Code ローカル設定
└── AGENTS.md
```

### ai-agent-config

```text
ai-agent-config/
├── agents/               # 8個のサブエージェント定義（.md）
├── agents.xml            # マスターエージェント設定（XML）
├── skills/               # 10個のスキル（SKILL.md + 補助ファイル）
├── settings/             # Claude/Cursor 設定・hooks
│   ├── claude/           # settings.json, hooks/
│   └── cursor/           # hooks/
├── scripts/              # copy-entries.sh
├── docs/                 # plan/, log/
├── .github/workflows/    # lint（markdownlint, prettier, shell-lint）
├── .claude/              # agent-memory/
└── Makefile              # 配置自動化（symlink, copy）
```

## Design policy

- **ディレクトリ境界を明確に保つ**: ai-agent-config由来のファイル群は `ai-agents/` サブディレクトリに集約し、既存のNeovim/Docker設定と混在させない
- **グローバル設定としての性質を維持する**: 統合後も `~/.claude/`, `~/.codex/`, `~/.cursor/` への配置（symlink/copy）は Makefile で行う。配置先は変わらない
- **CI/CDを統合する**: lint系ワークフローを1つにまとめ、パスフィルタで対象ディレクトリを分ける
- **docs/ は統合する**: plan/, log/ をリポジトリ全体で共有する
- **git historyを保持する**: `git subtree add` で ai-agent-config の履歴を残す
- **リポジトリ名を `my-pde` に変更する**: PDE（Personal Development Environment）はNeovimコミュニティで定着した用語であり、英語圏でも違和感がない
- **agent-memoryは `.claude/` 配下にマージする**: ai-agent-config の `.claude/agent-memory/` は統合先の `.claude/` に統合する
- **Cursor 用の hooks/settings もリポジトリに含める**: ただし Claude の hooks とは統合しない。`ai-agents/settings/cursor/` として独立して管理する
- **symlink パス変更は Makefile で吸収する**: `agents.xml` → `~/.claude/CLAUDE.md` 等のソースパスが変わるが、Makefile 側の修正のみで対応する

## Implementation steps

1. リポジトリ名を `my-pde` に変更する（GitHub上のrename + ローカルのremote URL更新）
2. ai-agent-config の docs/plan/, docs/log/ の内容を確認し、ファイル名の衝突がないことを確認する
3. `git subtree add --prefix=ai-agents` で ai-agent-config の内容を取り込む
4. `ai-agents/` ディレクトリを作成し、以下を配置する:
   - `agents/`, `agents.xml`
   - `skills/`
   - `settings/`
   - `scripts/copy-entries.sh`
5. ai-agent-config の Makefile をルートの Makefile またはサブディレクトリの Makefile として統合する
6. `.github/workflows/` の lint ワークフローを統合する（markdownlint, prettier, shfmt, shellcheck を1ワークフローに）
7. ai-agent-config の `.claude/agent-memory/` を `.claude/` 配下にマージする
8. `.claude/settings.local.json` の権限設定をマージする
9. AGENTS.md / CLAUDE.md の参照パスを更新する
10. ai-agent-config リポジトリをアーカイブする
11. README.md を更新し、PDE全体の構成を反映する

## File changes

| File | Change |
| --- | --- |
| `ai-agents/` | 新規ディレクトリ。ai-agent-config から agents/, agents.xml, skills/, settings/, scripts/ を移動 |
| `docs/plan/` | ai-agent-config の docs/plan/ 内ファイルをマージ |
| `docs/log/` | ai-agent-config の docs/log/ 内ファイルをマージ |
| `.github/workflows/` | lint ワークフローを統合。パスフィルタ追加 |
| `Makefile`（ルート or `ai-agents/Makefile`） | ai-agent-config の Makefile ターゲットを統合 |
| `.claude/settings.local.json` | 権限設定をマージ |
| `AGENTS.md` | ai-agents/ ディレクトリに関するガイドラインを追加 |
| `README.md` | PDE全体の構成説明を更新 |

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| リポジトリ肥大化により見通しが悪くなる | ディレクトリ境界を明確にし、各サブディレクトリに AGENTS.md を配置して責務を明示する |
| ai-agent-config のグローバル設定変更が Neovim 側 CI を不要に発火させる | GitHub Actions のパスフィルタ（`paths:` / `paths-ignore:`）で対象を限定する |
| git subtree add の履歴がコミットログを汚す | `--squash` オプションで取り込み時のコミットを圧縮し、subtree 内の個別履歴は `git log --follow` で確認可能にする |
| Makefile ターゲットの名前衝突 | ai-agents/ 配下に専用 Makefile を残し、ルート Makefile から委譲する（`make -C ai-agents/ ...`） |
| 他プロジェクトから ai-agent-config を参照している場合の影響 | 統合前に依存関係を確認。Makefile の配置先パスが変わるため、symlink/copy のソースパスを更新する |

## Validation

- [ ] `ai-agents/` 配下にエージェント・スキル・設定が正しく配置されている
- [ ] `make` でスキル・エージェント・設定の配置（`~/.claude/`, `~/.codex/`, `~/.cursor/`）が正常に動作する
- [ ] CI の lint ワークフローが全対象（Markdown, Shell, Go, Lua, Dockerfile）を正しく検出する
- [ ] AI Bridge の既存テスト（`go test`）がパスする
- [ ] Neovim 設定に影響がないことを確認（`nvim --headless` 等）
- [ ] ai-agent-config のシンボリックリンク（`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`）が新パスで動作する
- [ ] `docs/plan/`, `docs/log/` のファイル名が衝突していないことを確認
- [ ] GitHub 上のリポジトリ名が `my-pde` に変更されている
- [ ] `.claude/agent-memory/` が正しくマージされている

## Decisions

- **リポジトリ名**: `my-pde` に変更する
- **git history**: `git subtree add` で保持する
- **agent-memory**: `.claude/` 配下にマージする
- **Cursor settings/hooks**: リポジトリに含める（Claude とは統合しない）
- **symlink パス変更**: Makefile 側で吸収する
