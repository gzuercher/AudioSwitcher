# AudioSwitcher – Claude Code Guide

A native macOS menu bar app to toggle between two audio device sets with a global hotkey.

## Project Overview

- **Language:** Swift (single-file app)
- **Frameworks:** Cocoa, Carbon (for global hotkeys)
- **Dependency:** [SwitchAudioSource](https://github.com/deweller/switchaudio-osx) (CLI tool)
- **Config:** `~/.config/audioswitcher/config.json`

## Build

```bash
swiftc -o AudioSwitcher AudioSwitcher.swift -framework Cocoa -framework Carbon
```

## Run

```bash
./AudioSwitcher              # Start menu bar app
./AudioSwitcher --list-devices   # List available audio devices
./AudioSwitcher --init           # Create default config
./AudioSwitcher --config         # Show current config
./AudioSwitcher --help           # Show help
```

## Architecture

Single-file Swift app (`AudioSwitcher.swift`) with these sections:

- **Configuration** – `Config` struct, JSON load/save from `~/.config/audioswitcher/config.json`
- **SwitchAudioSource** – Wrapper functions calling the CLI tool
- **CLI Commands** – `--list-devices`, `--init`, `--config`, `--help`
- **Global Hotkey** – Carbon `RegisterEventHotKey` for system-wide shortcut
- **Menu Bar App** – `NSStatusItem` with toggle, status display, quit

## Rules

- Keep it as a single Swift file – no Xcode project, no SPM
- Communication with user: German
- Code, comments, documentation: English
- Commit messages: German, imperative ("Füge Validierung hinzu")
- No hardcoded device names in source – everything via config
- SwitchAudioSource path is auto-detected (Homebrew ARM + Intel + `which`)
