import SwiftUI
import HomeKit

@main
struct HomieApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appDelegate.homeKitManager)
                .environmentObject(appDelegate.ruleEngine)
        }
        
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appDelegate.homeKitManager)
                .environmentObject(appDelegate.ruleEngine)
                .environmentObject(appDelegate.homieState)
        } label: {
            HomieMenuBarLabel()
                .environmentObject(appDelegate.homieState)
        }
    }
}

struct HomieMenuBarLabel: View {
    @EnvironmentObject var homieState: HomieState
    
    var body: some View {
        Image(systemName: homieState.securityCompromised ? "house.fill" : "house")
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(homieState.securityCompromised ? .red : .primary)
    }
}
