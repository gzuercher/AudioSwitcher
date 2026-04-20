# Contributing

## Build

```bash
swiftc -o AudioSwitcher AudioSwitcher.swift -framework Cocoa -framework Carbon
```

## Project structure

```
AudioSwitcher/
  AudioSwitcher.swift   # Complete source (single file)
  CLAUDE.md             # Claude Code project guide
  README.md             # User documentation
  LICENSE               # MIT
```

## Guidelines

- Keep everything in a single Swift file — no Xcode project, no Swift Package Manager
- Code and comments in English
- Commit messages in German, imperative ("Füge Feature hinzu")
- No hardcoded device names — all configuration via `~/.config/audioswitcher/config.json`
- Test with `--list-devices`, `--init`, `--config` after changes

## Testing

1. Build the binary
2. Run `./AudioSwitcher --list-devices` to verify SwitchAudioSource detection
3. Run `./AudioSwitcher --init` and verify config is created
4. Run `./AudioSwitcher` and verify menu bar icon, toggle, and hotkey
