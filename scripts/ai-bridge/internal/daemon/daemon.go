package daemon

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"ai-bridge/internal/launcher"
	"ai-bridge/internal/watcher"
)

const defaultBridgeDir = ".ai-bridge"

// Config holds daemon configuration.
type Config struct {
	BridgeDir    string
	CLI          string
	Launcher     string
	PollInterval time.Duration
}

// Request represents a parsed request.json.
type Request struct {
	Prompt    string `json:"prompt"`
	CWD       string `json:"cwd"`
	Timestamp int64  `json:"timestamp"`
}

var (
	cliPattern      = regexp.MustCompile(`^[a-zA-Z][a-zA-Z0-9_./-]*$`)
	launcherPattern = regexp.MustCompile(`^[a-z][a-z0-9_-]*$`)
)

// LoadConfig resolves configuration from environment variables.
func LoadConfig() (*Config, error) {
	home, homeDirErr := os.UserHomeDir()
	if homeDirErr != nil {
		return nil, fmt.Errorf("cannot determine home directory: %w", homeDirErr)
	}

	bridgeDir := os.Getenv("AI_BRIDGE_DIR")
	if bridgeDir == "" {
		bridgeDir = filepath.Join(home, defaultBridgeDir)
	}

	cli := os.Getenv("AI_BRIDGE_CLI")
	if cli == "" {
		cli = "claude"
	}
	if !cliPattern.MatchString(cli) {
		return nil, fmt.Errorf("invalid CLI command name: %s", cli)
	}

	launcherName := os.Getenv("AI_BRIDGE_LAUNCHER")
	if launcherName == "" {
		launcherName = "wezterm"
	}
	if !launcherPattern.MatchString(launcherName) {
		return nil, fmt.Errorf("invalid launcher name: %s (only [a-z0-9_-] allowed)", launcherName)
	}

	return &Config{
		BridgeDir:    bridgeDir,
		CLI:          cli,
		Launcher:     launcherName,
		PollInterval: 1 * time.Second,
	}, nil
}

// parseRequest reads and validates a request JSON file.
func parseRequest(path string) (*Request, error) {
	data, readErr := os.ReadFile(path)
	if readErr != nil {
		return nil, fmt.Errorf("read request: %w", readErr)
	}
	var req Request
	if unmarshalErr := json.Unmarshal(data, &req); unmarshalErr != nil {
		return nil, fmt.Errorf("parse request JSON: %w", unmarshalErr)
	}
	if req.CWD == "" {
		return nil, fmt.Errorf("cwd is null or empty")
	}
	if req.Prompt == "" {
		return nil, fmt.Errorf("prompt is null or empty")
	}
	return &req, nil
}

// generateScript creates a temporary script that runs the AI CLI with the given prompt.
// The script deletes itself after execution.
func generateScript(cli, prompt string) (string, error) {
	f, createTempErr := os.CreateTemp("", "ai-bridge-*.sh")
	if createTempErr != nil {
		return "", fmt.Errorf("create temp script: %w", createTempErr)
	}
	name := f.Name()

	quotedPrompt := shellQuote(prompt)
	quotedPath := shellQuote(name)
	content := fmt.Sprintf("#!/bin/bash\n%s %s\nrm -f %s\n", cli, quotedPrompt, quotedPath)
	if _, writeErr := f.WriteString(content); writeErr != nil {
		_ = f.Close()
		_ = os.Remove(name)
		return "", fmt.Errorf("write temp script: %w", writeErr)
	}

	if chmodErr := f.Chmod(0o755); chmodErr != nil {
		_ = f.Close()
		_ = os.Remove(name)
		return "", fmt.Errorf("chmod temp script: %w", chmodErr)
	}

	if closeErr := f.Close(); closeErr != nil {
		_ = os.Remove(name)
		return "", fmt.Errorf("close temp script: %w", closeErr)
	}

	return name, nil
}

// shellQuote returns a POSIX shell-safe single-quoted string.
func shellQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", "'\"'\"'") + "'"
}

// Run starts the daemon main loop. It blocks until ctx is cancelled.
func Run(ctx context.Context, cfg *Config, l launcher.Launcher) error {
	if mkdirErr := os.MkdirAll(cfg.BridgeDir, 0o755); mkdirErr != nil {
		return fmt.Errorf("create bridge dir: %w", mkdirErr)
	}

	slog.Info("ai-bridge-daemon: started",
		"cli", cfg.CLI,
		"launcher", cfg.Launcher,
		"watching", filepath.Join(cfg.BridgeDir, "request.json"),
	)

	interval := cfg.PollInterval
	if interval == 0 {
		interval = 1 * time.Second
	}

	w := watcher.New(cfg.BridgeDir, interval)
	ch := w.Watch(ctx)

	for consumedPath := range ch {
		if processErr := processRequest(consumedPath, cfg.CLI, l); processErr != nil {
			slog.Warn("request failed", "error", processErr)
		}
	}

	return nil
}

func processRequest(consumedPath, cli string, l launcher.Launcher) error {
	req, parseErr := parseRequest(consumedPath)
	_ = os.Remove(consumedPath)
	if parseErr != nil {
		return fmt.Errorf("invalid request: %w", parseErr)
	}

	info, statErr := os.Stat(req.CWD)
	if statErr != nil || !info.IsDir() {
		return fmt.Errorf("cwd is not a valid directory: %s", req.CWD)
	}

	scriptPath, genScriptErr := generateScript(cli, req.Prompt)
	if genScriptErr != nil {
		return fmt.Errorf("generate script: %w", genScriptErr)
	}

	slog.Info("ai-bridge-daemon: launching", "cwd", req.CWD)
	if launchErr := l.Launch(req.CWD, scriptPath); launchErr != nil {
		_ = os.Remove(scriptPath)
		return fmt.Errorf("launcher failed: %w", launchErr)
	}

	return nil
}
