PROJECT   := Ubiquiti\ Assignment.xcodeproj
SCHEME    := Ubiquiti Assignment
DERIVED   := .build/DerivedData
# An iPhone simulator on the newest installed iOS runtime (simctl lists runtimes oldest first, so take the last
# iPhone); tests need a concrete device that meets the deployment target, builds do not. The name must run straight
# into the UDID so "iPhone SE (3rd generation)" is skipped rather than truncated to "iPhone SE". No parentheses in
# the pattern: make 3.81 cannot parse an unbalanced "(" inside $(shell), hence the "." before the UDID.
SIM       ?= $(shell xcrun simctl list devices available | grep -oE 'iPhone [A-Za-z0-9 ]+ .[0-9A-F-]{36}' | tail -1 | sed -E 's/ .[0-9A-F-]{36}$$//')
XCB       := xcodebuild -project $(PROJECT) -scheme "$(SCHEME)" -derivedDataPath $(DERIVED)
PRETTY    := 2>&1 | grep -E "error:|warning:|BUILD|TEST|Executed|failed" ; exit $${PIPESTATUS[0]}
SOURCES   := "Ubiquiti Assignment" "Ubiquiti AssignmentTests"
# Fail loudly when the formatter is missing: a silent skip is how an unformatted branch ships.
SWIFTFORMAT = $(or $(shell command -v swiftformat),$(error swiftformat not found: brew install swiftformat))

.PHONY: help build test run format lint lsp clean

help: ## list targets
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-8s %s\n", $$1, $$2}'

build: ## compile for the simulator (any machine, no simulator needed)
	@$(XCB) -configuration Debug -destination 'generic/platform=iOS Simulator' build $(PRETTY)

test: ## run unit tests on a local simulator (SIM="iPhone 16" to override)
	@test -n "$(SIM)" || { echo "no iPhone simulator found: install one in Xcode or pass SIM=name"; exit 1; }
	@$(XCB) -destination 'platform=iOS Simulator,name=$(SIM)' test $(PRETTY)

run: ## build here, pick simulator(s) and launch; RUN_HOST=user@mac launches there, SIM=name skips the picker
	@scripts/run.sh

format: ## swiftformat in place over app and tests (brew install swiftformat)
	@$(SWIFTFORMAT) $(SOURCES)

lint: ## swiftformat dry run over app and tests, fails on diff
	@$(SWIFTFORMAT) $(SOURCES) --lint

lsp: ## refresh sourcekit-lsp compile flags for the Xcode project (brew install xcode-build-server)
	@$(XCB) -configuration Debug -destination 'generic/platform=iOS Simulator' clean build 2>&1 | xcode-build-server parse >/dev/null

clean: ## remove build products
	@rm -rf .build
