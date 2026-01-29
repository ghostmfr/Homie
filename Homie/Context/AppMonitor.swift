import AppKit
import Combine

/// Monitors the frontmost application and notifies when it changes
class AppMonitor: ObservableObject {
    @Published var currentApp: RunningApp?
    
    var onAppChange: ((String, String) -> Void)?
    
    private var observer: NSObjectProtocol?
    private var lastBundleId: String?
    
    struct RunningApp {
        let bundleIdentifier: String
        let name: String
        let pid: pid_t
    }
    
    func start() {
        // Get initial state
        updateCurrentApp()
        
        // Listen for app activation changes
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppActivation(notification)
        }
        
        NSLog("[AppMonitor] Started monitoring frontmost app")
    }
    
    func stop() {
        if let observer = observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observer = nil
        NSLog("[AppMonitor] Stopped monitoring")
    }
    
    private func updateCurrentApp() {
        guard let frontmost = NSWorkspace.shared.frontmostApplication else { return }
        
        let bundleId = frontmost.bundleIdentifier ?? "unknown"
        let appName = frontmost.localizedName ?? "Unknown"
        
        currentApp = RunningApp(
            bundleIdentifier: bundleId,
            name: appName,
            pid: frontmost.processIdentifier
        )
    }
    
    private func handleAppActivation(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        let bundleId = app.bundleIdentifier ?? "unknown"
        let appName = app.localizedName ?? "Unknown"
        
        // Only fire if app actually changed
        if bundleId != lastBundleId {
            lastBundleId = bundleId
            
            currentApp = RunningApp(
                bundleIdentifier: bundleId,
                name: appName,
                pid: app.processIdentifier
            )
            
            NSLog("[AppMonitor] App changed: \(appName) (\(bundleId))")
            onAppChange?(bundleId, appName)
        }
    }
}

// MARK: - App Matching Helpers

extension AppMonitor {
    /// Check if a bundle ID matches a pattern (supports wildcards)
    static func matches(bundleId: String, pattern: String) -> Bool {
        if pattern.hasSuffix("*") {
            let prefix = String(pattern.dropLast())
            return bundleId.hasPrefix(prefix)
        } else if pattern.hasPrefix("*") {
            let suffix = String(pattern.dropFirst())
            return bundleId.hasSuffix(suffix)
        } else {
            return bundleId == pattern
        }
    }
}
