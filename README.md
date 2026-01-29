# Homie 🏠

> The missing bridge between macOS and your home.

Homie is a context-aware HomeKit controller that understands what you're doing on your Mac and adjusts your home accordingly. It's local-first, privacy-respecting, and has a personality.

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- 🏠 **Native HomeKit** — Control all your HomeKit devices
- 🧠 **App-Aware Scenes** — Lightroom opens? Dim the lights. Zoom meeting? Brighten up.
- 🎭 **Personality** — Homie is a character that reacts to what's happening
- 🔒 **Paranoid Security** — Local-only, never touches the internet
- ⌨️ **CLI Included** — `hkctl` for terminal access
- 🚀 **Raycast Ready** — Natural language control (coming soon)

## The Idea

Your smart home shouldn't be dumb about context. When you're editing photos at night, the lights should dim automatically. When you join a video call, they should brighten. When someone tries to expose Homie to the internet, it should get angry (literally — the character frowns).

## Quick Start

```bash
# Clone
git clone https://github.com/YOUR_USERNAME/Homie.git
cd Homie

# Open in Xcode (requires Apple Developer account)
open Homie.xcodeproj

# Build and run
```

Grant HomeKit access when prompted, and you're good to go.

## HTTP API

Homie runs a local API on `localhost:8420`.

```bash
# List devices
curl http://localhost:8420/devices

# Toggle a device
curl -X POST http://localhost:8420/device/DEVICE_ID/toggle

# Trigger a scene
curl -X POST http://localhost:8420/scene/SCENE_NAME/trigger
```

## CLI

```bash
# Install CLI
sudo cp .build/release/hkctl /usr/local/bin/

# Use it
hkctl list
hkctl toggle "Office Lamp"
hkctl scene "Good Night"
```

## App-Aware Rules

Create rules that trigger based on what you're doing:

```json
{
  "name": "Photo Editing Mode",
  "app": "com.adobe.Lightroom*",
  "scene": "Dim Office",
  "revert": true
}
```

When Lightroom opens, office dims. When you close it, lights restore.

## Security

Homie is **paranoid about security**:

- Binds to `127.0.0.1` only — never exposed to network
- Startup check for port forwarding
- Visual indicator if something's wrong
- Character literally frowns if exposed to internet 😠

Optional LAN mode available with API key for local network access.

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Developer Program ($99/year) — required for HomeKit entitlement
- HomeKit-enabled devices

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full system design.

## Roadmap

- [x] Core HomeKit control
- [x] HTTP API
- [x] CLI tool
- [ ] Homie character UI
- [ ] App-aware scene rules
- [ ] Menu bar app
- [ ] Raycast extension
- [ ] Shortcuts.app integration
- [ ] Focus mode sync
- [ ] Bi-directional automation (HomeKit → Mac)

## Contributing

PRs welcome! This is a community project for people who want their smart home to actually be smart.

## License

MIT License — see [LICENSE](LICENSE) for details.

---

Built with 🏠 by [@itsgbro](https://github.com/itsgbro)
