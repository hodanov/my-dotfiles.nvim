[![English](https://img.shields.io/badge/lang-English-blue)](README.md) [![日本語](https://img.shields.io/badge/lang-日本語-orange)](README.ja.md)

# ai-agent-config

これはCodex CLIのAGENTS.mdファイルを管理するリポジトリで、Claude Code用のCLAUDE.mdにも対応。

## 構成

- agents.xml: AGENTS.mdとCLAUDE.mdの実態。`~/.codex/AGENTS.md`または`~/.claude/CLAUDE.md`のシンボリックリンク。
- agents/: サブエージェント定義（Claude/Cursor用Markdown、Codex CLI用TOML）。
- Makefile: シンボリックリンクの作成と削除を簡単に実行するためのコマンドを実装。
- skills/: Codex CLI、Claude Code、Cursorで共通利用するSkills。

## 使い方

`~/.codex/AGENTS.md`のシンボリックリンクをagents.xmlに貼る。

```sh
cd ai-agent-config
make codex-link
```

シンボリックリンクを解除したい場合は下記のコマンドを実行する。

```sh
make codex-unlink
```

`~/.claude/CLAUDE.md`のシンボリックリンクをagents.xmlに貼る。

```sh
cd ai-agent-config
make claude-link
```

シンボリックリンクを解除したい場合は下記のコマンドを実行する。

```sh
make claude-unlink
```

コピーでユーザーレベルに配置する。

```sh
make skills-copy
```

ツール別:

```sh
make codex-skills-copy
make claude-skills-copy
make cursor-skills-copy
```

互換用（Codexのみコピー）:

```sh
make codex-skills-install
```

エージェントをユーザーレベルディレクトリにコピーする:

```sh
make agents-copy
```

ツール別:

```sh
make codex-agents-copy
make claude-agents-copy
make cursor-agents-copy
```

Codex CLI の場合、`agents-copy` は `~/.codex/config.toml` への `[agents.*]` エントリ登録も行う。

## AGENTS.mdの中身をxmlとして定義する理由

[GPT-5 for Coding Cheatsheet(PDF)](https://cdn.openai.com/API/docs/gpt-5-for-coding-cheatsheet.pdf)によると、XMLライクなタグでセクションを区切る書き方が推奨されているから。

上記OpenAIのチートシートで“XML-like syntax to help structure instructions”とはっきり書かれており、実例が掲載されている。

このリポジトリにあるagents.xmlの内容は、このチートシートを参考に作成した。

## 参考URL

- [GPT-5 for Coding Cheatsheet(PDF)](https://cdn.openai.com/API/docs/gpt-5-for-coding-cheatsheet.pdf)
- [GPT-5 prompting guide](https://cookbook.openai.com/examples/gpt-5/gpt-5_prompting_guide)
