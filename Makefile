DEVELOPER_DIR := /Applications/Xcode-beta.app/Contents/Developer
export DEVELOPER_DIR
SDK := $(shell xcrun --show-sdk-path)
TARGET := arm64-apple-macosx14.0
DIGESTER := xcrun swift-api-digester
MODULES := .build/release
ABI := abi/AinkradAppKit.abi.json
ALLOWLIST := abi/breakage-allowlist.txt

.PHONY: build abi-baseline abi-check test
build:
	swift build -c release

# Regenerate the committed ABI baseline (run after an intentional, reviewed change).
abi-baseline: build
	$(DIGESTER) -dump-sdk -abi -module AinkradAppKit \
	  -o $(ABI) -I $(MODULES) -sdk $(SDK) -target $(TARGET)

# Fail if the current module has an ABI break vs. the committed baseline.
abi-check: build
	$(DIGESTER) -diagnose-sdk -abi -module AinkradAppKit \
	  -baseline-path $(ABI) -I $(MODULES) -sdk $(SDK) -target $(TARGET) \
	  -breakage-allowlist-path $(ALLOWLIST) -o abi/report.txt ; \
	if grep -q "has been" abi/report.txt 2>/dev/null; then \
	  echo "ABI BREAK vs baseline (bump generation or allowlist):"; cat abi/report.txt; exit 1; \
	else echo "abi-check: no breaking changes"; fi

test:
	swift test
