package launcher

// WezTerm launches a script in a new WezTerm tab.
type WezTerm struct {
	run CommandRunner
}

// args returns the command-line arguments for wezterm cli spawn.
func (w *WezTerm) args(cwd, scriptPath string) []string {
	return []string{"cli", "spawn", "--cwd", cwd, "--", "bash", "-l", scriptPath}
}

// Launch opens a new WezTerm tab and runs the script.
func (w *WezTerm) Launch(cwd, scriptPath string) error {
	return w.run("wezterm", w.args(cwd, scriptPath)...)
}
