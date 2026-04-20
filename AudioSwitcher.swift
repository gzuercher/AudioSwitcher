import Cocoa
import Carbon
import Foundation

// MARK: - Configuration

struct Config: Codable {
    var primaryInput: String
    var primaryOutput: String
    var secondaryInput: String
    var secondaryOutput: String
    var hotkeyKey: String
    var hotkeyModifiers: [String]

    static let configDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/audioswitcher")
    static let configFile = configDir.appendingPathComponent("config.json")

    static let defaultConfig = Config(
        primaryInput: "Jabra Link 380",
        primaryOutput: "Jabra Link 380",
        secondaryInput: "MacBook Pro Microphone",
        secondaryOutput: "MacBook Pro Speakers",
        hotkeyKey: "a",
        hotkeyModifiers: ["cmd", "shift"]
    )

    static func load() -> Config {
        guard FileManager.default.fileExists(atPath: configFile.path) else {
            return defaultConfig
        }
        do {
            let data = try Data(contentsOf: configFile)
            return try JSONDecoder().decode(Config.self, from: data)
        } catch {
            fputs("Error reading config: \(error.localizedDescription)\n", stderr)
            fputs("Using default config.\n", stderr)
            return defaultConfig
        }
    }

    func save() throws {
        try FileManager.default.createDirectory(at: Config.configDir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: Config.configFile)
    }

    var carbonModifiers: UInt32 {
        var mods: UInt32 = 0
        for m in hotkeyModifiers {
            switch m.lowercased() {
            case "cmd", "command": mods |= UInt32(cmdKey)
            case "shift": mods |= UInt32(shiftKey)
            case "alt", "option": mods |= UInt32(optionKey)
            case "ctrl", "control": mods |= UInt32(controlKey)
            default: break
            }
        }
        return mods
    }

    var carbonKeyCode: UInt32 {
        let keyMap: [String: UInt32] = [
            "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7,
            "c": 8, "v": 9, "b": 11, "q": 12, "w": 13, "e": 14, "r": 15,
            "y": 16, "t": 17, "1": 18, "2": 19, "3": 20, "4": 21, "6": 22,
            "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28, "0": 29,
            "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35, "l": 37,
            "j": 38, "'": 39, "k": 40, ";": 41, "\\": 42, ",": 43, "/": 44,
            "n": 45, "m": 46, ".": 47, "`": 50, " ": 49,
            "f1": 122, "f2": 120, "f3": 99, "f4": 118, "f5": 96, "f6": 97,
            "f7": 98, "f8": 100, "f9": 101, "f10": 109, "f11": 103, "f12": 111,
        ]
        return keyMap[hotkeyKey.lowercased()] ?? 0
    }

    var hotkeyDescription: String {
        let modLabels = hotkeyModifiers.map { m -> String in
            switch m.lowercased() {
            case "cmd", "command": return "Cmd"
            case "shift": return "Shift"
            case "alt", "option": return "Opt"
            case "ctrl", "control": return "Ctrl"
            default: return m
            }
        }
        return "\(modLabels.joined(separator: "+"))+\(hotkeyKey.uppercased())"
    }
}

// MARK: - SwitchAudioSource

func findSwitchAudioSource() -> String? {
    let paths = [
        "/opt/homebrew/bin/SwitchAudioSource",
        "/usr/local/bin/SwitchAudioSource",
    ]
    for path in paths {
        if FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
    }
    // Try `which`
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
    task.arguments = ["SwitchAudioSource"]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = FileHandle.nullDevice
    try? task.run()
    task.waitUntilExit()
    let result = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return result.isEmpty ? nil : result
}

var switchAudioSourcePath: String = ""

func runSwitchAudioSource(_ args: [String]) -> String {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: switchAudioSourcePath)
    task.arguments = args
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = FileHandle.nullDevice
    try? task.run()
    task.waitUntilExit()
    return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

func currentAudioDevice(type: String) -> String {
    runSwitchAudioSource(["-t", type, "-c"])
}

func switchAudio(device: String, type: String) {
    _ = runSwitchAudioSource(["-t", type, "-s", device])
}

func listDevices(type: String) -> [String] {
    runSwitchAudioSource(["-a", "-t", type])
        .components(separatedBy: "\n")
        .filter { !$0.isEmpty }
}

// MARK: - CLI Commands

func handleCLI() -> Bool {
    let args = CommandLine.arguments
    guard args.count > 1 else { return false }

    switch args[1] {
    case "--list-devices":
        print("Input devices:")
        for d in listDevices(type: "input") { print("  \(d)") }
        print("\nOutput devices:")
        for d in listDevices(type: "output") { print("  \(d)") }

    case "--init":
        let config = Config.defaultConfig
        do {
            try config.save()
            print("Config written to \(Config.configFile.path)")
            print("Edit it to set your devices and hotkey.")
        } catch {
            fputs("Error writing config: \(error.localizedDescription)\n", stderr)
            exit(1)
        }

    case "--config":
        if FileManager.default.fileExists(atPath: Config.configFile.path) {
            let config = Config.load()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            if let data = try? encoder.encode(config),
               let json = String(data: data, encoding: .utf8) {
                print(json)
            }
        } else {
            print("No config found. Run with --init to create one.")
        }

    case "--help", "-h":
        print("""
        AudioSwitcher - Toggle between two audio devices from the menu bar.

        Usage:
          AudioSwitcher              Start the menu bar app
          AudioSwitcher --list-devices   List available audio devices
          AudioSwitcher --init           Create default config file
          AudioSwitcher --config         Show current config
          AudioSwitcher --help           Show this help

        Config: \(Config.configFile.path)
        Requires: SwitchAudioSource (brew install switchaudio-osx)
        """)

    default:
        fputs("Unknown argument: \(args[1]). Use --help for usage.\n", stderr)
        exit(1)
    }

    return true
}

// MARK: - Global Hotkey (Carbon)

var hotKeyRef: EventHotKeyRef?

func registerGlobalHotkey(config: Config) {
    var hotKeyID = EventHotKeyID()
    hotKeyID.signature = OSType(0x4153_5754) // "ASWT"
    hotKeyID.id = 1

    var eventType = EventTypeSpec(
        eventClass: OSType(kEventClassKeyboard),
        eventKind: UInt32(kEventHotKeyPressed)
    )

    let handler: EventHandlerUPP = { _, _, _ -> OSStatus in
        DispatchQueue.main.async {
            (NSApplication.shared.delegate as? AppDelegate)?.doToggle()
        }
        return noErr
    }

    InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, nil)
    RegisterEventHotKey(config.carbonKeyCode, config.carbonModifiers, hotKeyID,
                        GetApplicationEventTarget(), 0, &hotKeyRef)
}

// MARK: - Menu Bar App

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var config: Config!

    func applicationDidFinishLaunching(_ notification: Notification) {
        config = Config.load()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon()
        buildMenu()
        registerGlobalHotkey(config: config)

        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateIcon()
        }
    }

    func isPrimaryActive() -> Bool {
        let input = currentAudioDevice(type: "input")
        let output = currentAudioDevice(type: "output")
        return input == config.primaryInput || output == config.primaryOutput
    }

    func updateIcon() {
        if let button = statusItem.button {
            button.title = isPrimaryActive() ? "\u{1F3A7}" : "\u{1F5A5}"
        }
        buildMenu()
    }

    func buildMenu() {
        let menu = NSMenu()
        let primary = isPrimaryActive()

        let input = currentAudioDevice(type: "input")
        let output = currentAudioDevice(type: "output")

        let label = primary ? "Active: Primary" : "Active: Secondary"
        let statusEntry = NSMenuItem(title: label, action: nil, keyEquivalent: "")
        statusEntry.isEnabled = false
        menu.addItem(statusEntry)

        menu.addItem(NSMenuItem.separator())

        let inputItem = NSMenuItem(title: "Input:  \(input)", action: nil, keyEquivalent: "")
        inputItem.isEnabled = false
        menu.addItem(inputItem)

        let outputItem = NSMenuItem(title: "Output: \(output)", action: nil, keyEquivalent: "")
        outputItem.isEnabled = false
        menu.addItem(outputItem)

        menu.addItem(NSMenuItem.separator())

        let toggleItem = NSMenuItem(
            title: "Toggle (\(config.hotkeyDescription))",
            action: #selector(doToggle), keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(doQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc func doToggle() {
        if isPrimaryActive() {
            switchAudio(device: config.secondaryInput, type: "input")
            switchAudio(device: config.secondaryOutput, type: "output")
        } else {
            switchAudio(device: config.primaryInput, type: "input")
            switchAudio(device: config.primaryOutput, type: "output")
        }
        updateIcon()
    }

    @objc func doQuit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Main

guard let sasPath = findSwitchAudioSource() else {
    fputs("Error: SwitchAudioSource not found.\n", stderr)
    fputs("Install it: brew install switchaudio-osx\n", stderr)
    exit(1)
}
switchAudioSourcePath = sasPath

if handleCLI() { exit(0) }

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
