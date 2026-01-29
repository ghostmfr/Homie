import SwiftUI
import ServiceManagement

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            RulesSettingsView()
                .tabItem {
                    Label("Rules", systemImage: "bolt")
                }
            
            CLISettingsView()
                .tabItem {
                    Label("CLI", systemImage: "terminal")
                }
            
            SecuritySettingsView()
                .tabItem {
                    Label("Security", systemImage: "lock.shield")
                }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInDock") private var showInDock = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch Homie at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(enabled: newValue)
                    }
                
                Toggle("Show in Dock", isOn: $showInDock)
                    .help("Shows Homie icon in the Dock (requires restart)")
            } header: {
                Text("Startup")
            }
            
            Section {
                HStack {
                    Text("API Port")
                    Spacer()
                    Text("8420")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("API Address")
                    Spacer()
                    Text("127.0.0.1 (localhost only)")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("API Server")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private func setLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("[Settings] Failed to set launch at login: \(error)")
        }
    }
}

// MARK: - Rules Settings

struct RulesSettingsView: View {
    @EnvironmentObject var ruleEngine: RuleEngine
    @State private var showAddRule = false
    
    var body: some View {
        VStack {
            List {
                ForEach(ruleEngine.rules) { rule in
                    RuleRowView(rule: rule, ruleEngine: ruleEngine)
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        ruleEngine.deleteRule(id: ruleEngine.rules[index].id)
                    }
                }
            }
            
            HStack {
                Button(action: { showAddRule = true }) {
                    Label("Add Rule", systemImage: "plus")
                }
                
                Spacer()
                
                Text("\(ruleEngine.rules.count) rules")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
        }
        .sheet(isPresented: $showAddRule) {
            AddRuleView(ruleEngine: ruleEngine, isPresented: $showAddRule)
        }
    }
}

struct RuleRowView: View {
    let rule: HomieRule
    @ObservedObject var ruleEngine: RuleEngine
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(rule.name)
                        .fontWeight(.medium)
                    
                    if ruleEngine.activeRules.contains(rule.id) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                if let app = rule.conditions.app {
                    Text("App: \(app)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { rule.enabled },
                set: { newValue in
                    var updated = rule
                    updated.enabled = newValue
                    ruleEngine.updateRule(updated)
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

struct AddRuleView: View {
    @ObservedObject var ruleEngine: RuleEngine
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var appPattern = ""
    @State private var useTimeRange = false
    @State private var afterTime = "18:00"
    @State private var beforeTime = "23:00"
    @State private var revert = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New App-Aware Rule")
                .font(.headline)
            
            Form {
                TextField("Rule Name", text: $name)
                
                TextField("App Bundle ID", text: $appPattern)
                    .help("e.g., com.adobe.Lightroom* (supports wildcards)")
                
                Toggle("Time restriction", isOn: $useTimeRange)
                
                if useTimeRange {
                    HStack {
                        TextField("After", text: $afterTime)
                        TextField("Before", text: $beforeTime)
                    }
                }
                
                Toggle("Revert when app closes", isOn: $revert)
            }
            
            Text("Configure actions after creating the rule.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                
                Spacer()
                
                Button("Create") {
                    createRule()
                    isPresented = false
                }
                .disabled(name.isEmpty || appPattern.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
    
    private func createRule() {
        let timeRange: HomieRule.TimeRange? = useTimeRange 
            ? HomieRule.TimeRange(after: afterTime, before: beforeTime)
            : nil
        
        let rule = HomieRule(
            name: name,
            conditions: HomieRule.Conditions(
                app: appPattern,
                timeRange: timeRange
            ),
            actions: [],
            revert: revert,
            enabled: true
        )
        
        ruleEngine.addRule(rule)
    }
}

// MARK: - CLI Settings

struct CLISettingsView: View {
    @State private var cliInstalled = false
    @State private var installing = false
    
    private let cliPath = "/usr/local/bin/hkctl"
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: cliInstalled ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundColor(cliInstalled ? .green : .red)
                    
                    VStack(alignment: .leading) {
                        Text(cliInstalled ? "CLI Installed" : "CLI Not Installed")
                            .fontWeight(.medium)
                        Text(cliPath)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if installing {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Button(cliInstalled ? "Reinstall" : "Install") {
                            installCLI()
                        }
                    }
                }
            } header: {
                Text("hkctl Command Line Tool")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Usage Examples:")
                        .fontWeight(.medium)
                    
                    CodeBlock("hkctl list")
                    CodeBlock("hkctl toggle \"Office Lamp\"")
                    CodeBlock("hkctl set \"Bedroom\" 50")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            checkCLIInstalled()
        }
    }
    
    private func checkCLIInstalled() {
        cliInstalled = FileManager.default.fileExists(atPath: cliPath)
    }
    
    private func installCLI() {
        installing = true
        
        // In a real implementation, this would:
        // 1. Build the CLI if needed
        // 2. Prompt for admin password
        // 3. Copy to /usr/local/bin
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            installing = false
            checkCLIInstalled()
        }
    }
}

struct CodeBlock: View {
    let code: String
    
    init(_ code: String) {
        self.code = code
    }
    
    var body: some View {
        Text(code)
            .font(.system(.caption, design: .monospaced))
            .padding(8)
            .background(Color.black.opacity(0.05))
            .cornerRadius(4)
    }
}

// MARK: - Security Settings

struct SecuritySettingsView: View {
    @EnvironmentObject var homieState: HomieState
    @AppStorage("allowLAN") private var allowLAN = false
    @AppStorage("lanAPIKey") private var lanAPIKey = ""
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: homieState.securityCompromised ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                        .foregroundColor(homieState.securityCompromised ? .red : .green)
                        .font(.title)
                    
                    VStack(alignment: .leading) {
                        Text(homieState.securityCompromised ? "EXPOSED" : "Secure")
                            .font(.headline)
                            .foregroundColor(homieState.securityCompromised ? .red : .green)
                        
                        Text(homieState.securityCompromised 
                             ? "Port 8420 is exposed to the internet!"
                             : "API bound to localhost only")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Status")
            }
            
            Section {
                Toggle("Allow LAN access", isOn: $allowLAN)
                    .help("Allow connections from local network (10.x.x.x, 192.168.x.x)")
                
                if allowLAN {
                    SecureField("API Key", text: $lanAPIKey)
                        .help("Required for LAN access")
                    
                    Button("Generate New Key") {
                        lanAPIKey = UUID().uuidString
                    }
                }
            } header: {
                Text("Local Network")
            } footer: {
                if allowLAN {
                    Text("LAN mode allows access from devices on your local network with the API key.")
                }
            }
            
            Section {
                Text("Homie performs security checks on startup and every 5 minutes to ensure the API port is not exposed to the internet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
