# AudioSwitcher

A lightweight macOS menu bar app that toggles between two audio device sets (e.g. headset vs. monitor) with a single click or global hotkey.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## Features

- Menu bar icon shows active audio profile
- Toggle between two audio device sets (input + output)
- Configurable global hotkey (default: Cmd+Shift+A)
- Separate input/output devices per profile
- Zero dependencies besides [SwitchAudioSource](https://github.com/deweller/switchaudio-osx)
- Single-file Swift app, no Xcode project needed

## Installation

### Prerequisites

Install [SwitchAudioSource](https://github.com/deweller/switchaudio-osx) via Homebrew:

```bash
brew install switchaudio-osx
```

### Build from source

```bash
git clone https://github.com/Raptus/AudioSwitcher.git
cd AudioSwitcher
swiftc -o AudioSwitcher AudioSwitcher.swift -framework Cocoa -framework Carbon
```

## Configuration

### 1. List available devices

```bash
./AudioSwitcher --list-devices
```

Output:

```
Input devices:
  MacBook Pro Microphone
  Jabra Link 380
  PHL 34B2U6603CH

Output devices:
  MacBook Pro Speakers
  Jabra Link 380
  PHL 34B2U6603CH
```

### 2. Create config file

```bash
./AudioSwitcher --init
```

This creates `~/.config/audioswitcher/config.json` with default values.

### 3. Edit the config

```json
{
  "primaryInput": "Jabra Link 380",
  "primaryOutput": "Jabra Link 380",
  "secondaryInput": "PHL 34B2U6603CH",
  "secondaryOutput": "PHL 34B2U6603CH",
  "hotkeyKey": "a",
  "hotkeyModifiers": ["cmd", "shift"]
}
```

| Field | Description |
|-------|-------------|
| `primaryInput` | Input device for profile 1 (e.g. headset microphone) |
| `primaryOutput` | Output device for profile 1 (e.g. headset speakers) |
| `secondaryInput` | Input device for profile 2 (e.g. monitor microphone) |
| `secondaryOutput` | Output device for profile 2 (e.g. monitor speakers) |
| `hotkeyKey` | Key for the global hotkey (a-z, 0-9, f1-f12) |
| `hotkeyModifiers` | Modifier keys: `cmd`, `shift`, `alt`/`option`, `ctrl`/`control` |

**Tip:** Use `--list-devices` to find the exact device names. They must match exactly.

### 4. Verify config

```bash
./AudioSwitcher --config
```

## Usage

### Start the app

```bash
./AudioSwitcher
```

The menu bar shows:
- **Headphones icon** when primary profile is active
- **Monitor icon** when secondary profile is active

Click the icon to see current input/output devices, toggle the profile, or quit.

### Global hotkey

Press **Cmd+Shift+A** (or your configured hotkey) anywhere to toggle between profiles.

## Auto-start on login

Create a Launch Agent to start AudioSwitcher automatically:

```bash
cat > ~/Library/LaunchAgents/com.audioswitcher.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.audioswitcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/AudioSwitcher</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF
```

Replace `/path/to/AudioSwitcher` with the actual path to the binary, then load it:

```bash
launchctl load ~/Library/LaunchAgents/com.audioswitcher.plist
```

To remove:

```bash
launchctl unload ~/Library/LaunchAgents/com.audioswitcher.plist
rm ~/Library/LaunchAgents/com.audioswitcher.plist
```

## CLI Reference

| Command | Description |
|---------|-------------|
| `./AudioSwitcher` | Start the menu bar app |
| `./AudioSwitcher --list-devices` | List available audio input/output devices |
| `./AudioSwitcher --init` | Create default config at `~/.config/audioswitcher/config.json` |
| `./AudioSwitcher --config` | Display current configuration |
| `./AudioSwitcher --help` | Show help |

## License

MIT - see [LICENSE](LICENSE).
