<p align="center">
  <img src="docs/images/icon.png" width="128" alt="lil homie icon">
</p>

<h1 align="center">lil homie</h1>

<p align="center">
  <strong>HomeKit REST API + CLI for macOS</strong><br>
  <em>runs so you don't have to.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
  <img src="https://img.shields.io/github/v/release/ghostmfr/lilhomie" alt="Release">
</p>

---

**lil homie** exposes your HomeKit devices via a local REST API and CLI. Control lights, switches, and scenes from scripts, terminals, webhooks, or any automation tool.

- 🌐 **REST API** on `localhost:8420`
- ⌨️ **CLI** — `lilhomie` command
- 🏠 **Native HomeKit** — uses Apple's HomeKit framework
- 🔒 **Local only** — never touches the internet

---

## Installation

### Download

Grab the latest release:

👉 **[Download lil homie](https://github.com/ghostmfr/lilhomie/releases/latest)**

- `lil-homie-v1.0-mac.zip` — macOS app
- `lilhomie-cli-v1.0.zip` — CLI binary

### Setup

1. Unzip and drag **lil homie.app** to Applications
2. Launch and grant HomeKit access when prompted
3. Server starts automatically on port 8420

### CLI Installation

```bash
# Download and install
curl -L https://github.com/ghostmfr/lilhomie/releases/latest/download/lilhomie-cli-v1.0.zip -o lilhomie.zip
unzip lilhomie.zip
sudo mv lilhomie /usr/local/bin/
```

---

## REST API

The API runs on `http://localhost:8420` while the app is running.

> **Tip:** Use underscores for spaces in device/room names: `Desk_Lamp`

### Devices

```bash
# List all devices
curl localhost:8420/devices

# Get device info
curl localhost:8420/device/Desk_Lamp

# Toggle
curl -X POST localhost:8420/device/Desk_Lamp/toggle

# Set brightness
curl -X POST localhost:8420/device/Desk_Lamp/set \
  -H "Content-Type: application/json" \
  -d '{"brightness": 50}'
```

### Rooms

```bash
# List rooms
curl localhost:8420/rooms

# All devices in room
curl localhost:8420/room/Office

# Room on/off
curl -X POST localhost:8420/room/Office/on
curl -X POST localhost:8420/room/Office/off
```

### Scenes

```bash
# List scenes
curl localhost:8420/scenes

# Trigger scene
curl -X POST localhost:8420/scene/Good_Night/trigger
```

---

## CLI

```bash
lilhomie list                    # List all devices
lilhomie status "Desk Lamp"      # Device status
lilhomie on "Desk Lamp"          # Turn on
lilhomie off "Desk Lamp"         # Turn off
lilhomie toggle "Desk Lamp"      # Toggle
lilhomie set "Desk Lamp" -b 50   # Set brightness

lilhomie scenes                  # List scenes
lilhomie scene "Good Night"      # Trigger scene
```

---

## Use Cases

- **Home automation scripts** — bash, Python, Node.js
- **Stream Deck buttons** — trigger via curl
- **Raycast/Alfred** — quick device control
- **Webhooks** — IFTTT, n8n, Home Assistant
- **Cron jobs** — scheduled lighting
- **SSH** — control home from anywhere

---

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Developer account (for HomeKit entitlement)
- HomeKit-compatible devices

---

## Building from Source

```bash
git clone https://github.com/ghostmfr/lilhomie.git
cd lilhomie
open Homie.xcodeproj
# Build and run in Xcode
```

---

## Known Issues

See [Issues](https://github.com/ghostmfr/lilhomie/issues) for current bugs.

---

## License

MIT — see [LICENSE](LICENSE)

---

<p align="center">
  Built with 🏠💨 by <a href="https://github.com/ghostmfr">Ghost Manufacture</a>
</p>
