# Code Review Memory

## Project Conventions

- **Agent frontmatter fields**: `name`, `description`, `tools`, `model`, `permissionMode`, `maxTurns`, `color`, `memory` (Claude Code extensions, not Agent Skills spec)
- **Skill frontmatter fields**: `name`, `description` are standard. `disable-model-invocation` and `argument-hint` are Claude Code extensions (not in agentskills.io spec)
- **Severity terminology is split across two systems**:
  - Subagent Findings Reports (review-security/performance/correctness/changeability): `[Critical]`, `[Warning]`, `[Info]`
  - code-review-scanner Scan Reports: `High`, `Medium`, `Low` (priority, not severity)
  - code-review-critic Review Reports: `[High]`, `[Medium]` (priority categories)
  - These are different taxonomies: subagents use severity; scanner/critic use priority
- **Language**: Agent definitions are in English with Japanese section headers; skill files are primarily in Japanese
- **Review pipeline**: Two parallel systems exist:
  1. `/review` skill (Phase.1 scan via 4 subagents) -> `code-review-critic` (Phase.2)
  2. `code-review-scanner` (Phase.1 scan) -> `code-review-critic` (Phase.2)

## Common Patterns

- Skills use `disable-model-invocation: true` for user-invoked skills that should NOT be auto-loaded by Claude (e.g., resource-heavy orchestration)
- `disable-model-invocation: true` means "prevent auto-loading"; it does NOT prevent model reasoning during execution
- Subagents share identical output format structure (Findings Report with Summary + Findings list + No-issues section)
- All review subagents use `model: sonnet`, `permissionMode: plan`, `maxTurns: 15`
- No skills in this project use `allowed-tools`; skills inherit tool access from the host agent
- `tools:` is the correct field for agent definitions; `allowed-tools:` is for skill definitions (different schemas)
- Color convention: yellow = code-review agents, cyan = investigation agents, magenta = review subagents

## Skill Improve System Conventions

- `observations/` layout: obs files at `YYYY-MM-DD_obs.md` (top-level), amendment files under `observations/amendments/YYYY-MM-DD_amendment.md`
- `observations/*.md` glob in individual-skill mode correctly excludes `amendments/` subdir (single-level glob)
- `all` mode walk instruction has no glob — LLM may read amendment files as obs files; this is the known ambiguity
- 12 skills exist under `ai-agents/skills/`; only `review/observations/.gitkeep` exists (no actual obs files yet as of 2026-03-21)

## WezTerm Config Conventions

- Config split into 4 modules: `wezterm.lua` (entry), `appearance.lua`, `keybindings.lua`, `workspaces.lua`
- Each module exports `function(config)` pattern; entry point calls them sequentially
- `wezterm.GLOBAL` used for cross-reload persistent state (survives config reloads)
- `wezterm.mux.get_workspace_names()` always returns a Lua table (never nil); at least one workspace always exists

## Past Reviews

### 2026-03-01: 4 review subagent definitions (review-security/performance/correctness/changeability)

- Step 1 wording "Read the changed files" is misleading; diff is passed as input text via SKILL.md Agent tool prompt
- `[Info]` template missing `根拠` field contradicts "根拠必須" rule -- minor template inconsistency
- Description language in Japanese (all other agents use English) -- inconsistency but no functional impact since agents are explicitly invoked
- `color: magenta` same for all 4 is correct (same-role convention, not a problem)
- `maxTurns: 15`, `model: sonnet`, no `改善案` -- all correct by design
- Domain-specific 5th rules are well-calibrated per specialty
- Scanner false positives: Bash absence, color sameness, `改善案` absence all valid by design

### 2026-03-01: skills/review/SKILL.md (re-review after fixes)

- `disable-model-invocation: true` was incorrectly removed after prior review's wrong interpretation; should be restored
- Severity terminology now correctly aligned: SKILL.md says "Critical/Warning" matching subagent output
- Phase.2 handoff still lacks concrete invocation instructions for `code-review-critic`
- Scanner false positives: `tools:` in agent files is correct (not `allowed-tools:`); `permissionMode` in Notes is prose not frontmatter
- Three-dot diff `main...<branch>` is correct for branch review (shows changes from merge base)

### 2026-03-01: skills/review/SKILL.md (new file) - initial review

- Severity terminology mismatch: subagents output `Critical/Warning/Info` but SKILL.md Step 3 references `Critical/High` -- FIXED in re-review
- `disable-model-invocation: true` incorrectly flagged as conflicting with summary generation -- was wrong interpretation
- Phase.2 handoff mechanism ambiguous -- still valid in re-review

### 2026-03-21: skill-improve/SKILL.md + skill-observe/SKILL.md (new files)

- Core issue: Step 2 asymmetry — individual mode uses `observations/*.md` (glob, excludes amendments/), `all` mode says "走査" with no glob — LLM may read amendment files as obs files
- Step 4 correctly targets `observations/amendments/` separately — the intent to separate the two is clear but `all` mode doesn't enforce it
- `observations/*.md` single-level glob is technically correct and safe for individual mode; the problem is only in `all` mode prose
- Fix: add `observations/*_obs.md` or explicit "amendments/ を除外" instruction to `all` mode description in Step 2

### 2026-04-04: dotfiles/wezterm/keybindings.lua (fuzzy workspace selector)

- Phase.1 Critical (`get_workspace_names()` nil/empty risk) was FALSE POSITIVE -- API always returns table, never nil
- Real issue found: `prompt_new_workspace` allows empty-string workspace creation (`if line then` is truthy for `""` in Lua) -- pre-existing bug, not introduced by this diff
- `local next` shadows Lua built-in -- no functional impact in this scope but style concern
- Overall: clean refactoring, good separation of concerns, standard WezTerm patterns
