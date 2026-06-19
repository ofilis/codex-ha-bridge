# Codex Home Assistant MQTT Bridge

Publish OpenAI Codex usage limits to Home Assistant over MQTT.

**Codex Home Assistant MQTT Bridge** reads the same Codex usage information used by the Codex client, normalizes it, and publishes Home Assistant MQTT Discovery entities for the 5-hour and weekly usage windows.

It is designed to be lightweight: there are no npm package dependencies, and included startup helpers can run the bridge in the background on Windows or macOS.

---

## Features

- Publishes Codex usage to Home Assistant via MQTT.
- Creates Home Assistant sensors automatically with MQTT Discovery.
- Tracks 5-hour usage and remaining percentage.
- Tracks weekly usage and remaining percentage.
- Publishes retained state and availability topics for reliable Home Assistant restarts.
- Publishes reset times:
  - `Codex 5h Reset`: `16:49`
  - `Codex Weekly Reset`: `12/05 - 09:01`
- Publishes plan, credits, and limit status.
- Runs without npm dependencies.
- Includes Windows startup helpers that run silently in the background.
- Includes a macOS LaunchAgent installer for background startup at login.

---

## Screenshots

Codex usage shown on a small Home Assistant dashboard display:

<img src="docs/images/pic-1.jpg" alt="Codex usage shown on a small Home Assistant dashboard display" width="720">

Home Assistant MQTT device and sensor entities:

<img src="docs/images/pic-2.png" alt="Codex usage sensors in Home Assistant" width="640">

---

## Home Assistant entities

The bridge publishes these sensors:

| Sensor | Example |
| --- | --- |
| `Codex 5h Used` | `49%` |
| `Codex 5h Remaining` | `51%` |
| `Codex 5h Reset` | `16:49` |
| `Codex Weekly Used` | `8%` |
| `Codex Weekly Remaining` | `92%` |
| `Codex Weekly Reset` | `12/05 - 09:01` |
| `Codex Credits` | `0 credits` |
| `Codex Plan` | `plus` |
| `Codex Limit Status` | `OK` |

All sensor values come from the retained JSON state payload on `codex/usage/state`, with bridge availability published on `codex/usage/availability`.

---

## How it works

1. The bridge reads Codex authentication data from your local Codex configuration directory, or from an optional access token fallback.
2. It requests Codex usage information from the Codex backend usage endpoint.
3. It flattens the response into simple values suitable for MQTT state payloads.
4. It publishes MQTT Discovery configs so Home Assistant creates the sensors automatically.
5. It periodically republishes the current usage state and availability.

Default MQTT topics:

```text
homeassistant/sensor/codex_usage/...
codex/usage/state
codex/usage/availability
```

---

## Requirements

- Windows, macOS, or Linux with Node.js 20 or newer.
- Home Assistant with MQTT enabled.
- A working MQTT broker, such as the Mosquitto add-on.
- A valid Codex login on the machine running the bridge.

The Windows helper scripts can also use the Node.js runtime bundled with the Codex desktop app when it is available.

---

## Quick start on Windows

1. Copy `.env.example` to `.env`.
2. Edit `.env` with your MQTT settings.
3. Double-click `start.bat` to test the bridge.
4. Double-click `install-startup-task.bat` to run it silently when you sign in to Windows.

Example `.env`:

```env
MQTT_URL=mqtt://192.168.1.50:1883
MQTT_USERNAME=ha_demo_user
MQTT_PASSWORD=your-password
POLL_SECONDS=60
```

Do not commit your `.env` file. It contains your MQTT password and may contain Codex-related credentials.

---

## Manual start

If Node.js is installed and available in your terminal:

```powershell
node src/index.js
```

Or through npm:

```powershell
npm start
```

If you are using the Windows helper:

```powershell
.\run.ps1
```

---

## Background startup on macOS

First copy and configure the environment file:

```bash
cp .env.example .env
```

Install and immediately start a per-user LaunchAgent:

```bash
./install-launch-agent.sh
```

The installer resolves the current Node.js executable, requires Node.js 20 or newer, and creates:

```text
~/Library/LaunchAgents/com.ofilis.codex-ha-bridge.plist
```

The bridge starts when you sign in and restarts if it exits. Logs are written to:

```text
logs/bridge.log
logs/bridge-error.log
```

Run the installer again after moving the repository or changing the Node.js installation. To stop the bridge and remove the LaunchAgent:

```bash
./uninstall-launch-agent.sh
```

---

## Silent startup on Windows

To create a Windows startup shortcut:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-startup-task.ps1
```

Or double-click:

```text
install-startup-task.bat
```

This creates a shortcut in the user's Windows Startup folder and starts the bridge immediately. It does not keep a terminal window open.

To remove the startup shortcut:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall-startup-task.ps1
```

When installed as a silent Windows startup app, logs are written to:

```text
logs/bridge.log
```

---

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `MQTT_URL` | `mqtt://homeassistant.local:1883` | MQTT broker URL. The built-in MQTT client supports `mqtt://`. |
| `MQTT_USERNAME` | empty | MQTT username. |
| `MQTT_PASSWORD` | empty | MQTT password. |
| `CODEX_HOME` | `~/.codex` | Codex config/auth directory. |
| `CODEX_ACCESS_TOKEN` | empty | Optional bearer token fallback. |
| `CHATGPT_ACCOUNT_ID` | empty | Optional account ID override when needed by the Codex backend request. |
| `CODEX_BACKEND_URL` | `https://chatgpt.com/backend-api/wham/usage` | Optional backend usage endpoint override. |
| `CODEX_REFRESH_TOKEN_URL` | `https://auth.openai.com/oauth/token` | Optional token refresh endpoint override. |
| `POLL_SECONDS` | `60` | How often to publish usage updates. |
| `MQTT_BASE_TOPIC` | `codex/usage` | MQTT state/availability topic prefix. |
| `HA_DISCOVERY_PREFIX` | `homeassistant` | Home Assistant MQTT discovery prefix. |
| `DEVICE_ID` | `codex_usage` | Home Assistant device identifier. |
| `DEVICE_NAME` | `Codex Usage` | Home Assistant device name. |

---

## Example Home Assistant dashboard cards

5-hour usage gauge:

```yaml
type: gauge
entity: sensor.codex_5h_used
name: Codex 5h
min: 0
max: 100
severity:
  green: 0
  yellow: 70
  red: 90
```

Weekly usage gauge:

```yaml
type: gauge
entity: sensor.codex_weekly_used
name: Codex Weekly
min: 0
max: 100
severity:
  green: 0
  yellow: 70
  red: 90
```

---

## Repository contents

```text
.
├── .env.example
├── README.md
├── package.json
├── install-launch-agent.sh
├── uninstall-launch-agent.sh
├── start.bat
├── run.ps1
├── run-service.ps1
├── run-hidden.vbs
├── install-startup-task.bat
├── install-startup-task.ps1
├── uninstall-startup-task.ps1
├── docs/
│   └── images/
└── src/
    ├── auth.js
    ├── codexUsage.js
    ├── config.js
    ├── index.js
    ├── mqttHa.js
    └── simpleMqtt.js
```

### Main files

- `src/index.js` — bridge entry point and polling loop.
- `src/config.js` — environment/config loading.
- `src/auth.js` — Codex authentication handling.
- `src/codexUsage.js` — Codex usage request and normalization.
- `src/mqttHa.js` — Home Assistant MQTT Discovery and state publishing.
- `src/simpleMqtt.js` — minimal MQTT client implementation.
- `install-launch-agent.sh` / `uninstall-launch-agent.sh` — macOS LaunchAgent management.
- `start.bat`, `run.ps1`, `run-service.ps1`, `run-hidden.vbs` — Windows run helpers.
- `install-startup-task.ps1` / `uninstall-startup-task.ps1` — Windows startup shortcut management.

---

## Development / validation

This project has no npm dependencies. To validate JavaScript syntax:

```powershell
npm run check
```

The check script runs `node --check` against the source files.

---

## Troubleshooting

### Sensors do not appear in Home Assistant

- Confirm MQTT is enabled in Home Assistant.
- Confirm your MQTT broker URL, username, and password in `.env`.
- Check that Home Assistant MQTT Discovery is enabled.
- Check the bridge logs for MQTT connection errors.

### Usage values are not updating

- Confirm Codex is logged in on the same machine running the bridge.
- Confirm `CODEX_HOME` points to the correct Codex config/auth directory if you use a non-default location.
- Run the bridge manually with `node src/index.js` to see foreground logs.

### The Windows startup task does not run silently

- Re-run `install-startup-task.bat` or `install-startup-task.ps1`.
- Check `logs/bridge.log` in the repository directory.
- Confirm Node.js is available, or that the Codex desktop app bundled Node.js runtime can be found by the helper scripts.

### The macOS LaunchAgent does not start

- Check `logs/bridge-error.log` for startup or connection errors.
- Run `launchctl print gui/$(id -u)/com.ofilis.codex-ha-bridge` to inspect its status.
- Re-run `./install-launch-agent.sh` after moving the repository or changing the Node.js installation.
- Confirm `.env` contains valid MQTT settings and Node.js 20 or newer is installed.

---

## Security and privacy

- Do not commit `.env`.
- Do not share `CODEX_ACCESS_TOKEN` if you use it.
- The bridge does not publish your Codex token or MQTT password to Home Assistant.
- MQTT state payloads contain usage/limit information only, not authentication headers, refresh tokens, or raw credential objects.
- If OpenAI changes the Codex backend endpoint or response shape, the bridge may need an update.

---

## Notes and limitations

This project uses the Codex backend usage endpoint used by Codex itself. It is not a separately documented public API.

Because of that, endpoint paths, authentication behavior, or response formats may change without notice. If that happens, update the bridge before relying on it for automations or monitoring.
