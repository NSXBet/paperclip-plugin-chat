#!/usr/bin/env bash
# Setup script: copies the Paperclip Plugin SDK from the local Paperclip
# installation into .paperclip-sdk/ so the plugin can build.
#
# Usage: ./scripts/setup-sdk.sh
#
# The SDK is not published to npm, so it must be copied from your local
# Paperclip installation's dependency cache.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SDK_DIR="$PROJECT_DIR/.paperclip-sdk/plugin-sdk"

if [ -d "$SDK_DIR" ] && [ -f "$SDK_DIR/package.json" ]; then
  echo "SDK already set up at $SDK_DIR"
  exit 0
fi

echo "Looking for @paperclipai/plugin-sdk in local caches..."

# Try common locations where Paperclip stores the SDK
SDK_SOURCE=""

# 1. Bun cache (most common for Paperclip installations)
for dir in "$HOME"/.bun/install/cache/@paperclipai/plugin-sdk@*; do
  if [ -d "$dir" ] && [ -f "$dir/package.json" ]; then
    SDK_SOURCE="$dir"
    break
  fi
done

# 2. npm global cache
if [ -z "$SDK_SOURCE" ]; then
  for dir in "$HOME"/.npm/_npx/**/node_modules/@paperclipai/plugin-sdk; do
    if [ -d "$dir" ] && [ -f "$dir/package.json" ]; then
      SDK_SOURCE="$dir"
      break
    fi
  done
fi

# 3. Paperclip plugins directory
if [ -z "$SDK_SOURCE" ]; then
  for dir in "$HOME"/.paperclip/plugins/node_modules/@paperclipai/plugin-sdk; do
    if [ -d "$dir" ] && [ -f "$dir/package.json" ]; then
      SDK_SOURCE="$dir"
      break
    fi
  done
fi

# 4. bunx cache (used by paperclipai CLI)
if [ -z "$SDK_SOURCE" ]; then
  for dir in /tmp/bunx-*-paperclipai@*/node_modules/@paperclipai/plugin-sdk; do
    if [ -d "$dir" ] && [ -f "$dir/package.json" ]; then
      SDK_SOURCE="$dir"
      break
    fi
  done
fi

if [ -z "$SDK_SOURCE" ]; then
  echo "ERROR: Could not find @paperclipai/plugin-sdk in any known location."
  echo ""
  echo "Please copy it manually:"
  echo "  mkdir -p .paperclip-sdk"
  echo "  cp -r /path/to/@paperclipai/plugin-sdk .paperclip-sdk/plugin-sdk"
  echo ""
  echo "Common locations:"
  echo "  ~/.bun/install/cache/@paperclipai/plugin-sdk@*/"
  echo "  ~/.paperclip/plugins/node_modules/@paperclipai/plugin-sdk/"
  exit 1
fi

echo "Found SDK at: $SDK_SOURCE"
mkdir -p "$PROJECT_DIR/.paperclip-sdk"
cp -r "$SDK_SOURCE" "$SDK_DIR"
echo "SDK copied to $SDK_DIR"
echo "You can now run: npm install && npm run build"
