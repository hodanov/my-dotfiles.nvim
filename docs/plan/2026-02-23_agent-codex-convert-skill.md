# Plan

`agents/*.md`（Claude/Cursor 用）から `agents/codex/*.toml`（Codex CLI 用）への
変換を自動化するスキルを作成し、新しいエージェント追加時の手間とミスを減らす。
既存の `blog-idea-draft-export`（SKILL.md + scripts/）パターンに従う。

## Scope

- In:
  - `skills/agent-codex-convert/SKILL.md` の作成
  - `skills/agent-codex-convert/scripts/convert_agent_to_codex.sh` の作成
- Out:
  - 既存の `agents/codex/*.toml` の変更
  - Makefile の変更

## Action items

- [ ] `skills/agent-codex-convert/scripts/convert_agent_to_codex.sh` を作成する
- [ ] `skills/agent-codex-convert/SKILL.md` を作成する
- [ ] `--dry-run` で既存 TOML と diff 比較する
- [ ] `--force` でファイル生成を確認する
- [ ] 2 回目実行で上書き確認プロンプトを確認する

## Open questions

- なし
