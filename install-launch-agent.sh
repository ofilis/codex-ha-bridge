#!/bin/sh

set -eu

LABEL="com.ofilis.codex-ha-bridge"
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$PLIST_DIR/$LABEL.plist"
LOG_DIR="$ROOT/logs"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This installer only supports macOS." >&2
  exit 1
fi

NODE_PATH=$(command -v node || true)
if [ -z "$NODE_PATH" ]; then
  echo "Node.js was not found. Install Node.js 20 or newer and try again." >&2
  exit 1
fi

NODE_MAJOR=$("$NODE_PATH" -p "Number(process.versions.node.split('.')[0])")
if [ "$NODE_MAJOR" -lt 20 ]; then
  echo "Node.js 20 or newer is required. Found: $("$NODE_PATH" --version)" >&2
  exit 1
fi

if [ ! -f "$ROOT/.env" ]; then
  if [ -f "$ROOT/.env.example" ]; then
    cp "$ROOT/.env.example" "$ROOT/.env"
  fi
  echo ".env was created. Add your MQTT settings, then run this installer again."
  echo "File: $ROOT/.env"
  exit 1
fi

xml_escape() {
  printf "%s" "$1" |
    sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

NODE_XML=$(xml_escape "$NODE_PATH")
ROOT_XML=$(xml_escape "$ROOT")
STDOUT_XML=$(xml_escape "$LOG_DIR/bridge.log")
STDERR_XML=$(xml_escape "$LOG_DIR/bridge-error.log")

mkdir -p "$PLIST_DIR" "$LOG_DIR"

cat >"$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$NODE_XML</string>
    <string>$ROOT_XML/src/index.js</string>
  </array>
  <key>WorkingDirectory</key>
  <string>$ROOT_XML</string>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>ThrottleInterval</key>
  <integer>30</integer>
  <key>StandardOutPath</key>
  <string>$STDOUT_XML</string>
  <key>StandardErrorPath</key>
  <string>$STDERR_XML</string>
</dict>
</plist>
EOF

plutil -lint "$PLIST_PATH" >/dev/null
launchctl bootout "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"

echo "Installed and started the Codex Home Assistant MQTT Bridge LaunchAgent."
echo "LaunchAgent: $PLIST_PATH"
echo "Output log: $LOG_DIR/bridge.log"
echo "Error log: $LOG_DIR/bridge-error.log"
