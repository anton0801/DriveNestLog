import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "car.fill",
            accentIcon: "wrench.fill",
            title: "Track Your\nVehicle Health",
            subtitle: "Never miss an oil change, brake service, or tire rotation again. Your car talks — we help you listen.",
            mascot: "🐔🔧",
            gradient: LinearGradient(colors: [Color(hex: "#1C2230"), Color(hex: "#12151C")], startPoint: .top, endPoint: .bottom),
            accentColor: Color(hex: "#4DA3FF")
        ),
        OnboardingPage(
            icon: "fuelpump.fill",
            accentIcon: "chart.line.uptrend.xyaxis",
            title: "Monitor Every\nExpense",
            subtitle: "Fuel, insurance, repairs — track every dollar spent on your car and discover where your money goes.",
            mascot: "🐔⛽",
            gradient: LinearGradient(colors: [Color(hex: "#1E1A2E"), Color(hex: "#12151C")], startPoint: .top, endPoint: .bottom),
            accentColor: Color(hex: "#FF9F43")
        ),
        OnboardingPage(
            icon: "map.fill",
            accentIcon: "location.fill",
            title: "Plan Every\nJourney",
            subtitle: "Pre-trip checklists, trip logging, and route tracking — arrive safely every time.",
            mascot: "🐔🗺️",
            gradient: LinearGradient(colors: [Color(hex: "#111E1A"), Color(hex: "#12151C")], startPoint: .top, endPoint: .bottom),
            accentColor: Color(hex: "#45C486")
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            accentIcon: "star.fill",
            title: "Smart Insights\n& Reminders",
            subtitle: "Get personalized alerts, achievements, and cost analytics. Drive smarter with DriveNest Log.",
            mascot: "🐔📊",
            gradient: LinearGradient(colors: [Color(hex: "#1A1218"), Color(hex: "#12151C")], startPoint: .top, endPoint: .bottom),
            accentColor: Color(hex: "#F25F5C")
        )
    ]
    
    var body: some View {
        ZStack {
            pages[currentPage].gradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation(.dnSpring) { currentPage = pages.count - 1 }
                        }
                        .font(DNFont.label(15))
                        .foregroundColor(.dnTextSecondary)
                        .padding(.trailing, DNSpacing.md)
                        .padding(.top, DNSpacing.md)
                    }
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                        OnboardingPageView(page: page, isActive: currentPage == idx)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.dnSpring, value: currentPage)
                
                // Dots and button
                VStack(spacing: DNSpacing.lg) {
                    // Dot indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            RoundedRectangle(cornerRadius: DNRadius.pill)
                                .fill(i == currentPage ? pages[currentPage].accentColor : Color.dnTextSecondary.opacity(0.4))
                                .frame(width: i == currentPage ? 24 : 7, height: 7)
                                .animation(.dnSpring, value: currentPage)
                        }
                    }
                    
                    // Action button
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation(.dnSpring) { currentPage += 1 }
                        }) {
                            HStack {
                                Text("Next")
                                Image(systemName: "arrow.right")
                            }
                            .font(DNFont.heading(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(pages[currentPage].accentColor)
                            .cornerRadius(DNRadius.md)
                        }
                        .padding(.horizontal, DNSpacing.lg)
                    } else {
                        Button(action: {
                            withAnimation(.dnSpring) {
                                hasCompletedOnboarding = true
                            }
                        }) {
                            HStack {
                                Text("Get Started")
                                Image(systemName: "chevron.right")
                            }
                            .font(DNFont.heading(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient.dnBlueGradient)
                            .cornerRadius(DNRadius.md)
                            .dnShadow(color: .dnAccentBlue.opacity(0.4))
                        }
                        .padding(.horizontal, DNSpacing.lg)
                    }
                }
                .padding(.bottom, DNSpacing.xxl)
            }
        }
        .animation(.dnSpring, value: currentPage)
    }
}

struct OnboardingPage {
    let icon: String
    let accentIcon: String
    let title: String
    let subtitle: String
    let mascot: String
    let gradient: LinearGradient
    let accentColor: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool
    
    @State private var illustrationScale: CGFloat = 0.8
    @State private var illustrationOpacity: Double = 0
    @State private var textOffset: CGFloat = 30
    @State private var textOpacity: Double = 0
    @State private var floatOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: DNSpacing.xl) {
            Spacer()
            
            // Illustration
            ZStack {
                // Background circles
                Circle()
                    .fill(page.accentColor.opacity(0.08))
                    .frame(width: 260, height: 260)
                
                Circle()
                    .fill(page.accentColor.opacity(0.05))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(rotationAngle))
                
                Circle()
                    .stroke(page.accentColor.opacity(0.2), lineWidth: 1)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-rotationAngle * 0.5))
                
                // Main icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.dnCard, Color.dnCardElevated],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 130, height: 130)
                        .dnShadow(color: page.accentColor.opacity(0.3), radius: 24)
                    
                    Image(systemName: page.icon)
                        .font(.system(size: 52))
                        .foregroundColor(page.accentColor)
                        .offset(y: floatOffset)
                }
                
                // Accent icon badge
                ZStack {
                    Circle()
                        .fill(page.accentColor)
                        .frame(width: 44, height: 44)
                    Image(systemName: page.accentIcon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .offset(x: 55, y: -55)
                .dnShadow(color: page.accentColor.opacity(0.5))
                
                // Mascot
                Text(page.mascot)
                    .font(.system(size: 30))
                    .offset(x: -60, y: 55)
                    .scaleEffect(illustrationScale)
            }
            .scaleEffect(illustrationScale)
            .opacity(illustrationOpacity)
            
            // Text
            VStack(spacing: DNSpacing.md) {
                Text(page.title)
                    .font(DNFont.display(30))
                    .foregroundColor(.dnText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text(page.subtitle)
                    .font(DNFont.body(15))
                    .foregroundColor(.dnTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, DNSpacing.lg)
            }
            .offset(y: textOffset)
            .opacity(textOpacity)
            
            Spacer()
            Spacer()
        }
        .onChange(of: isActive) { active in
            if active { animateIn() }
        }
        .onAppear {
            if isActive { animateIn() }
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                floatOffset = -10
            }
        }
    }
    
    private func animateIn() {
        illustrationScale = 0.7
        illustrationOpacity = 0
        textOffset = 30
        textOpacity = 0
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            illustrationScale = 1.0
            illustrationOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            textOffset = 0
            textOpacity = 1.0
        }
    }
}
