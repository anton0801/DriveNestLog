import SwiftUI

// MARK: - Color System
extension Color {
    static let dnBackground = Color(hex: "#12151C")
    static let dnCard = Color(hex: "#1C2230")
    static let dnCardElevated = Color(hex: "#222B3A")
    static let dnAccentBlue = Color(hex: "#4DA3FF")
    static let dnAccentOrange = Color(hex: "#FF9F43")
    static let dnGreen = Color(hex: "#45C486")
    static let dnRed = Color(hex: "#F25F5C")
    static let dnText = Color(hex: "#F3F5F8")
    static let dnTextSecondary = Color(hex: "#A7B0BE")
    static let dnBorder = Color(hex: "#2A3447")
    static let dnCardLight = Color(hex: "#F7F9FC")
    static let dnBackgroundLight = Color(hex: "#EEF1F7")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Gradient System
extension LinearGradient {
    static let dnBlueGradient = LinearGradient(
        colors: [Color(hex: "#4DA3FF"), Color(hex: "#2D7DD2")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let dnOrangeGradient = LinearGradient(
        colors: [Color(hex: "#FF9F43"), Color(hex: "#E07B20")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let dnGreenGradient = LinearGradient(
        colors: [Color(hex: "#45C486"), Color(hex: "#27A066")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let dnCardGradient = LinearGradient(
        colors: [Color(hex: "#1C2230"), Color(hex: "#222B3A")],
        startPoint: .top, endPoint: .bottom
    )
    static let dnHeroGradient = LinearGradient(
        colors: [Color(hex: "#1C2230"), Color(hex: "#12151C")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Typography
struct DNFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func heading(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
    static func label(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
}

// MARK: - Spacing
struct DNSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
struct DNRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 28
    static let pill: CGFloat = 999
}

// MARK: - Animation
extension Animation {
    static let dnSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let dnFast = Animation.spring(response: 0.3, dampingFraction: 0.75)
    static let dnSlow = Animation.spring(response: 0.6, dampingFraction: 0.8)
}

// MARK: - Shadow
struct DNShadow: ViewModifier {
    var color: Color = .black.opacity(0.25)
    var radius: CGFloat = 12
    var y: CGFloat = 4
    
    func body(content: Content) -> some View {
        content.shadow(color: color, radius: radius, x: 0, y: y)
    }
}

extension View {
    func dnShadow(color: Color = .black.opacity(0.25), radius: CGFloat = 12, y: CGFloat = 4) -> some View {
        modifier(DNShadow(color: color, radius: radius, y: y))
    }
}
