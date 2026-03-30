import SwiftUI
import WebKit

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedTab = 0
    @State private var tabScales: [CGFloat] = [1, 1, 1, 1, 1]
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                GarageView()
                    .tag(1)
                ExpenseTrackerView()
                    .tag(2)
                AnalyticsView()
                    .tag(3)
                ProfileView()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab, tabScales: $tabScales)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var tabScales: [CGFloat]
    
    let tabs: [(icon: String, title: String)] = [
        ("gauge.high", "Dashboard"),
        ("car.2.fill", "Garage"),
        ("creditcard.fill", "Expenses"),
        ("chart.bar.fill", "Analytics"),
        ("person.fill", "Profile")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { idx, tab in
                Button(action: {
                    withAnimation(.dnFast) {
                        selectedTab = idx
                        tabScales[idx] = 0.85
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.dnSpring) { tabScales[idx] = 1.0 }
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22))
                            .foregroundColor(selectedTab == idx ? .dnAccentBlue : .dnTextSecondary)
                            .scaleEffect(tabScales[idx])
                        
                        Text(tab.title)
                            .font(DNFont.label(10))
                            .foregroundColor(selectedTab == idx ? .dnAccentBlue : .dnTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedTab == idx ?
                        Color.dnAccentBlue.opacity(0.1) : Color.clear
                    )
                    .cornerRadius(DNRadius.md)
                    .padding(.horizontal, 4)
                    .animation(.dnFast, value: selectedTab)
                }
            }
        }
        .padding(.horizontal, DNSpacing.sm)
        .padding(.top, DNSpacing.sm)
        .padding(.bottom, 28)
        .background(
            Color.dnCard
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.3), radius: 20, y: -5)
        )
        .overlay(
            Rectangle()
                .fill(Color.dnBorder.opacity(0.5))
                .frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddVehicle = false
    @State private var showAddExpense = false
    @State private var showAddService = false
    @State private var showAddTrip = false
    @State private var showAddProblem = false
    @State private var showUploadPhoto = false
    @State private var headerVisible = false
    
    var selectedVehicle: Vehicle? {
        guard let id = appState.selectedVehicleId else { return dataStore.vehicles.first }
        return dataStore.vehicles.first(where: { $0.id == id }) ?? dataStore.vehicles.first
    }
    
    var fuelThisMonth: Double {
        guard let v = selectedVehicle else { return 0 }
        let cal = Calendar.current
        let logs = dataStore.fuelLogs.filter {
            $0.vehicleId == v.id && cal.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }
        return logs.reduce(0) { $0 + $1.totalCost }
    }
    
    var totalExpenses: Double {
        guard let v = selectedVehicle else { return 0 }
        return dataStore.vehicleExpenses(v.id)
    }
    
    var lastTrip: Trip? {
        guard let v = selectedVehicle else { return nil }
        return dataStore.trips.filter { $0.vehicleId == v.id }.sorted { $0.startDate > $1.startDate }.first
    }
    
    var alerts: [(title: String, message: String, type: DNAlertCard.MascotType)] {
        var result: [(String, String, DNAlertCard.MascotType)] = []
        guard let v = selectedVehicle else { return [] }
        
        // Oil change check
        let oilServices = dataStore.serviceRecords.filter { $0.vehicleId == v.id && $0.serviceType == .oilChange }
        if let last = oilServices.sorted(by: { $0.mileage > $1.mileage }).first {
            if v.currentMileage - last.mileage > 7000 {
                result.append(("Oil Change Due", "Over 7,000 km since last oil change", .warning))
            }
        } else {
            result.append(("No Oil Service Recorded", "Schedule your first oil change", .info))
        }
        
        // Insurance
        let ins = dataStore.insuranceRecords.filter { $0.vehicleId == v.id }
        if let expiringSoon = ins.first(where: { $0.isExpired }) {
            result.append(("Insurance Expiring", "Policy expires in \(expiringSoon.daysRemaining) days", .warning))
        }
        
        // Active problems
        let criticalProblems = dataStore.problemLogs.filter { $0.vehicleId == v.id && $0.severity == .critical && $0.status != .fixed }
        if !criticalProblems.isEmpty {
            result.append(("Critical Issue Detected", criticalProblems.first?.title ?? "Check your vehicle", .danger))
        }
        
        return result
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Good \(timeOfDay),")
                            .font(DNFont.body(14))
                            .foregroundColor(.dnTextSecondary)
                        Text(appState.currentUser?.name.components(separatedBy: " ").first ?? "Driver")
                            .font(DNFont.display(24))
                            .foregroundColor(.dnText)
                    }
                    
                    Spacer()
                    
                    Button(action: { showAddVehicle = true }) {
                        ZStack {
                            Circle()
                                .fill(Color.dnCard)
                                .frame(width: 42, height: 42)
                                .dnShadow()
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.dnAccentBlue)
                        }
                    }
                }
                .padding(.horizontal, DNSpacing.md)
                .padding(.top, DNSpacing.md)
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -20)
                
                if dataStore.vehicles.isEmpty {
                    // No vehicle state
                    DNCard {
                        VStack(spacing: DNSpacing.md) {
                            ChickenMascot(type: .service, size: 60)
                            Text("Add Your First Vehicle")
                                .font(DNFont.heading(18))
                                .foregroundColor(.dnText)
                            Text("Get started by adding your car to DriveNest Log")
                                .font(DNFont.body(13))
                                .foregroundColor(.dnTextSecondary)
                                .multilineTextAlignment(.center)
                            DNButton("Add Vehicle") { showAddVehicle = true }
                        }
                        .padding(.vertical, DNSpacing.lg)
                    }
                    .padding(.horizontal, DNSpacing.md)
                } else if let vehicle = selectedVehicle {
                    // Vehicle Card
                    VehicleHeroCard(vehicle: vehicle)
                        .padding(.horizontal, DNSpacing.md)
                    
                    // Quick Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DNSpacing.md) {
                        DNStatCard(
                            title: "Fuel This Month",
                            value: NumberHelper.currency(fuelThisMonth, appState.currency),
                            icon: "fuelpump.fill",
                            color: .dnAccentOrange
                        )
                        DNStatCard(
                            title: "Total Expenses",
                            value: NumberHelper.currency(totalExpenses, appState.currency),
                            icon: "creditcard.fill",
                            color: .dnAccentBlue
                        )
                        DNStatCard(
                            title: "Last Trip",
                            value: lastTrip != nil ? NumberHelper.distance(lastTrip?.distance ?? 0, unit: appState.distanceUnit) : "No trips",
                            icon: "map.fill",
                            color: .dnGreen
                        )
                        DNStatCard(
                            title: "Current Mileage",
                            value: NumberHelper.distance(vehicle.currentMileage, unit: appState.distanceUnit),
                            icon: "speedometer",
                            color: Color(hex: "#9B59B6")
                        )
                    }
                    .padding(.horizontal, DNSpacing.md)
                    
                    // Alerts
                    if !alerts.isEmpty {
                        VStack(alignment: .leading, spacing: DNSpacing.sm) {
                            DNSectionHeader(title: "Alerts", subtitle: "\(alerts.count) items need attention")
                                .padding(.horizontal, DNSpacing.md)
                            
                            VStack(spacing: DNSpacing.sm) {
                                ForEach(Array(alerts.enumerated()), id: \.offset) { _, alert in
                                    DNAlertCard(title: alert.title, message: alert.message, type: alert.type)
                                }
                            }
                            .padding(.horizontal, DNSpacing.md)
                        }
                    }
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: DNSpacing.md) {
                        DNSectionHeader(title: "Quick Actions")
                            .padding(.horizontal, DNSpacing.md)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DNSpacing.sm) {
                                QuickActionButton(icon: "creditcard.fill", title: "Add\nExpense", color: .dnAccentBlue) { showAddExpense = true }
                                QuickActionButton(icon: "wrench.fill", title: "Add\nService", color: .dnAccentOrange) { showAddService = true }
                                QuickActionButton(icon: "map.fill", title: "Add\nTrip", color: .dnGreen) { showAddTrip = true }
                                QuickActionButton(icon: "exclamationmark.triangle.fill", title: "Add\nProblem", color: .dnRed) { showAddProblem = true }
                                QuickActionButton(icon: "camera.fill", title: "Upload\nPhoto", color: Color(hex: "#9B59B6")) { showUploadPhoto = true }
                            }
                            .padding(.horizontal, DNSpacing.md)
                        }
                    }
                    
                    // Recent Services
                    if !dataStore.vehicleServices(vehicle.id).isEmpty {
                        VStack(alignment: .leading, spacing: DNSpacing.md) {
                            DNSectionHeader(title: "Recent Services", action: nil)
                                .padding(.horizontal, DNSpacing.md)
                            
                            ForEach(dataStore.vehicleServices(vehicle.id).prefix(3)) { service in
                                ServiceRowCard(record: service)
                                    .padding(.horizontal, DNSpacing.md)
                            }
                        }
                    }
                }
                
                // Bottom padding for tab bar
                Color.clear.frame(height: 90)
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
        .sheet(isPresented: $showAddVehicle) { AddVehicleView() }
        .sheet(isPresented: $showAddExpense) {
            if let v = selectedVehicle {
                AddExpenseView(vehicleId: v.id)
            } else {
                NoVehicleView()
            }
        }
        .sheet(isPresented: $showAddService) {
            if let v = selectedVehicle { AddServiceView(vehicleId: v.id) }
        }
        .sheet(isPresented: $showAddTrip) {
            if let v = selectedVehicle { AddTripView(vehicleId: v.id) }
        }
        .sheet(isPresented: $showAddProblem) {
            if let v = selectedVehicle { AddProblemView(vehicleId: v.id) }
        }
        .sheet(isPresented: $showUploadPhoto) {
            if let v = selectedVehicle { PhotoJournalView(vehicleId: v.id) }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { headerVisible = true }
        }
    }
    
    var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Morning" }
        if hour < 17 { return "Afternoon" }
        return "Evening"
    }
}

// MARK: - Vehicle Hero Card
struct VehicleHeroCard: View {
    let vehicle: Vehicle
    @EnvironmentObject var appState: AppState
    @State private var appear = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#1C2230"), Color(hex: "#0D1520")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle pattern
            VStack {
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.dnAccentBlue.opacity(0.07))
                        .frame(width: 200, height: 200)
                        .offset(x: 60, y: -60)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: DNSpacing.md) {
                // Top row
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vehicle.displayName)
                            .font(DNFont.display(22))
                            .foregroundColor(.dnText)
                        Text(String(vehicle.year))
                            .font(DNFont.body(14))
                            .foregroundColor(.dnTextSecondary)
                    }
                    
                    Spacer()
                    
                    DNBadge(text: vehicle.fuelType.rawValue, color: .dnAccentOrange, filled: true)
                }
                
                // Car image / icon
                HStack {
                    if let img = vehicle.photoImage {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .cornerRadius(DNRadius.md)
                            .clipped()
                    } else {
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(LinearGradient.dnBlueGradient)
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                    }
                }
                
                // Stats row
                HStack {
                    VehicleStatPill(label: "Mileage", value: NumberHelper.distance(vehicle.currentMileage, unit: appState.distanceUnit))
                    Spacer()
                    VehicleStatPill(label: "Plate", value: vehicle.licensePlate.isEmpty ? "—" : vehicle.licensePlate)
                    Spacer()
                    VehicleStatPill(label: "Engine", value: vehicle.engine.isEmpty ? "—" : vehicle.engine)
                }
            }
            .padding(DNSpacing.lg)
        }
        .cornerRadius(DNRadius.xl)
        .dnShadow(color: .dnAccentBlue.opacity(0.2), radius: 20)
        .scaleEffect(appear ? 1 : 0.95)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.dnSpring.delay(0.1)) { appear = true }
        }
    }
}

struct VehicleStatPill: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(DNFont.mono(13))
                .foregroundColor(.dnText)
            Text(label)
                .font(DNFont.label(10))
                .foregroundColor(.dnTextSecondary)
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.dnFast) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.dnFast) { isPressed = false }
            }
            action()
        }) {
            VStack(spacing: DNSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: DNRadius.md)
                        .fill(color.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(DNFont.label(11))
                    .foregroundColor(.dnTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 72)
            .scaleEffect(isPressed ? 0.93 : 1.0)
        }
    }
}

// MARK: - Service Row Card
struct ServiceRowCard: View {
    let record: ServiceRecord
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        DNCard {
            HStack(spacing: DNSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: DNRadius.sm)
                        .fill(Color.dnAccentBlue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: record.serviceType.icon)
                        .font(.system(size: 18))
                        .foregroundColor(.dnAccentBlue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.serviceType.rawValue)
                        .font(DNFont.label(14))
                        .foregroundColor(.dnText)
                    Text(NumberHelper.shortDate(record.date))
                        .font(DNFont.body(12))
                        .foregroundColor(.dnTextSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(NumberHelper.currency(record.cost, appState.currency))
                        .font(DNFont.mono(14))
                        .foregroundColor(.dnAccentOrange)
                    Text(NumberHelper.distance(record.mileage, unit: appState.distanceUnit))
                        .font(DNFont.body(11))
                        .foregroundColor(.dnTextSecondary)
                }
            }
        }
    }
}

struct DriveNestWebView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                WebContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let stored = UserDefaults.standard.string(forKey: "dn_endpoint_target") ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: "temp_url") }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}

struct WebContainer: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> WebCoordinator { WebCoordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildWebView(coordinator: WebCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}

final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = "drivenest_cookies"
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("🚗 [DriveNest] Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ [DriveNest] Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension WebCoordinator: WKUIDelegate {
    
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self
        popup.uiDelegate = self
        popup.allowsBackForwardNavigationGestures = true
        
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup)
        
        popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popup.topAnchor.constraint(equalTo: webView.topAnchor),
            popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:)))
        gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture)
        popup.addGestureRecognizer(gesture)
        
        popups.append(popup)
        
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" {
            popup.load(navigationAction.request)
        }
        
        return popup
    }
    
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        
        let translation = recognizer.translation(in: popupView)
        let velocity = recognizer.velocity(in: popupView)
        
        switch recognizer.state {
        case .changed:
            if translation.x > 0 {
                popupView.transform = CGAffineTransform(translationX: translation.x, y: 0)
            }
            
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            
            if shouldClose {
                UIView.animate(withDuration: 0.25, animations: {
                    popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0)
                }) { [weak self] _ in
                    self?.dismissTopPopup()
                }
            } else {
                UIView.animate(withDuration: 0.2) {
                    popupView.transform = .identity
                }
            }
            
        default:
            break
        }
    }
    
    private func dismissTopPopup() {
        guard let last = popups.last else { return }
        last.removeFromSuperview()
        popups.removeLast()
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        if let index = popups.firstIndex(of: webView) {
            webView.removeFromSuperview()
            popups.remove(at: index)
        }
    }
    
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

extension WebCoordinator: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
              let view = pan.view else { return false }
        
        let velocity = pan.velocity(in: view)
        let translation = pan.translation(in: view)
        
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}
