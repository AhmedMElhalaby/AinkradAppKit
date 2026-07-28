# The project currently needs the macOS 27 beta SDK; default to Xcode-beta when
# it's installed. On a machine/runner without Xcode-beta (e.g. a GitHub-hosted
# macos-latest runner), fall back to whatever toolchain `xcode-select` already
# points at instead of a nonexistent path. An explicitly supplied DEVELOPER_DIR
# (env or command line) always wins over both.
# Override on the command line: `make abi-check DEVELOPER_DIR=…` or point at a
# different beta install with `make abi-check XCODE_BETA=…`.
XCODE_BETA := /Applications/Xcode-beta.app/Contents/Developer
DEVELOPER_DIR ?= $(if $(wildcard $(XCODE_BETA)),$(XCODE_BETA),$(shell xcode-select -p))
export DEVELOPER_DIR
SDK := $(shell xcrun --show-sdk-path)
TARGET := arm64-apple-macosx14.0
DIGESTER := xcrun swift-api-digester
MODULES := .build/release
ABI := abi/AinkradAppKitContract.abi.json
ALLOWLIST := abi/breakage-allowlist.txt

.PHONY: build abi-baseline abi-check test
build:
	swift build -c release

# The baseline tracks AinkradAppKitContract ONLY.
#
# It used to cover the whole package, so every HUD component tweak registered as
# an ABI event and the committed baseline was ~90% component churn — real
# contract changes had nothing to stand out against. The contract is the only
# module whose ABI can stop an installed plugin from loading, so it is the only
# one held to this standard. AinkradAppKitUI is free to move.

# Regenerate the committed ABI baseline (run after an intentional, reviewed change).
abi-baseline: build
	$(DIGESTER) -dump-sdk -abi -module AinkradAppKitContract \
	  -o $(ABI) -I $(MODULES) -sdk $(SDK) -target $(TARGET)

# Fail if the current module has an ABI break vs. the committed baseline.
# The pass/fail decision lives in scripts/abi-check.sh — see the comment there
# for why `grep "has been"` was not enough: it cannot see added protocol
# requirements, which are exactly the break library evolution does NOT cover.
abi-check: build
	$(DIGESTER) -diagnose-sdk -abi -module AinkradAppKitContract \
	  -baseline-path $(ABI) -I $(MODULES) -sdk $(SDK) -target $(TARGET) \
	  -breakage-allowlist-path $(ALLOWLIST) -o abi/report.txt
	@./scripts/abi-check.sh abi/report.txt

test:
	swift test
