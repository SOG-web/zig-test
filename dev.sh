#!/bin/bash
# Development script with auto-reload

set -e

echo "🔄 Starting development server with auto-reload..."
echo "📁 Watching: src/, build.zig"
echo "Press Ctrl+C to stop"
echo ""

watchexec -r -e zig -w src -w build.zig \
  --ignore '*.swp' \
  --ignore '*.tmp' \
  -- bash -c "clear && echo '🔨 Building...' && zig build && echo '✅ Build successful!' && echo '🚀 Starting server...' && echo '' && ./zig-out/bin/vendor_server"

