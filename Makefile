.PHONY: all build build-cli install generate clean help

all: generate build

# Generate Xcode project from project.yml (requires xcodegen)
generate:
	@if command -v xcodegen >/dev/null 2>&1; then \
		xcodegen generate; \
	else \
		echo "⚠️  xcodegen not installed. Install with: brew install xcodegen"; \
		echo "   Or open the existing Homie.xcodeproj"; \
	fi

# Build the app
build:
	xcodebuild -project Homie.xcodeproj \
		-scheme Homie \
		-configuration Release \
		-destination 'platform=macOS' \
		build

# Build just the CLI tool
build-cli:
	swift build -c release

# Install CLI to /usr/local/bin
install: build-cli
	sudo cp .build/release/hkctl /usr/local/bin/
	sudo chmod +x /usr/local/bin/hkctl
	@echo "✅ Installed: /usr/local/bin/hkctl"

# Clean build artifacts
clean:
	rm -rf .build build DerivedData
	xcodebuild clean -project Homie.xcodeproj -scheme Homie 2>/dev/null || true

# Archive for distribution
archive:
	xcodebuild -project Homie.xcodeproj \
		-scheme Homie \
		-configuration Release \
		-archivePath build/Homie.xcarchive \
		archive

help:
	@echo "Homie Build Targets:"
	@echo "  make generate   - Generate Xcode project (requires xcodegen)"
	@echo "  make build      - Build the app"
	@echo "  make build-cli  - Build the CLI tool"
	@echo "  make install    - Install CLI to /usr/local/bin"
	@echo "  make clean      - Remove build artifacts"
	@echo "  make archive    - Create release archive"
	@echo ""
	@echo "Requirements:"
	@echo "  - Apple Developer Program for HomeKit entitlement"
	@echo "  - xcodegen for project generation (optional)"
