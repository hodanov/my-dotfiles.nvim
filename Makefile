AI_AGENTS_DIR := ai-agents
AI_BRIDGE_DIR := scripts/ai-bridge

# --- AI Bridge (delegate to scripts/ai-bridge/Makefile) ---

AI_BRIDGE_TARGETS := ai-bridge-build ai-bridge-sign ai-bridge-install ai-bridge-test ai-bridge-clean

.PHONY: $(AI_BRIDGE_TARGETS)
$(AI_BRIDGE_TARGETS):
	@$(MAKE) -C $(AI_BRIDGE_DIR) $(patsubst ai-bridge-%,%,$@)

# --- AI Agents (delegate to ai-agents/Makefile) ---

.PHONY: codex-link codex-unlink claude-link claude-unlink cursor-link cursor-unlink gemini-link gemini-unlink
codex-link codex-unlink claude-link claude-unlink cursor-link cursor-unlink gemini-link gemini-unlink:
	@$(MAKE) -C $(AI_AGENTS_DIR) $@

.PHONY: skills-copy codex-skills-copy claude-skills-copy cursor-skills-copy gemini-skills-copy
skills-copy codex-skills-copy claude-skills-copy cursor-skills-copy gemini-skills-copy:
	@$(MAKE) -C $(AI_AGENTS_DIR) $@

.PHONY: agents-copy claude-agents-copy cursor-agents-copy gemini-agents-copy
agents-copy claude-agents-copy cursor-agents-copy gemini-agents-copy:
	@$(MAKE) -C $(AI_AGENTS_DIR) $@

.PHONY: settings-copy claude-settings-copy cursor-settings-copy gemini-settings-copy
settings-copy claude-settings-copy cursor-settings-copy gemini-settings-copy:
	@$(MAKE) -C $(AI_AGENTS_DIR) $@

# --- Dotfiles ---

DOTFILES_DIR := dotfiles

.PHONY: dotfiles-link dotfiles-unlink

dotfiles-link:
	@mkdir -p $(HOME)/.config
	@rm -f $(HOME)/.wezterm.lua
	@ln -sfn $(CURDIR)/$(DOTFILES_DIR)/wezterm $(HOME)/.config/wezterm
	@echo "Linked $(DOTFILES_DIR)/wezterm -> $(HOME)/.config/wezterm"

dotfiles-unlink:
	@rm -f $(HOME)/.config/wezterm
	@echo "Unlinked $(HOME)/.config/wezterm"
