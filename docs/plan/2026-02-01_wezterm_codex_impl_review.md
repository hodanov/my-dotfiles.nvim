# Plan

We will implement an "implement -> review" workflow using WezTerm (no tmux) and two Codex sessions (same model/settings), with automation for pane layout and prompt routing. The plan focuses on WezTerm CLI automation plus Codex skills stored globally under `~/.codex/skills`.

## Scope

- In: WezTerm automated layout, pane selection, Codex skill separation (implement/review), same model/config for both sessions.
- Out: tmux setup, other AI providers, human review automation.

## Action items

- [ ] Confirm WezTerm CLI availability and output format from `wezterm cli list`, and decide the target selector strategy (pane-id vs. title/class).
- [ ] Define a WezTerm automation approach (script or WezTerm config) to spawn a window with two panes and start Codex in each.
- [ ] Create global Codex skills under `~/.codex/skills` for implement and review roles, with consistent prompt templates and boundaries.
- [ ] Create a sender helper (skill or script) that resolves the review pane and sends the review prompt via `wezterm cli send-text`.
- [ ] Run a dry-run workflow: implement -> self-check -> send to review pane -> receive feedback -> apply -> re-review.
- [ ] Add a quick validation checklist for routing correctness and multi-window safety (wrong pane, stale pane-id, multiple instances).

## Open questions

- None
