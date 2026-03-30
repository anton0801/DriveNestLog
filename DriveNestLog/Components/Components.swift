import SwiftUI

// MARK: - Primary Button
struct DNButton: View {
    let title: String
    let gradient: LinearGradient
    let action: () -> Void
    @State private var isPressed = false
    
    init(_ title: String, gradient: LinearGradient = .dnBlueGradient, action: @escaping () -> Void) {
        self.title = title
        self.gradient = gradient
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.dnFast) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.dnFast) { isPressed = false }
            }
            action()
        }) {
            Text(title)
                .font(DNFont.heading(16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(gradient)
                .cornerRadius(DNRadius.md)
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .dnShadow(color: .dnAccentBlue.opacity(0.3))
        }
    }
}

// MARK: - Secondary Button
struct DNSecondaryButton: View {
    let title: String
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
            Text(title)
                .font(DNFont.heading(16))
                .foregroundColor(.dnAccentBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.dnAccentBlue.opacity(0.12))
                .cornerRadius(DNRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DNRadius.md)
                        .stroke(Color.dnAccentBlue.opacity(0.3), lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.97 : 1.0)
        }
    }
}

// MARK: - Card View
struct DNCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = DNSpacing.md
    
    init(padding: CGFloat = DNSpacing.md, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(Color.dnCard)
            .cornerRadius(DNRadius.lg)
            .dnShadow()
    }
}

// MARK: - Input Field
struct DNTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(DNFont.label(12))
                .foregroundColor(.dnTextSecondary)
            
            HStack(spacing: DNSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundColor(isFocused ? .dnAccentBlue : .dnTextSecondary)
                        .animation(.dnFast, value: isFocused)
                }
                
                if isSecure {
                    SecureField(placeholder.isEmpty ? title : placeholder, text: $text)
                        .font(DNFont.body(15))
                        .foregroundColor(.dnText)
                        .focused($isFocused)
                } else {
                    TextField(placeholder.isEmpty ? title : placeholder, text: $text)
                        .font(DNFont.body(15))
                        .foregroundColor(.dnText)
                        .keyboardType(keyboardType)
                        .focused($isFocused)
                }
            }
            .padding(.horizontal, DNSpacing.md)
            .padding(.vertical, 13)
            .background(Color.dnCardElevated)
            .cornerRadius(DNRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DNRadius.md)
                    .stroke(isFocused ? Color.dnAccentBlue : Color.dnBorder, lineWidth: 1)
                    .animation(.dnFast, value: isFocused)
            )
        }
    }
}

// MARK: - Section Header
struct DNSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    var actionTitle: String = "See All"
    
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DNFont.heading(18))
                    .foregroundColor(.dnText)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DNFont.body(12))
                        .foregroundColor(.dnTextSecondary)
                }
            }
            Spacer()
            if let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(DNFont.label(13))
                        .foregroundColor(.dnAccentBlue)
                }
            }
        }
    }
}

// MARK: - Stat Card
struct DNStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: DNSpacing.sm) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                }
                Spacer()
            }
            
            Text(value)
                .font(DNFont.display(22))
                .foregroundColor(.dnText)
            
            Text(title)
                .font(DNFont.label(11))
                .foregroundColor(.dnTextSecondary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(DNFont.body(10))
                    .foregroundColor(color)
            }
        }
        .padding(DNSpacing.md)
        .background(Color.dnCard)
        .cornerRadius(DNRadius.lg)
        .dnShadow()
    }
}

// MARK: - Badge
struct DNBadge: View {
    let text: String
    let color: Color
    var filled: Bool = false
    
    var body: some View {
        Text(text)
            .font(DNFont.label(11))
            .foregroundColor(filled ? .white : color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(filled ? color : color.opacity(0.15))
            .cornerRadius(DNRadius.pill)
    }
}

func reduce(state: DriveNestState, intent: DriveNestIntent) -> DriveNestState {
    var newState = state
    
    switch intent {
    case .initialize:
        newState.phase = .loading
        
    case .trackingDataReceived(let data):
        let converted = data.mapValues { "\($0)" }
        newState.tracking = TrackingData(attributes: converted)
        
    case .navigationDataReceived(let data):
        let converted = data.mapValues { "\($0)" }
        newState.navigation = NavigationData(parameters: converted)
        
    case .validationCompleted(let success):
        if success {
            newState.phase = .validated
        } else {
            newState.phase = .failed
            newState.ui.navigateToMain = true
        }
        
    case .endpointFetched(let url):
        newState.configuration.endpoint = url
        newState.configuration.mode = "Active"
        newState.configuration.isFirstLaunch = false
        newState.phase = .ready(url)
        
        if newState.permission.canAsk {
            newState.ui.showPermissionPrompt = true
        } else {
            newState.ui.navigateToWeb = true
        }
        
    case .permissionResponseReceived(let granted):
        newState.permission.isGranted = granted
        newState.permission.isDenied = !granted
        newState.permission.lastAskedDate = Date()
        newState.ui.showPermissionPrompt = false
        newState.ui.navigateToWeb = true
        
    case .deferNotificationPermission:
        newState.permission.lastAskedDate = Date()
        newState.ui.showPermissionPrompt = false
        newState.ui.navigateToWeb = true
        
    case .networkConnected:
        newState.network = .connected
        newState.ui.showOfflineView = false
        
    case .networkDisconnected:
        newState.network = .disconnected
        newState.ui.showOfflineView = true
        
    case .timeout:
        newState.phase = .failed
        newState.ui.navigateToMain = true
        
    default:
        break
    }
    
    return newState
}

struct DNEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: DNSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.dnAccentBlue.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.dnAccentBlue)
            }
            
            Text(title)
                .font(DNFont.heading(18))
                .foregroundColor(.dnText)
            
            Text(message)
                .font(DNFont.body(14))
                .foregroundColor(.dnTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DNSpacing.xl)
            
            if let actionTitle = actionTitle, let action = action {
                DNButton(actionTitle, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DNSpacing.xxl)
    }
}

// MARK: - Nav Bar
struct DNNavBar: View {
    let title: String
    var subtitle: String? = nil
    var trailingContent: AnyView? = nil
    @Environment(\.presentationMode) var presentationMode
    var showBack: Bool = true
    
    var body: some View {
        HStack {
            if showBack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    ZStack {
                        Circle()
                            .fill(Color.dnCardElevated)
                            .frame(width: 36, height: 36)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.dnText)
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(title)
                    .font(DNFont.heading(17))
                    .foregroundColor(.dnText)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DNFont.body(12))
                        .foregroundColor(.dnTextSecondary)
                }
            }
            
            Spacer()
            
            if let trailing = trailingContent {
                trailing
            } else if showBack {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, DNSpacing.md)
        .padding(.vertical, DNSpacing.sm)
    }
}

// MARK: - Info Row
struct DNInfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .dnText
    
    var body: some View {
        HStack {
            Text(label)
                .font(DNFont.body(14))
                .foregroundColor(.dnTextSecondary)
            Spacer()
            Text(value)
                .font(DNFont.label(14))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 8)
        .overlay(
            Divider().opacity(0.3),
            alignment: .bottom
        )
    }
}

// MARK: - Shimmer Effect
struct ShimmerView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color.dnCard, location: phase - 0.3),
                        .init(color: Color.dnCardElevated, location: phase),
                        .init(color: Color.dnCard, location: phase + 0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}

// MARK: - Chicken Mascot
struct ChickenMascot: View {
    enum MascotType {
        case fuel, service, trip, alert
        
        var icon: String {
            switch self {
            case .fuel: return "🐔"
            case .service: return "🐔"
            case .trip: return "🐔"
            case .alert: return "🐔"
            }
        }
        
        var accessory: String {
            switch self {
            case .fuel: return "⛽"
            case .service: return "🔧"
            case .trip: return "🗺️"
            case .alert: return "⚠️"
            }
        }
        
        var color: Color {
            switch self {
            case .fuel: return .dnAccentOrange
            case .service: return .dnAccentBlue
            case .trip: return .dnGreen
            case .alert: return .dnRed
            }
        }
    }
    
    let type: MascotType
    var size: CGFloat = 40
    @State private var bounce = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(type.color.opacity(0.15))
                .frame(width: size + 10, height: size + 10)
            
            Text(type.icon)
                .font(.system(size: size * 0.7))
                .offset(y: bounce ? -3 : 0)
                .animation(.dnSpring.repeatForever(autoreverses: true), value: bounce)
            
            Text(type.accessory)
                .font(.system(size: size * 0.35))
                .offset(x: size * 0.25, y: size * 0.2)
        }
        .onAppear { bounce = true }
    }
}

// MARK: - Alert Card
struct DNAlertCard: View {
    let title: String
    let message: String
    let type: MascotType
    
    enum MascotType {
        case warning, info, success, danger
        var color: Color {
            switch self {
            case .warning: return .dnAccentOrange
            case .info: return .dnAccentBlue
            case .success: return .dnGreen
            case .danger: return .dnRed
            }
        }
        var icon: String {
            switch self {
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .danger: return "xmark.octagon.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: DNSpacing.md) {
            Image(systemName: type.icon)
                .font(.system(size: 20))
                .foregroundColor(type.color)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(DNFont.label(14))
                    .foregroundColor(.dnText)
                Text(message)
                    .font(DNFont.body(12))
                    .foregroundColor(.dnTextSecondary)
            }
            Spacer()
        }
        .padding(DNSpacing.md)
        .background(type.color.opacity(0.1))
        .cornerRadius(DNRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DNRadius.md)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Tab Item Data
struct TabItemData {
    let icon: String
    let title: String
}

// MARK: - No Vehicle Sheet View
struct NoVehicleView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: DNSpacing.lg) {
            Spacer()
            Image(systemName: "car.fill")
                .font(.system(size: 60))
                .foregroundColor(.dnTextSecondary)
            Text("No Vehicle Added")
                .font(DNFont.display(22))
                .foregroundColor(.dnText)
            Text("Please add a vehicle first before tracking expenses.")
                .font(DNFont.body(15))
                .foregroundColor(.dnTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DNSpacing.xl)
            DNButton("Close") { presentationMode.wrappedValue.dismiss() }
                .padding(.horizontal, DNSpacing.lg)
            Spacer()
        }
        .background(Color.dnBackground.ignoresSafeArea())
    }
}

// MARK: - Number Formatter
struct NumberHelper {
    static func currency(_ value: Double, _ currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(currencyCode) \(value)"
    }

    static func shortCurrency(_ value: Double, _ currencyCode: String = "USD") -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        }
        return String(format: "%.0f", value)
    }
    
    static func distance(_ value: Double, unit: String = "km") -> String {
        String(format: "%.0f \(unit)", value)
    }
    
    static func fuel(_ value: Double, unit: String = "L") -> String {
        String(format: "%.1f \(unit)", value)
    }
    
    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
