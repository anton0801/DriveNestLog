import SwiftUI
import Combine
import Network

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var carOffset: CGFloat = -200
    @State private var chickenScale: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var particleOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var rotationAngle: Double = 0
    
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    
    @StateObject private var store: DriveNestStore
    @State private var networkMonitor = NWPathMonitor()
    @State private var cancellables = Set<AnyCancellable>()
    
    init() {
        let storage = UserDefaultsStorageService()
        let validation = FirebaseValidationService()
        let network = HTTPNetworkService()
        let notification = SystemNotificationService()
        
        _store = StateObject(wrappedValue: DriveNestStore(
            storage: storage,
            validation: validation,
            network: network,
            notification: notification
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.dnBackground.ignoresSafeArea()
                
                GeometryReader { geometry in
                    Image(geometry.size.width > geometry.size.height ? "inet_wifi_bg_l" : "inet_wifi_bg")
                        .resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                        .blur(radius: 10)
                }
                .ignoresSafeArea()
                .opacity(0.4)
                
                // Animated background particles
                ForEach(0..<12, id: \.self) { i in
                    ParticleView(index: i, opacity: particleOpacity)
                }
                
                // Radial glow
                RadialGradient(
                    colors: [Color.dnAccentBlue.opacity(0.15), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: glowRadius
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.5), value: glowRadius)
                
                VStack(spacing: DNSpacing.lg) {
                    Spacer()
                    
                    // Logo area
                    ZStack {
                        // Glow ring
                        Circle()
                            .stroke(
                                LinearGradient(colors: [Color.dnAccentBlue.opacity(0.5), Color.dnAccentOrange.opacity(0.3)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1.5
                            )
                            .frame(width: 130, height: 130)
                            .rotationEffect(.degrees(rotationAngle))
                        
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.dnCard, Color.dnCardElevated],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                            .dnShadow(color: .dnAccentBlue.opacity(0.3), radius: 20)
                        
                        // Car silhouette
                        VStack(spacing: -4) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 42))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.dnAccentBlue, Color.dnAccentOrange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .offset(x: carOffset)
                            
//                            // Chicken mascot
//                            Text("🐔")
//                                .font(.system(size: 22))
//                                .scaleEffect(chickenScale)
//                                .offset(x: 18, y: -2)
                        }
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    // App name
                    VStack(spacing: 6) {
                        HStack(spacing: 0) {
                            Text("Drive")
                                .font(DNFont.display(34))
                                .foregroundColor(.dnText)
                            Text("Nest")
                                .font(DNFont.display(34))
                                .foregroundColor(.dnAccentBlue)
                            Text(" Log")
                                .font(DNFont.display(34))
                                .foregroundColor(.dnAccentOrange)
                        }
                        
                        Text("Your smart car")
                            .font(DNFont.body(15))
                            .foregroundColor(.dnTextSecondary)
                            .tracking(1.5)
                    }
                    .opacity(textOpacity)
                    
                    Spacer()
                    
                    // Loading indicator
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { i in
                            LoadingDot(delay: Double(i) * 0.2, opacity: textOpacity)
                        }
                    }
                    .padding(.bottom, DNSpacing.xxl)
                }
                
                NavigationLink(
                    destination: DriveNestWebView().navigationBarHidden(true),
                    isActive: .constant(store.state.ui.navigateToWeb)
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: .constant(store.state.ui.navigateToMain)
                ) { EmptyView() }
            }
            .onAppear {
                startAnimation()
                setupStreams()
                setupNetworkMonitoring()
                Task {
                    await store.process(.initialize)
                }
            }
            .fullScreenCover(isPresented: .constant(store.state.ui.showPermissionPrompt)) {
                DriveNestNotificationView(store: store)
            }
            .fullScreenCover(isPresented: .constant(store.state.ui.showOfflineView)) {
                UnavailableView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                Task {
                    await store.process(.trackingDataReceived(data))
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                Task {
                    await store.process(.navigationDataReceived(data))
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                if path.status == .satisfied {
                    await store.process(.networkConnected)
                } else {
                    await store.process(.networkDisconnected)
                }
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
    private func startAnimation() {
        // Particles
        withAnimation(.easeIn(duration: 0.5)) {
            particleOpacity = 1
        }
        
        // Glow
        withAnimation(.easeInOut(duration: 2).delay(0.2)) {
            glowRadius = 300
        }
        
        // Logo scale in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.3)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Car drives in
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.7)) {
            carOffset = 0
        }
        
        // Chicken pops up
        withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(1.1)) {
            chickenScale = 1.0
        }
        
        // Text fades in
        withAnimation(.easeIn(duration: 0.5).delay(1.3)) {
            textOpacity = 1.0
        }
        
        // Ring rotation
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
    }
}

struct ParticleView: View {
    let index: Int
    let opacity: Double
    
    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    
    private var startX: CGFloat { CGFloat.random(in: -180...180) }
    private var startY: CGFloat { CGFloat.random(in: -350...350) }
    private var size: CGFloat { CGFloat.random(in: 3...8) }
    private var color: Color { [Color.dnAccentBlue, Color.dnAccentOrange, Color.dnGreen].randomElement()! }
    
    var body: some View {
        Circle()
            .fill(color.opacity(0.4))
            .frame(width: size, height: size)
            .offset(x: startX + offsetX, y: startY + offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: Double.random(in: 2...4)).repeatForever(autoreverses: true)) {
                    offsetY = CGFloat.random(in: -30...30)
                    offsetX = CGFloat.random(in: -20...20)
                }
            }
    }
}

struct LoadingDot: View {
    let delay: Double
    let opacity: Double
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        Circle()
            .fill(Color.dnAccentBlue)
            .frame(width: 7, height: 7)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(delay)) {
                    scale = 1.0
                }
            }
    }
}

struct DriveNestNotificationView: View {
    let store: DriveNestStore
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(geometry.size.width > geometry.size.height ? "main_p_bg_l" : "main_p_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.custom("MadimiOne-Regular", size: 24))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.custom("MadimiOne-Regular", size: 16))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await store.process(.requestNotificationPermission)
                }
            } label: {
                Image("main_p_bg_btn")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                store.processSync(.deferNotificationPermission)
            } label: {
                Text("Skip")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
    }
}

struct UnavailableView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(geometry.size.width > geometry.size.height ? "inet_wifi_bg_l" : "inet_wifi_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                
                Image("inet_wifi_alert")
                    .resizable()
                    .frame(width: 250, height: 220)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
}
