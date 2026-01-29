import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    let homeKitManager = HomeKitManager()
    let appMonitor = AppMonitor()
    let ruleEngine: RuleEngine
    let homieState = HomieState()
    var httpServer: HTTPServer?
    
    override init() {
        self.ruleEngine = RuleEngine(homeKitManager: homeKitManager)
        super.init()
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Request HomeKit authorization
        homeKitManager.requestAuthorization { [weak self] success in
            if success {
                self?.homeKitManager.loadDevices()
                self?.homeKitManager.loadScenes()
            }
        }
        
        // Wire up server toggle
        homieState.onToggleServer = { [weak self] in
            self?.toggleServer()
        }
        
        // Start HTTP server (if auto-launch enabled)
        httpServer = HTTPServer(homeKitManager: homeKitManager, ruleEngine: ruleEngine, homieState: homieState)
        if homieState.autoLaunchServer {
            httpServer?.start()
            homieState.serverRunning = true
        } else {
            homieState.serverRunning = false
        }
        
        // Start app monitoring (limited in Catalyst)
        appMonitor.onAppChange = { [weak self] bundleId, appName in
            self?.ruleEngine.evaluateAppChange(bundleId: bundleId, appName: appName)
        }
        appMonitor.start()
        
        // Apply dock visibility preference
        homieState.applyDockVisibility()
        
        NSLog("[lil homie] Started successfully")
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        httpServer?.stop()
        appMonitor.stop()
    }
    
    func toggleServer() {
        if homieState.serverRunning {
            httpServer?.stop()
            homieState.serverRunning = false
        } else {
            httpServer?.start()
            homieState.serverRunning = true
        }
    }
}

// MARK: - Scene Delegate

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        #if targetEnvironment(macCatalyst)
        // Lock window size
        let fixedSize = CGSize(width: 380, height: 600)
        windowScene.sizeRestrictions?.minimumSize = fixedSize
        windowScene.sizeRestrictions?.maximumSize = fixedSize
        
        // Hide title bar for cleaner look
        if let titlebar = windowScene.titlebar {
            titlebar.titleVisibility = .hidden
            titlebar.toolbar = nil
        }
        #endif
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Don't quit - keep server running in background
    }
}

// Keep app running when all windows closed
extension AppDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: Any) -> Bool {
        return false
    }
}

// MARK: - Homie State

class HomieState: ObservableObject {
    @Published var securityCompromised: Bool = false
    @Published var currentMood: HomieCharacter.Mood = .happy
    @Published var isProcessing: Bool = false
    @Published var requestCount: Int = 0
    @Published var port: UInt16 = 8420
    @Published var serverRunning: Bool = true
    
    // Callback to toggle server (set by AppDelegate)
    var onToggleServer: (() -> Void)?
    
    // Auto-launch preference
    @AppStorage("autoLaunchServer") var autoLaunchServer: Bool = true
    
    // Hide from dock preference  
    @AppStorage("hideFromDock") var hideFromDock: Bool = false {
        didSet {
            applyDockVisibility()
        }
    }
    
    func applyDockVisibility() {
        #if targetEnvironment(macCatalyst)
        // Access NSApplication through dynamic loading
        guard let nsAppClass = NSClassFromString("NSApplication") as? NSObject.Type,
              let sharedApp = nsAppClass.value(forKey: "sharedApplication") as? NSObject else {
            return
        }
        // setActivationPolicy: 0 = regular (dock), 1 = accessory (no dock), 2 = prohibited
        let policy = hideFromDock ? 1 : 0
        sharedApp.perform(Selector(("setActivationPolicy:")), with: policy)
        #endif
    }
    
    var effectiveMood: HomieCharacter.Mood {
        if securityCompromised { return .angry }
        if isProcessing { return .thinking }
        return currentMood
    }
    
    func incrementRequestCount() {
        DispatchQueue.main.async {
            self.requestCount += 1
        }
    }
    
    func toggleServer() {
        onToggleServer?()
    }
}
