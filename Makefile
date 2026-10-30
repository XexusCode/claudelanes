VERSION ?= 0.1.1

.PHONY: build test app install zip clean

build:
	swift build

test:
	swift test

app:
	VERSION=$(VERSION) ./scripts/build-app.sh

install: app
	@if pgrep -xq ClaudeLanes; then osascript -e 'tell application id "io.github.xexuscode.claudelanes" to quit' || true; sleep 1; fi
	rm -rf /Applications/ClaudeLanes.app
	cp -R dist/ClaudeLanes.app /Applications/ClaudeLanes.app
	@echo "Installed /Applications/ClaudeLanes.app"

zip: app
	cd dist && rm -f ClaudeLanes-$(VERSION).zip && ditto -c -k --keepParent ClaudeLanes.app ClaudeLanes-$(VERSION).zip
	@echo "dist/ClaudeLanes-$(VERSION).zip"

clean:
	rm -rf .build dist
