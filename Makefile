VERSION ?= 0.1.0

.PHONY: build test app install zip clean

build:
	swift build

test:
	swift test

app:
	VERSION=$(VERSION) ./scripts/build-app.sh

install: app
	@if pgrep -xq Lanes; then osascript -e 'tell application id "io.github.xexuscode.lanes" to quit' || true; sleep 1; fi
	rm -rf /Applications/Lanes.app
	cp -R dist/Lanes.app /Applications/Lanes.app
	@echo "Installed /Applications/Lanes.app"

zip: app
	cd dist && rm -f Lanes-$(VERSION).zip && ditto -c -k --keepParent Lanes.app Lanes-$(VERSION).zip
	@echo "dist/Lanes-$(VERSION).zip"

clean:
	rm -rf .build dist
