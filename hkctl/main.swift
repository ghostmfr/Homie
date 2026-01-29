#!/usr/bin/env swift

import Foundation

let baseURL = "http://127.0.0.1:8420"

// MARK: - Models

struct Device: Codable {
    let id: String
    let name: String
    let room: String?
    let type: String
    let isOn: Bool
    let brightness: Int?
}

struct Scene: Codable {
    let id: String
    let name: String
    let home: String
    let actions: Int
}

struct DevicesResponse: Codable {
    let devices: [Device]
}

struct ScenesResponse: Codable {
    let scenes: [Scene]
}

struct ActionResponse: Codable {
    let success: Bool?
    let device: Device?
    let error: String?
}

// MARK: - HTTP Client

func request(_ method: String, _ path: String, body: [String: Any]? = nil) -> Data? {
    guard let url = URL(string: baseURL + path) else { return nil }
    
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.timeoutInterval = 10
    
    if let body = body {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    }
    
    let semaphore = DispatchSemaphore(value: 0)
    var result: Data?
    
    URLSession.shared.dataTask(with: request) { data, _, error in
        result = error == nil ? data : nil
        semaphore.signal()
    }.resume()
    
    _ = semaphore.wait(timeout: .now() + 15)
    return result
}

// MARK: - Commands

func listDevices() {
    guard let data = request("GET", "/devices"),
          let response = try? JSONDecoder().decode(DevicesResponse.self, from: data) else {
        print("❌ Failed to connect to Homie. Is the app running?")
        exit(1)
    }
    
    if response.devices.isEmpty {
        print("No devices found.")
        return
    }
    
    print("📱 HomeKit Devices:\n")
    
    // Group by room
    let grouped = Dictionary(grouping: response.devices) { $0.room ?? "No Room" }
    for (room, devices) in grouped.sorted(by: { $0.key < $1.key }) {
        print("  \(room):")
        for device in devices.sorted(by: { $0.name < $1.name }) {
            let status = device.isOn ? "🟢" : "⚪️"
            let brightness = device.brightness.map { " (\($0)%)" } ?? ""
            print("    \(status) \(device.name)\(brightness)")
        }
        print("")
    }
    
    print("Total: \(response.devices.count) devices")
}

func listScenes() {
    guard let data = request("GET", "/scenes"),
          let response = try? JSONDecoder().decode(ScenesResponse.self, from: data) else {
        print("❌ Failed to connect to Homie. Is the app running?")
        exit(1)
    }
    
    if response.scenes.isEmpty {
        print("No scenes found.")
        return
    }
    
    print("🎬 HomeKit Scenes:\n")
    for scene in response.scenes {
        print("  • \(scene.name) (\(scene.actions) actions)")
    }
    print("\nTotal: \(response.scenes.count) scenes")
}

func getStatus(_ name: String) {
    let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
    guard let data = request("GET", "/device/\(encoded)"),
          let device = try? JSONDecoder().decode(Device.self, from: data) else {
        print("❌ Device '\(name)' not found")
        exit(1)
    }
    
    print("📱 \(device.name)")
    print("   Status: \(device.isOn ? "🟢 ON" : "⚪️ OFF")")
    if let brightness = device.brightness {
        print("   Brightness: \(brightness)%")
    }
    if let room = device.room {
        print("   Room: \(room)")
    }
}

func toggleDevice(_ name: String) {
    let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
    guard let data = request("POST", "/device/\(encoded)/toggle"),
          let response = try? JSONDecoder().decode(ActionResponse.self, from: data) else {
        print("❌ Failed to toggle '\(name)'")
        exit(1)
    }
    
    if response.success == true {
        if let device = response.device {
            print("✅ \(device.name) → \(device.isOn ? "ON 🟢" : "OFF ⚪️")")
        } else {
            print("✅ Toggled '\(name)'")
        }
    } else {
        print("❌ \(response.error ?? "Unknown error")")
        exit(1)
    }
}

func setDevice(_ name: String, on: Bool) {
    let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
    guard let data = request("POST", "/device/\(encoded)/set", body: ["on": on]),
          let response = try? JSONDecoder().decode(ActionResponse.self, from: data) else {
        print("❌ Failed to set '\(name)'")
        exit(1)
    }
    
    if response.success == true {
        print("✅ \(name) → \(on ? "ON 🟢" : "OFF ⚪️")")
    } else {
        print("❌ \(response.error ?? "Unknown error")")
        exit(1)
    }
}

func setBrightness(_ name: String, _ level: Int) {
    let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
    guard let data = request("POST", "/device/\(encoded)/set", body: ["on": true, "brightness": level]),
          let response = try? JSONDecoder().decode(ActionResponse.self, from: data) else {
        print("❌ Failed to set brightness for '\(name)'")
        exit(1)
    }
    
    if response.success == true {
        print("✅ \(name) → \(level)%")
    } else {
        print("❌ \(response.error ?? "Unknown error")")
        exit(1)
    }
}

func triggerScene(_ name: String) {
    let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
    guard let data = request("POST", "/scene/\(encoded)/trigger"),
          let response = try? JSONDecoder().decode(ActionResponse.self, from: data) else {
        print("❌ Failed to trigger scene '\(name)'")
        exit(1)
    }
    
    if response.success == true {
        print("✅ Scene '\(name)' triggered")
    } else {
        print("❌ \(response.error ?? "Scene not found")")
        exit(1)
    }
}

func showStatus() {
    guard let data = request("GET", "/debug"),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        print("❌ Failed to connect to Homie. Is the app running?")
        exit(1)
    }
    
    let devices = json["devicesLoaded"] as? Int ?? 0
    let scenes = json["scenesLoaded"] as? Int ?? 0
    let activeRules = json["activeRules"] as? [String] ?? []
    
    print("🏠 Homie Status")
    print("   Devices: \(devices)")
    print("   Scenes: \(scenes)")
    print("   Active Rules: \(activeRules.isEmpty ? "None" : activeRules.joined(separator: ", "))")
    print("   API: http://127.0.0.1:8420")
}

func printUsage() {
    print("""
    hkctl - Homie CLI
    
    Usage:
      hkctl list                    List all devices (grouped by room)
      hkctl scenes                  List all scenes
      hkctl status <name>           Get device status
      hkctl toggle <name>           Toggle device on/off
      hkctl on <name>               Turn device on
      hkctl off <name>              Turn device off
      hkctl set <name> <0-100>      Set brightness level
      hkctl scene <name>            Trigger a scene
      hkctl info                    Show Homie status
      hkctl help                    Show this help
    
    Device/scene names support fuzzy matching.
    
    Examples:
      hkctl toggle "Office Lamp"
      hkctl on office
      hkctl set kitchen 50
      hkctl scene "Good Night"
    """)
}

// MARK: - Main

let args = Array(CommandLine.arguments.dropFirst())

guard !args.isEmpty else {
    printUsage()
    exit(0)
}

switch args[0].lowercased() {
case "list", "ls", "devices":
    listDevices()
    
case "scenes":
    listScenes()
    
case "status", "get":
    guard args.count > 1 else {
        print("Usage: hkctl status <device-name>")
        exit(1)
    }
    getStatus(args[1...].joined(separator: " "))
    
case "toggle":
    guard args.count > 1 else {
        print("Usage: hkctl toggle <device-name>")
        exit(1)
    }
    toggleDevice(args[1...].joined(separator: " "))
    
case "on":
    guard args.count > 1 else {
        print("Usage: hkctl on <device-name>")
        exit(1)
    }
    setDevice(args[1...].joined(separator: " "), on: true)
    
case "off":
    guard args.count > 1 else {
        print("Usage: hkctl off <device-name>")
        exit(1)
    }
    setDevice(args[1...].joined(separator: " "), on: false)
    
case "set":
    guard args.count > 2, let level = Int(args.last!) else {
        print("Usage: hkctl set <device-name> <0-100>")
        exit(1)
    }
    let name = args[1..<(args.count-1)].joined(separator: " ")
    setBrightness(name, max(0, min(100, level)))
    
case "scene":
    guard args.count > 1 else {
        print("Usage: hkctl scene <scene-name>")
        exit(1)
    }
    triggerScene(args[1...].joined(separator: " "))
    
case "info", "status-all":
    showStatus()
    
case "help", "-h", "--help":
    printUsage()
    
default:
    print("Unknown command: \(args[0])")
    printUsage()
    exit(1)
}
