AGENTS_SRC := $(CURDIR)/agents.xml
AGENTS_DEST := $(HOME)/.codex/AGENTS.md
AGENTS_DEST_FOR_CLAUDE := $(HOME)/.claude/CLAUDE.md
AGENTS_DEST_FOR_CURSOR := $(HOME)/.cursor/AGENTS.md
AGENTS_DEST_FOR_COPILOT := $(HOME)/.copilot/copilot-instructions.md

SKILLS_SRC := $(CURDIR)/skills
CODEX_SKILLS_DEST := $(HOME)/.codex/skills
CLAUDE_SKILLS_DEST := $(HOME)/.claude/skills
CURSOR_SKILLS_DEST := $(HOME)/.cursor/skills
COPILOT_SKILLS_DEST := $(HOME)/.copilot/skills

AGENTS_MD_SRC := $(CURDIR)/agents
CLAUDE_AGENTS_DEST := $(HOME)/.claude/agents
CURSOR_AGENTS_DEST := $(HOME)/.cursor/agents
COPILOT_AGENTS_DEST := $(HOME)/.copilot/agents

SETTINGS_SRC := $(CURDIR)/settings
CLAUDE_SETTINGS_DEST := $(HOME)/.claude
CURSOR_SETTINGS_DEST := $(HOME)/.cursor
COPILOT_HOOKS_DEST := $(HOME)/.copilot/hooks

COPY_ENTRIES := $(CURDIR)/scripts/copy-entries.sh

.PHONY: codex-link
codex-link:
	@ln -sf "$(AGENTS_SRC)" "$(AGENTS_DEST)"
	@echo "Linked $(AGENTS_DEST) -> $(AGENTS_SRC)"

.PHONY: codex-unlink
codex-unlink:
	@if [ -L "$(AGENTS_DEST)" ]; then \
		rm -f "$(AGENTS_DEST)"; \
		echo "Removed symlink $(AGENTS_DEST)"; \
	else \
		echo "$(AGENTS_DEST) is not a symlink or does not exist."; \
	fi

.PHONY: claude-link
claude-link:
	@ln -sf "$(AGENTS_SRC)" "$(AGENTS_DEST_FOR_CLAUDE)"
	@echo "Linked $(AGENTS_DEST_FOR_CLAUDE) -> $(AGENTS_SRC)"

.PHONY: claude-unlink
claude-unlink:
	@if [ -L "$(AGENTS_DEST_FOR_CLAUDE)" ]; then \
		rm -f "$(AGENTS_DEST_FOR_CLAUDE)"; \
		echo "Removed symlink $(AGENTS_DEST_FOR_CLAUDE)"; \
	else \
		echo "$(AGENTS_DEST_FOR_CLAUDE) is not a symlink or does not exist."; \
	fi

.PHONY: cursor-link
cursor-link:
	@ln -sf "$(AGENTS_SRC)" "$(AGENTS_DEST_FOR_CURSOR)"
	@echo "Linked $(AGENTS_DEST_FOR_CURSOR) -> $(AGENTS_SRC)"

.PHONY: cursor-unlink
cursor-unlink:
	@if [ -L "$(AGENTS_DEST_FOR_CURSOR)" ]; then \
		rm -f "$(AGENTS_DEST_FOR_CURSOR)"; \
		echo "Removed symlink $(AGENTS_DEST_FOR_CURSOR)"; \
	else \
		echo "$(AGENTS_DEST_FOR_CURSOR) is not a symlink or does not exist."; \
	fi

.PHONY: copilot-link
copilot-link:
	@ln -sf "$(AGENTS_SRC)" "$(AGENTS_DEST_FOR_COPILOT)"
	@echo "Linked $(AGENTS_DEST_FOR_COPILOT) -> $(AGENTS_SRC)"

.PHONY: copilot-unlink
copilot-unlink:
	@if [ -L "$(AGENTS_DEST_FOR_COPILOT)" ]; then \
		rm -f "$(AGENTS_DEST_FOR_COPILOT)"; \
		echo "Removed symlink $(AGENTS_DEST_FOR_COPILOT)"; \
	else \
		echo "$(AGENTS_DEST_FOR_COPILOT) is not a symlink or does not exist."; \
	fi

.PHONY: skills-copy
skills-copy: codex-skills-copy claude-skills-copy cursor-skills-copy copilot-skills-copy

.PHONY: codex-skills-copy
codex-skills-copy:
	@"$(COPY_ENTRIES)" skills "$(SKILLS_SRC)" "$(CODEX_SKILLS_DEST)"

.PHONY: claude-skills-copy
claude-skills-copy:
	@"$(COPY_ENTRIES)" skills "$(SKILLS_SRC)" "$(CLAUDE_SKILLS_DEST)"

.PHONY: cursor-skills-copy
cursor-skills-copy:
	@"$(COPY_ENTRIES)" skills "$(SKILLS_SRC)" "$(CURSOR_SKILLS_DEST)"

.PHONY: copilot-skills-copy
copilot-skills-copy:
	@"$(COPY_ENTRIES)" skills "$(SKILLS_SRC)" "$(COPILOT_SKILLS_DEST)"

.PHONY: agents-copy
agents-copy: claude-agents-copy cursor-agents-copy copilot-agents-copy

.PHONY: claude-agents-copy
claude-agents-copy:
	@"$(COPY_ENTRIES)" agents "$(AGENTS_MD_SRC)" "$(CLAUDE_AGENTS_DEST)"

.PHONY: cursor-agents-copy
cursor-agents-copy:
	@"$(COPY_ENTRIES)" agents "$(AGENTS_MD_SRC)" "$(CURSOR_AGENTS_DEST)"

.PHONY: copilot-agents-copy
copilot-agents-copy:
	@"$(COPY_ENTRIES)" agents "$(AGENTS_MD_SRC)" "$(COPILOT_AGENTS_DEST)"

.PHONY: settings-copy
settings-copy: claude-settings-copy cursor-settings-copy copilot-hooks-copy

.PHONY: claude-settings-copy
claude-settings-copy:
	@"$(COPY_ENTRIES)" settings "$(SETTINGS_SRC)/claude" "$(CLAUDE_SETTINGS_DEST)"

.PHONY: cursor-settings-copy
cursor-settings-copy:
	@"$(COPY_ENTRIES)" settings "$(SETTINGS_SRC)/cursor" "$(CURSOR_SETTINGS_DEST)"

.PHONY: copilot-hooks-copy
copilot-hooks-copy:
	@"$(COPY_ENTRIES)" settings "$(SETTINGS_SRC)/copilot/hooks" "$(COPILOT_HOOKS_DEST)"
