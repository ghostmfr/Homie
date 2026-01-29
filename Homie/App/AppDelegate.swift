import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    let homeKitManager = HomeKitManager()
    let appMonitor = AppMonitor()
    let ruleEngine: RuleEngine
    let homieState = HomieState()
    var httpServer: HTTPServer?
    
    override init() {
        self.ruleEngine = RuleEngine(homeKitManager: homeKitManager)
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request HomeKit authorization
        homeKitManager.requestAuthorization { [weak self] success in
            if success {
                self?.homeKitManager.loadDevices()
                self?.homeKitManager.loadScenes()
            }
        }
        
        // Start HTTP server
        httpServer = HTTPServer(homeKitManager: homeKitManager, ruleEngine: ruleEngine)
        httpServer?.start()
        
        // Start app monitoring for context-aware scenes
        appMonitor.onAppChange = { [weak self] bundleId, appName in
            self?.ruleEngine.evaluateAppChange(bundleId: bundleId, appName: appName)
        }
        appMonitor.start()
        
        // Security check
        performSecurityAudit()
        
        // Schedule periodic security checks
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.performSecurityAudit()
        }
        
        NSLog("[Homie] Started successfully")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        httpServer?.stop()
        appMonitor.stop()
    }
    
    private func performSecurityAudit() {
        SecurityAuditor.checkPortExposure(port: 8420) { [weak self] isExposed in
            DispatchQueue.main.async {
                self?.homieState.securityCompromised = isExposed
                if isExposed {
                    NSLog("[Homie] ⚠️ SECURITY WARNING: Port 8420 appears to be exposed!")
                }
            }
        }
    }
}

// MARK: - Homie State

class HomieState: ObservableObject {
    @Published var securityCompromised: Bool = false
    @Published var currentMood: HomieCharacter.Mood = .happy
    @Published var isProcessing: Bool = false
    
    var effectiveMood: HomieCharacter.Mood {
        if securityCompromised { return .angry }
        if isProcessing { return .thinking }
        return currentMood
    }
}

// MARK: - Security Auditor

struct SecurityAuditor {
    static func checkPortExposure(port: UInt16, completion: @escaping (Bool) -> Void) {
        // Check if port is bound to anything other than localhost
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        task.arguments = ["-i", ":\(port)", "-P", "-n"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            // Check if bound to 0.0.0.0 or any non-localhost address
            let isExposed = output.contains("*:8420") || 
                           output.contains("0.0.0.0:8420") ||
                           (output.contains(":8420") && !output.contains("127.0.0.1:8420") && !output.contains("localhost:8420"))
            
            completion(isExposed)
        } catch {
            completion(false)
        }
    }
}
