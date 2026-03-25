import SwiftUI
import UserNotifications

@main
struct DriveNestLogApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var dataStore = DataStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(dataStore)
                .preferredColorScheme(appState.colorScheme)
                .onAppear {
                    // Request notification permissions on launch if enabled
                    if appState.notificationsEnabled {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
                    }
                }
        }
    }
}

// MARK: - Root View (handles routing: Splash → Onboarding → Auth → App)
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var splashDone = false

    var body: some View {
        ZStack {
            if !splashDone {
                SplashView(onFinished: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        splashDone = true
                    }
                })
                .transition(.opacity)
            } else if !appState.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if !appState.isAuthenticated {
                AuthView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                MainTabView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: splashDone)
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: appState.isAuthenticated)
    }
}
