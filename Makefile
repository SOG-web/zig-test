.PHONY: help generate-models build test clean run watch install-generator

help:
	@echo "Available commands:"
	@echo ""
	@echo "🔧 Models:"
	@echo "  make generate-models             - Generate all models from JSON schemas"
	@echo "  make generate-models OUT=<dir>   - Generate models to custom directory"
	@echo "  make install-generator           - Install zig-model-gen globally"
	@echo ""
	@echo "🚀 Build & Run:"
	@echo "  make build                       - Build the project"
	@echo "  make run                         - Build and run the server"
	@echo "  make watch                       - Run with auto-reload on file changes"
	@echo "  make test                        - Run tests"
	@echo "  make clean                       - Clean generated files"

generate-models:
	@echo "🚀 Generating models from JSON schemas..."
	@if [ -n "$(OUT)" ]; then \
		cd scripts && zig build -Doptimize=ReleaseFast && zig-out/bin/zig-model-gen ../schemas ../$(OUT); \
	else \
		cd scripts && zig build -Doptimize=ReleaseFast && zig-out/bin/zig-model-gen ../schemas; \
	fi
	@echo ""

install-generator:
	@echo "📦 Installing zig-model-gen..."
	@cd scripts && bash install.sh


build:
	@echo "Building project..."
	@zig build

run:
	@echo "🚀 Building and running server..."
	@zig build
	@./zig-out/bin/vendor_server

watch:
	@./dev.sh

test:
	@echo "Running tests..."
	@zig build test

clean:
	@echo "Cleaning generated files..."
	@rm -rf src/db/models/generated/
	@rm -rf zig-cache/ zig-out/
	@echo "✅ Clean complete"