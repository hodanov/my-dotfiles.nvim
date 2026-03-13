package watcher

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestWatch_ConsumesRequest(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	w := New(dir, 50*time.Millisecond)

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	ch := w.Watch(ctx)

	// Write a request file.
	reqPath := filepath.Join(dir, "request.json")
	if err := os.WriteFile(reqPath, []byte(`{"prompt":"hi"}`), 0o644); err != nil {
		t.Fatal(err)
	}

	select {
	case consumed := <-ch:
		if consumed == "" {
			t.Fatal("consumed path is empty")
		}
		// The original file should no longer exist.
		if _, err := os.Stat(reqPath); !os.IsNotExist(err) {
			t.Error("request.json should be renamed after consume")
		}
		// The consumed file should exist.
		if _, err := os.Stat(consumed); err != nil {
			t.Errorf("consumed file should exist: %v", err)
		}
		// Clean up consumed file.
		_ = os.Remove(consumed)
	case <-ctx.Done():
		t.Fatal("timed out waiting for consumed request")
	}
}

func TestWatch_NoDuplicateConsume(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	w := New(dir, 50*time.Millisecond)

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	ch := w.Watch(ctx)

	// Write one request file.
	reqPath := filepath.Join(dir, "request.json")
	if err := os.WriteFile(reqPath, []byte(`{"prompt":"once"}`), 0o644); err != nil {
		t.Fatal(err)
	}

	// Collect all consumed events.
	var consumed []string
	done := make(chan struct{})
	go func() {
		for path := range ch {
			consumed = append(consumed, path)
			_ = os.Remove(path)
		}
		close(done)
	}()

	<-done

	if len(consumed) != 1 {
		t.Errorf("expected exactly 1 consume event, got %d", len(consumed))
	}
}

func TestWatch_StopsOnCancel(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	w := New(dir, 50*time.Millisecond)

	ctx, cancel := context.WithCancel(context.Background())
	ch := w.Watch(ctx)

	cancel()

	// Channel should be closed after cancel.
	for range ch {
		// drain
	}
}

func TestWatch_CancelDuringBlockedSend(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	w := New(dir, 50*time.Millisecond)

	ctx, cancel := context.WithCancel(context.Background())
	ch := w.Watch(ctx)

	// Write a request so the watcher consumes it and tries to send on ch.
	if writeErr := os.WriteFile(filepath.Join(dir, "request.json"), []byte(`{}`), 0o644); writeErr != nil {
		t.Fatal(writeErr)
	}

	// Wait for watcher to detect, consume, and block on unbuffered ch send.
	time.Sleep(200 * time.Millisecond)

	// Cancel while send is blocked — should take the inner ctx.Done() path.
	cancel()

	// Channel should be closed.
	for range ch {
	}
}

func TestWatch_NoFileNoPanic(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	w := New(dir, 50*time.Millisecond)

	ctx, cancel := context.WithTimeout(context.Background(), 300*time.Millisecond)
	defer cancel()

	ch := w.Watch(ctx)

	// No file written — should just close without events.
	for range ch {
		t.Error("unexpected event when no file exists")
	}
}
