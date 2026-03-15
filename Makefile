AI_AGENTS_DIR := ai-agents

# --- AI Agents (delegate to ai-agents/Makefile) ---

.PHONY: codex-link codex-unlink claude-link claude-unlink
codex-link codex-unlink claude-link claude-unlink:
	@$(MAKE) -C $(AI_AGENTS_DIR) $@

.PHONY: skills-copy codex-skills-copy claude-skills-copy cursor-skills-copy
skills-copy codex-skills-copy claude-skills-copy cursor-skills-copy:
	@$(MAKE) -C $(AI_AGENTS_DIR) $@

.PHONY: agents-copy claude-agents-copy cursor-agents-copy
agents-copy claude-agents-copy cursor-agents-copy:
	@$(MAKE) -C $(AI_AGENTS_DIR) $@

.PHONY: settings-copy claude-settings-copy cursor-settings-copy
settings-copy claude-settings-copy cursor-settings-copy:
	@$(MAKE) -C $(AI_AGENTS_DIR) $@
