PROJECT   := Ubiquiti\ Assignment.xcodeproj
SCHEME    := Ubiquiti Assignment
DERIVED   := .build/DerivedData
# First available iPhone simulator on this machine; tests need a concrete device, builds do not.
SIM       ?= $(shell xcrun simctl list devices available | grep -m1 -o 'iPhone [^(]*' | sed 's/ *$$//')
XCB       := xcodebuild -project $(PROJECT) -scheme "$(SCHEME)" -derivedDataPath $(DERIVED)
PRETTY    := 2>&1 | grep -E "error:|warning:|BUILD|TEST|Executed|failed" ; exit $${PIPESTATUS[0]}

.PHONY: help build test run format lint lsp clean

help: ## list targets
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-8s %s\n", $$1, $$2}'

build: ## compile for the simulator (any machine, no simulator needed)
	@$(XCB) -configuration Debug -destination 'generic/platform=iOS Simulator' build $(PRETTY)

test: ## run unit tests on a local simulator (SIM="iPhone 16" to override)
	@$(XCB) -destination 'platform=iOS Simulator,name=$(SIM)' test $(PRETTY)

run: ## build here, pick simulator(s) and launch; RUN_HOST=user@mac launches there, SIM=name skips the picker
	@scripts/run.sh

format: ## swiftformat in place (brew install swiftformat)
	@swiftformat "Ubiquiti Assignment"

lint: ## swiftformat dry run, fails on diff
	@swiftformat --lint "Ubiquiti Assignment"

lsp: ## refresh sourcekit-lsp compile flags for the Xcode project (brew install xcode-build-server)
	@$(XCB) -configuration Debug -destination 'generic/platform=iOS Simulator' clean build 2>&1 | xcode-build-server parse >/dev/null

clean: ## remove build products
	@rm -rf .build
