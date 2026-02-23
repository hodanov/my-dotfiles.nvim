# Log

2026-02-23: 調査用サブエージェントのレビュー・修正、agents-copy make ターゲットの実装、agent-codex-convert スキルの作成。

## Summary

- investigation-scout / investigation-diver サブエージェントのレビューと修正
- `make agents-copy` ターゲットの実装（Claude/Cursor/Codex CLI 対応）
- Codex CLI 用 TOML エージェントファイルの作成
- `agent-codex-convert` スキルの作成（MD → TOML 自動変換）

## Details

### サブエージェントレビュー・修正

- 公式ドキュメントとプランを照らし合わせてレビュー実施
- 修正 4 点:
  - `investigation-scout.md`: model を opus → sonnet に変更
  - `investigation-scout.md`: `permissionMode: plan` を追加
  - `investigation-diver.md`: `permissionMode: plan` を追加
  - `investigation-diver.md`: `memory: project` を追加
- PR #11 としてドラフト PR 作成済み

### agents-copy make ターゲット

- Makefile に 4 つの新規ターゲットを追加:
  - `agents-copy`: 全ツール一括コピー
  - `claude-agents-copy`: `~/.claude/agents/` に .md コピー
  - `cursor-agents-copy`: `~/.cursor/agents/` に .md コピー
  - `codex-agents-copy`: `~/.codex/agents/` に .toml コピー + `config.toml` 登録
- `copy_agents_md` define を作成（`copy_skills` と同じ重複チェック・上書き確認パターン）
- Codex 用は TOML コピー + `config.toml` の `[agents.*]` セクション追記を実装
- README.md / README.ja.md にドキュメント追加

### Codex CLI 用 TOML ファイル

- `agents/codex/investigation-scout.toml` を作成
- `agents/codex/investigation-diver.toml` を作成
- 変換ルール:
  - model: sonnet → `gpt-5.3-codex`
  - permissionMode: plan → `sandbox_mode = "read-only"`
  - tools → `## Constraints` セクションとして body に注入
  - memory → Codex 非対応のためプロンプトから削除 + コメントで注記

### agent-codex-convert スキル

- `skills/agent-codex-convert/SKILL.md` を作成（`disable-model-invocation: true`）
- `skills/agent-codex-convert/scripts/convert_agent_to_codex.sh` を作成
- スクリプト機能:
  - YAML frontmatter 解析 → TOML 自動生成
  - `--dry-run`, `--force`, `--reasoning-effort`, `--output-dir` オプション
  - memory フィールド検出時の WARNING 出力（手動レビュー前提）
  - エラーハンドリング（不正入力、重複ファイル、frontmatter 欠落）
- 既存 TOML との diff 比較で動作確認済み

### 作成したプラン文書

- `docs/plan/2026-02-23_agents-copy-make-targets.md`
- `docs/plan/2026-02-23_agent-codex-convert-skill.md`
