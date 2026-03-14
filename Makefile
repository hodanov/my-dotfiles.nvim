AGENTS_SRC := $(PWD)/agents.xml
AGENTS_DEST := $(HOME)/.codex/AGENTS.md
AGENTS_DEST_FOR_CLAUDE := $(HOME)/.claude/CLAUDE.md

SKILLS_SRC := $(PWD)/skills
CODEX_SKILLS_DEST := $(HOME)/.codex/skills
CLAUDE_SKILLS_DEST := $(HOME)/.claude/skills
CURSOR_SKILLS_DEST := $(HOME)/.cursor/skills

AGENTS_MD_SRC := $(PWD)/agents
CLAUDE_AGENTS_DEST := $(HOME)/.claude/agents
CURSOR_AGENTS_DEST := $(HOME)/.cursor/agents

SETTINGS_SRC := $(PWD)/settings
CLAUDE_SETTINGS_DEST := $(HOME)/.claude
CURSOR_SETTINGS_DEST := $(HOME)/.cursor

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

define copy_skills
	@set -eu; \
	src="$(SKILLS_SRC)"; \
	dest="$(1)"; \
	if [ ! -d "$$src" ]; then \
		echo "Source skills directory not found: $$src"; \
		exit 1; \
	fi; \
	if [ -L "$$dest" ]; then \
		echo "Destination is a symlink. Remove it before copying: $$dest"; \
		exit 1; \
	fi; \
	mkdir -p "$$dest"; \
	tmp=$$(mktemp); \
	trap 'rm -f "$$tmp"' EXIT; \
	find "$$src" -mindepth 1 -maxdepth 1 -type d -print0 > "$$tmp"; \
	if [ ! -s "$$tmp" ]; then \
		echo "No skills found in $$src"; \
		exit 0; \
	fi; \
	dup_found=0; \
	dup_list=""; \
	while IFS= read -r -d '' dir; do \
		base=$$(basename "$$dir"); \
		if [ -e "$$dest/$$base" ]; then \
			dup_found=1; \
			dup_list="$$dup_list$$base\n"; \
		fi; \
	done < "$$tmp"; \
	overwrite=0; \
	if [ "$$dup_found" -eq 1 ]; then \
		echo "The following skills already exist in $$dest:"; \
		printf "%b" "$$dup_list"; \
		printf "Overwrite existing skills? [y/N] "; \
		read -r ans; \
		case "$$ans" in \
			y|Y) overwrite=1 ;; \
			*) overwrite=0 ;; \
		esac; \
	fi; \
	while IFS= read -r -d '' dir; do \
		base=$$(basename "$$dir"); \
		dest_dir="$$dest/$$base"; \
		if [ -e "$$dest_dir" ] && [ "$$overwrite" -ne 1 ]; then \
			echo "Skip $$base (already exists)"; \
			continue; \
		fi; \
		rm -rf "$$dest_dir"; \
		cp -R "$$dir" "$$dest_dir"; \
		echo "Installed $$base"; \
	done < "$$tmp"; \
	echo "Done."
endef

.PHONY: skills-copy
skills-copy: codex-skills-copy claude-skills-copy cursor-skills-copy

.PHONY: codex-skills-copy
codex-skills-copy:
	$(call copy_skills,$(CODEX_SKILLS_DEST))

.PHONY: codex-skills-install
codex-skills-install: codex-skills-copy

.PHONY: claude-skills-copy
claude-skills-copy:
	$(call copy_skills,$(CLAUDE_SKILLS_DEST))

.PHONY: cursor-skills-copy
cursor-skills-copy:
	$(call copy_skills,$(CURSOR_SKILLS_DEST))

define copy_agents_md
	@set -eu; \
	src="$(AGENTS_MD_SRC)"; \
	dest="$(1)"; \
	if [ ! -d "$$src" ]; then \
		echo "Source agents directory not found: $$src"; \
		exit 1; \
	fi; \
	if [ -L "$$dest" ]; then \
		echo "Destination is a symlink. Remove it before copying: $$dest"; \
		exit 1; \
	fi; \
	mkdir -p "$$dest"; \
	tmp=$$(mktemp); \
	trap 'rm -f "$$tmp"' EXIT; \
	find "$$src" -maxdepth 1 -name '*.md' -type f -print0 > "$$tmp"; \
	if [ ! -s "$$tmp" ]; then \
		echo "No agent .md files found in $$src"; \
		exit 0; \
	fi; \
	dup_found=0; \
	dup_list=""; \
	while IFS= read -r -d '' f; do \
		base=$$(basename "$$f"); \
		if [ -e "$$dest/$$base" ]; then \
			dup_found=1; \
			dup_list="$$dup_list$$base\n"; \
		fi; \
	done < "$$tmp"; \
	overwrite=0; \
	if [ "$$dup_found" -eq 1 ]; then \
		echo "The following agents already exist in $$dest:"; \
		printf "%b" "$$dup_list"; \
		printf "Overwrite existing agents? [y/N] "; \
		read -r ans; \
		case "$$ans" in \
			y|Y) overwrite=1 ;; \
			*) overwrite=0 ;; \
		esac; \
	fi; \
	while IFS= read -r -d '' f; do \
		base=$$(basename "$$f"); \
		if [ -e "$$dest/$$base" ] && [ "$$overwrite" -ne 1 ]; then \
			echo "Skip $$base (already exists)"; \
			continue; \
		fi; \
		cp "$$f" "$$dest/$$base"; \
		echo "Installed $$base"; \
	done < "$$tmp"; \
	echo "Done."
endef

.PHONY: agents-copy
agents-copy: claude-agents-copy cursor-agents-copy

.PHONY: claude-agents-copy
claude-agents-copy:
	$(call copy_agents_md,$(CLAUDE_AGENTS_DEST))

.PHONY: cursor-agents-copy
cursor-agents-copy:
	$(call copy_agents_md,$(CURSOR_AGENTS_DEST))

define copy_settings
	@set -eu; \
	src="$(SETTINGS_SRC)/$(1)"; \
	dest="$(2)"; \
	if [ ! -d "$$src" ]; then \
		echo "Source settings directory not found: $$src"; \
		exit 1; \
	fi; \
	tmp=$$(mktemp); \
	trap 'rm -f "$$tmp"' EXIT; \
	find "$$src" -type f -print0 > "$$tmp"; \
	if [ ! -s "$$tmp" ]; then \
		echo "No settings files found in $$src"; \
		exit 0; \
	fi; \
	dup_found=0; \
	dup_list=""; \
	while IFS= read -r -d '' f; do \
		rel=$${f#$$src/}; \
		if [ -e "$$dest/$$rel" ]; then \
			dup_found=1; \
			dup_list="$$dup_list$$rel\n"; \
		fi; \
	done < "$$tmp"; \
	overwrite=0; \
	if [ "$$dup_found" -eq 1 ]; then \
		echo "The following settings already exist in $$dest:"; \
		printf "%b" "$$dup_list"; \
		printf "Overwrite existing settings? [y/N] "; \
		read -r ans; \
		case "$$ans" in \
			y|Y) overwrite=1 ;; \
			*) overwrite=0 ;; \
		esac; \
	fi; \
	while IFS= read -r -d '' f; do \
		rel=$${f#$$src/}; \
		dest_file="$$dest/$$rel"; \
		if [ -e "$$dest_file" ] && [ "$$overwrite" -ne 1 ]; then \
			echo "Skip $$rel (already exists)"; \
			continue; \
		fi; \
		mkdir -p "$$(dirname "$$dest_file")"; \
		cp -p "$$f" "$$dest_file"; \
		echo "Installed $$rel"; \
	done < "$$tmp"; \
	echo "Done."
endef

.PHONY: settings-copy
settings-copy: claude-settings-copy cursor-settings-copy

.PHONY: claude-settings-copy
claude-settings-copy:
	$(call copy_settings,claude,$(CLAUDE_SETTINGS_DEST))

.PHONY: cursor-settings-copy
cursor-settings-copy:
	$(call copy_settings,cursor,$(CURSOR_SETTINGS_DEST))
