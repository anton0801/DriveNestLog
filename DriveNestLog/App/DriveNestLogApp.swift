import SwiftUI
import UserNotifications

@main
struct DriveNestLogApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var dataStore = DataStore.shared

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegateApp
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(appState)
                .environmentObject(dataStore)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if !appState.isAuthenticated {
                AuthView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                MainTabView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .onAppear {
                        if appState.notificationsEnabled {
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: appState.isAuthenticated)
        .preferredColorScheme(appState.colorScheme)
    }
}
