.DEFAULT_GOAL := help
.PHONY: all run run-fg stop build release app package release-patch release-minor release-major release-publish release-dry-run install logs clean help

all: help

# Compile and run the app in background (Debug)
run:
	@./scripts/run.sh

# Run the app in terminal foreground with live console logs
run-fg:
	@./scripts/run.sh --foreground

# Terminate running app instance
stop:
	@./scripts/stop.sh

# Compile in Debug mode
build:
	@./scripts/build.sh --debug

# Compile in Release mode
release:
	@./scripts/build.sh --release

# Compile Release mode and assemble .app bundle
app: release

# Compile Release build and package distribution archive (.zip & .sha256) under dist/
package:
	@./scripts/package.sh

# Release SemVer Patch version (Changelog, Tag, GH Release)
release-patch:
	@./scripts/release.sh patch

# Release SemVer Minor version (Changelog, Tag, GH Release)
release-minor:
	@./scripts/release.sh minor

# Release SemVer Major version (Changelog, Tag, GH Release)
release-major:
	@./scripts/release.sh major

# Release custom version or default patch (e.g. make release-publish VERSION=1.2.0)
release-publish:
	@./scripts/release.sh $(if $(VERSION),$(VERSION),patch)

# Simulate full release cycle without making permanent changes
release-dry-run:
	@./scripts/release.sh $(if $(VERSION),$(VERSION),patch) --dry-run

# Compile Release and install permanently into macOS /Applications
install:
	@./scripts/install.sh --release

# Stream live unified system logs
logs:
	@./scripts/logs.sh

# Clean build artifacts and cache
clean:
	@./scripts/build.sh --clean

# Help menu
help:
	@echo "Router Check - Developer and Release Commands:"
	@echo "  make (or make help)  : Show this help menu (Default)"
	@echo "  make run             : Build Debug and launch in background"
	@echo "  make run-fg          : Run in foreground with live console logs"
	@echo "  make stop            : Terminate running application instance"
	@echo "  make build           : Compile Debug configuration only"
	@echo "  make release         : Compile Release configuration only"
	@echo "  make app             : Compile Release and assemble .app bundle"
	@echo "  make package         : Build Release and package distribution archive (dist/)"
	@echo "  make release-patch   : Bump and release SemVer Patch version (e.g. 1.0.0 -> 1.0.1)"
	@echo "  make release-minor   : Bump and release SemVer Minor version (e.g. 1.0.0 -> 1.1.0)"
	@echo "  make release-major   : Bump and release SemVer Major version (e.g. 1.0.0 -> 2.0.0)"
	@echo "  make release-publish : Release specified version (e.g. make release-publish VERSION=1.2.0)"
	@echo "  make release-dry-run : Simulate full release cycle safely without changes"
	@echo "  make install         : Build Release and install to /Applications"
	@echo "  make logs            : Stream live application logs"
	@echo "  make clean           : Clean build artifacts and cache"
