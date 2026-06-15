#!/bin/sh

set -eu

LABEL="com.ofilis.codex-ha-bridge"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This uninstaller only supports macOS." >&2
  exit 1
fi

if [ ! -f "$PLIST_PATH" ]; then
  echo "No LaunchAgent was found at $PLIST_PATH"
  exit 0
fi

launchctl bootout "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null || true
rm "$PLIST_PATH"

echo "Stopped and removed the Codex Home Assistant MQTT Bridge LaunchAgent."
