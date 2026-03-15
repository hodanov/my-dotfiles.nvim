BINARY := ai-bridge
CMD    := ./cmd/ai-bridge

.PHONY: build sign install clean test

build:
	go build -o $(BINARY) $(CMD)

sign: build
	codesign --sign - --force $(BINARY)

install: sign
	./$(BINARY) install-launchd

test:
	go test ./...

clean:
	rm -f $(BINARY) coverage.out
