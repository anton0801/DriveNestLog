import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var carOffset: CGFloat = -200
    @State private var chickenScale: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var particleOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var rotationAngle: Double = 0
    
    let onFinished: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color.dnBackground.ignoresSafeArea()
            
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
                        
                        // Chicken mascot
                        Text("🐔")
                            .font(.system(size: 22))
                            .scaleEffect(chickenScale)
                            .offset(x: 18, y: -2)
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
                    
                    Text("Your smart car companion")
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
        }
        .onAppear {
            startAnimation()
        }
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
        
        // Finish after 2.8s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            onFinished()
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
