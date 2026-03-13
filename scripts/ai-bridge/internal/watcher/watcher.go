package watcher

import (
	"context"
	"fmt"
	"log/slog"
	"math/rand"
	"os"
	"path/filepath"
	"time"
)

// Watcher polls a directory for request.json and atomically consumes it.
type Watcher struct {
	dir      string
	interval time.Duration
}

// New creates a Watcher that polls dir for "request.json" at the given interval.
func New(dir string, interval time.Duration) *Watcher {
	return &Watcher{dir: dir, interval: interval}
}

// Watch polls for request.json. When found, it atomically renames the file
// and sends the consumed path on the returned channel. The channel is closed
// when ctx is cancelled.
func (w *Watcher) Watch(ctx context.Context) <-chan string {
	ch := make(chan string)
	go func() {
		defer close(ch)
		ticker := time.NewTicker(w.interval)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				consumed, ok := w.tryConsume()
				if !ok {
					continue
				}
				select {
				case ch <- consumed:
				case <-ctx.Done():
					return
				}
			}
		}
	}()
	return ch
}

// tryConsume checks for request.json and atomically renames it.
// Returns the consumed path and true on success.
func (w *Watcher) tryConsume() (string, bool) {
	path := filepath.Join(w.dir, "request.json")
	if _, statErr := os.Stat(path); statErr != nil {
		return "", false
	}
	consumed := fmt.Sprintf("%s.%d.%d.consumed", path, time.Now().Unix(), rand.Intn(100000))
	if renameErr := os.Rename(path, consumed); renameErr != nil {
		slog.Debug("consume failed (likely race)", "error", renameErr)
		return "", false
	}
	return consumed, true
}
