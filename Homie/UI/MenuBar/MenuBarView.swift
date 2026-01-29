import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var homeKitManager: HomeKitManager
    @EnvironmentObject var ruleEngine: RuleEngine
    @EnvironmentObject var homieState: HomieState
    
    @State private var selectedRoom: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Homie
            headerView
            
            Divider()
            
            // Security warning if needed
            if homieState.securityCompromised {
                securityWarning
                Divider()
            }
            
            // Active rules indicator
            if !ruleEngine.activeRules.isEmpty {
                activeRulesView
                Divider()
            }
            
            // Devices list
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(filteredDevices) { device in
                        DeviceRow(device: device, homeKitManager: homeKitManager)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 300)
            
            Divider()
            
            // Room filter
            roomFilterView
            
            Divider()
            
            // Footer
            footerView
        }
        .frame(width: 280)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            HomieCharacter(mood: homieState.effectiveMood, size: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Homie")
                    .font(.headline)
                
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { homeKitManager.loadDevices() }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .help("Refresh devices")
        }
        .padding(12)
    }
    
    private var statusText: String {
        let onCount = homeKitManager.devices.filter { $0.isOn }.count
        if onCount == 0 {
            return "All lights off"
        } else if onCount == 1 {
            return "1 light on"
        } else {
            return "\(onCount) lights on"
        }
    }
    
    // MARK: - Security Warning
    
    private var securityWarning: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text("Port exposed to internet!")
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding(8)
        .background(Color.red.opacity(0.1))
    }
    
    // MARK: - Active Rules
    
    private var activeRulesView: some View {
        HStack {
            Image(systemName: "bolt.fill")
                .foregroundColor(.yellow)
            
            let activeNames = ruleEngine.rules
                .filter { ruleEngine.activeRules.contains($0.id) }
                .map { $0.name }
                .joined(separator: ", ")
            
            Text(activeNames)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
    
    // MARK: - Room Filter
    
    private var roomFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                roomChip(room: nil, label: "All")
                
                ForEach(rooms, id: \.self) { room in
                    roomChip(room: room, label: room)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
    
    private func roomChip(room: String?, label: String) -> some View {
        Button(action: { selectedRoom = room }) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(selectedRoom == room ? Color.accentColor : Color.secondary.opacity(0.2))
                .foregroundColor(selectedRoom == room ? .white : .primary)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private var rooms: [String] {
        Set(homeKitManager.devices.compactMap { $0.roomName }).sorted()
    }
    
    private var filteredDevices: [HomeDevice] {
        if let room = selectedRoom {
            return homeKitManager.devices.filter { $0.roomName == room }
        }
        return homeKitManager.devices
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            Button("Settings...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
        }
        .font(.caption)
        .padding(12)
    }
}

// MARK: - Device Row

struct DeviceRow: View {
    let device: HomeDevice
    @ObservedObject var homeKitManager: HomeKitManager
    @State private var isToggling = false
    
    var body: some View {
        Button(action: toggleDevice) {
            HStack {
                Circle()
                    .fill(device.isOn ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(device.name)
                        .font(.system(size: 13))
                    
                    if let room = device.roomName {
                        Text(room)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let brightness = device.brightness, device.isOn {
                    Text("\(brightness)%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if isToggling {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: device.isOn ? "lightbulb.fill" : "lightbulb")
                        .foregroundColor(device.isOn ? .yellow : .secondary)
                        .frame(width: 16)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isToggling)
    }
    
    private func toggleDevice() {
        isToggling = true
        homeKitManager.toggleDevice(device) { _ in
            DispatchQueue.main.async {
                isToggling = false
            }
        }
    }
}
