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
