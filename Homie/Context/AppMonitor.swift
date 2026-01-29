import Foundation
import Combine
import CoreGraphics

/// Monitors the frontmost application using CoreGraphics window APIs
/// Works on Mac Catalyst without special permissions
class AppMonitor: ObservableObject {
    @Published var currentApp: RunningApp?
    @Published var currentAppName: String?
    
    var onAppChange: ((String, String) -> Void)?
    
    private var timer: Timer?
    private var lastAppName: String?
    
    struct RunningApp: Equatable {
        let bundleIdentifier: String
        let name: String
    }
    
    func start() {
        // Initial check
        checkFrontmostApp()
        
        // Poll every 1.5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.checkFrontmostApp()
        }
        
        NSLog("[AppMonitor] Started polling frontmost app via CGWindowList")
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        NSLog("[AppMonitor] Stopped")
    }
    
    private func checkFrontmostApp() {
        guard let appName = getFrontmostAppName() else { return }
        
        // Only fire if changed
        if appName != lastAppName {
            lastAppName = appName
            
            // Use app name as identifier (bundle ID not easily available in Catalyst)
            // Rules can match on app name or common bundle ID patterns
            let bundleId = appNameToBundleId(appName)
            
            currentAppName = appName
            currentApp = RunningApp(bundleIdentifier: bundleId, name: appName)
            
            NSLog("[AppMonitor] App changed: \(appName) (\(bundleId))")
            onAppChange?(bundleId, appName)
        }
    }
    
    private func getFrontmostAppName() -> String? {
        // Get list of on-screen windows
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        
        // Find the frontmost window (layer 0, not menubar/dock)
        for window in windowList {
            guard let layer = window[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let ownerName = window[kCGWindowOwnerName as String] as? String else {
                continue
            }
            
            // Skip our own app and system processes
            if ownerName == "Homie" || ownerName == "Dock" || ownerName == "Window Server" {
                continue
            }
            
            return ownerName
        }
        
        return nil
    }
    
    /// Convert app name to likely bundle ID for rule matching
    private func appNameToBundleId(_ name: String) -> String {
        // Common app mappings
        let knownApps: [String: String] = [
            "Safari": "com.apple.Safari",
            "Finder": "com.apple.finder",
            "Mail": "com.apple.mail",
            "Messages": "com.apple.MobileSMS",
            "Notes": "com.apple.Notes",
            "Calendar": "com.apple.iCal",
            "Music": "com.apple.Music",
            "Photos": "com.apple.Photos",
            "Preview": "com.apple.Preview",
            "Terminal": "com.apple.Terminal",
            "Xcode": "com.apple.dt.Xcode",
            "Visual Studio Code": "com.microsoft.VSCode",
            "Code": "com.microsoft.VSCode",
            "Slack": "com.tinyspeck.slackmacgap",
            "Discord": "com.hnc.Discord",
            "Zoom": "us.zoom.xos",
            "zoom.us": "us.zoom.xos",
            "Google Chrome": "com.google.Chrome",
            "Firefox": "org.mozilla.firefox",
            "Spotify": "com.spotify.client",
            "Adobe Lightroom": "com.adobe.LightroomClassicCC7",
            "Lightroom Classic": "com.adobe.LightroomClassicCC7",
            "Adobe Photoshop": "com.adobe.Photoshop",
            "Photoshop": "com.adobe.Photoshop",
            "Logic Pro": "com.apple.logic10",
            "Final Cut Pro": "com.apple.FinalCut",
            "Figma": "com.figma.Desktop",
            "Notion": "notion.id",
            "Raycast": "com.raycast.macos",
            "Arc": "company.thebrowser.Browser",
            "Obsidian": "md.obsidian",
            "1Password": "com.1password.1password",
        ]
        
        if let bundleId = knownApps[name] {
            return bundleId
        }
        
        // Generate a likely bundle ID
        let sanitized = name.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
        return "com.unknown.\(sanitized)"
    }
    
    // MARK: - Utilities
    
    /// Check if a bundle ID or app name matches a pattern (supports wildcards)
    static func matches(bundleId: String, pattern: String) -> Bool {
        let bundleLower = bundleId.lowercased()
        let patternLower = pattern.lowercased()
        
        if patternLower.hasSuffix("*") {
            let prefix = String(patternLower.dropLast())
            return bundleLower.hasPrefix(prefix)
        } else if patternLower.hasPrefix("*") {
            let suffix = String(patternLower.dropFirst())
            return bundleLower.hasSuffix(suffix)
        } else {
            return bundleLower == patternLower
        }
    }
    
    /// Check if app name matches a pattern
    static func matchesName(appName: String, pattern: String) -> Bool {
        let nameLower = appName.lowercased()
        let patternLower = pattern.lowercased()
        
        if patternLower.hasSuffix("*") {
            let prefix = String(patternLower.dropLast())
            return nameLower.hasPrefix(prefix)
        } else if patternLower.hasPrefix("*") {
            let suffix = String(patternLower.dropFirst())
            return nameLower.hasSuffix(suffix)
        } else {
            return nameLower.contains(patternLower)
        }
    }
}
