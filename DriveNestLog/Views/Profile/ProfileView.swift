import SwiftUI
import UIKit
import UserNotifications

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingExportSheet = false
    @State private var showingEditProfile = false
    @State private var showingAchievements = false
    @State private var exportText = ""
    @State private var showingExportResult = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DNSpacing.lg) {
                    // Profile Header
                    profileHeader

                    // Stats
                    profileStats

                    // Settings Sections
                    Group {
                        appearanceSection
                        unitsSection
                        notificationsSection
                        dataSection
                        aboutSection
                    }

                    // Logout
                    Button(action: { showingLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#F25F5C"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#F25F5C").opacity(0.1))
                        .cornerRadius(DNRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: DNRadius.md)
                                .stroke(Color(hex: "#F25F5C").opacity(0.3), lineWidth: 1)
                        )
                    }

                    // Delete Account
                    Button(action: { showingDeleteAccountAlert = true }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.minus")
                            Text("Delete Account")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#FF3B30"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#FF3B30").opacity(0.08))
                        .cornerRadius(DNRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: DNRadius.md)
                                .stroke(Color(hex: "#FF3B30").opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.bottom, DNSpacing.xl)
                }
                .padding(DNSpacing.md)
            }
            .background(Color(hex: "#12151C").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile & Settings")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#F3F5F8"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingEditProfile = true }) {
                        Image(systemName: "pencil")
                            .foregroundColor(Color(hex: "#4DA3FF"))
                    }
                }
            }
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    appState.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    dataStore.deleteAllData()
                    appState.deleteAccount()
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingExportResult) {
                ExportDataView(text: exportText)
            }
            .sheet(isPresented: $showingAchievements) {
                NavigationView {
                    AchievementsView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Done") { showingAchievements = false }
                                .foregroundColor(Color(hex: "#4DA3FF"))
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Profile Header
    var profileHeader: some View {
        DNCard {
            HStack(spacing: DNSpacing.md) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.dnBlueGradient)
                        .frame(width: 70, height: 70)
                    Text(String(appState.currentUser?.name.prefix(1) ?? "U"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.currentUser?.name ?? "Driver")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "#F3F5F8"))
                    Text(appState.currentUser?.email ?? "")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#A7B0BE"))
                    HStack(spacing: 4) {
                        Image(systemName: "car.2.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#4DA3FF"))
                        Text("\(dataStore.vehicles.count) vehicle\(dataStore.vehicles.count == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#4DA3FF"))
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Profile Stats
    var profileStats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: DNSpacing.sm) {
            MiniStat(value: "\(dataStore.serviceRecords.count)", label: "Services", icon: "wrench.fill", color: Color(hex: "#45C486"))
            MiniStat(value: "\(dataStore.expenses.count)", label: "Expenses", icon: "dollarsign", color: Color(hex: "#FF9F43"))
            MiniStat(value: "\(dataStore.trips.count)", label: "Trips", icon: "map.fill", color: Color(hex: "#4DA3FF"))
        }
    }

    // MARK: - Appearance Section
    var appearanceSection: some View {
        SettingsSection(title: "Appearance", icon: "paintbrush.fill", iconColor: Color(hex: "#9B59B6")) {
            VStack(spacing: 0) {
                // Theme picker
                VStack(alignment: .leading, spacing: DNSpacing.sm) {
                    Text("App Theme")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#F3F5F8"))
                    HStack(spacing: DNSpacing.sm) {
                        ForEach(["system", "dark", "light"], id: \.self) { theme in
                            Button(action: {
                                withAnimation(.dnSpring) { appState.appTheme = theme }
                            }) {
                                VStack(spacing: 6) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(themePreviewColor(theme))
                                            .frame(height: 40)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(appState.appTheme == theme ? Color(hex: "#4DA3FF") : Color.clear, lineWidth: 2)
                                            )
                                        Image(systemName: themeIcon(theme))
                                            .font(.system(size: 16))
                                            .foregroundColor(theme == "light" ? .black : .white)
                                    }
                                    Text(theme.capitalized)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(appState.appTheme == theme ? Color(hex: "#4DA3FF") : Color(hex: "#A7B0BE"))
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(DNSpacing.md)

                Divider().background(Color(hex: "#2A3447"))

                // Achievements button
                Button(action: { showingAchievements = true }) {
                    SettingsRow(icon: "trophy.fill", label: "Achievements", color: Color(hex: "#FFD700"), value: nil, showChevron: true)
                }
            }
        }
    }

    func themePreviewColor(_ theme: String) -> Color {
        switch theme {
        case "dark": return Color(hex: "#12151C")
        case "light": return Color(hex: "#F5F7FA")
        default: return Color(hex: "#2A3447")
        }
    }

    func themeIcon(_ theme: String) -> String {
        switch theme {
        case "dark": return "moon.fill"
        case "light": return "sun.max.fill"
        default: return "circle.lefthalf.filled"
        }
    }

    // MARK: - Units Section
    var unitsSection: some View {
        SettingsSection(title: "Units & Currency", icon: "ruler.fill", iconColor: Color(hex: "#45C486")) {
            VStack(spacing: 0) {
                // Currency
                VStack(alignment: .leading, spacing: DNSpacing.sm) {
                    Text("Currency")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#F3F5F8"))
                    HStack(spacing: DNSpacing.sm) {
                        ForEach(["USD", "EUR", "GBP", "UAH"], id: \.self) { currency in
                            Button(action: { appState.currency = currency }) {
                                Text(currency)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(appState.currency == currency ? .white : Color(hex: "#A7B0BE"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: DNRadius.sm)
                                            .fill(appState.currency == currency ? Color(hex: "#4DA3FF") : Color(hex: "#2A3447"))
                                    )
                            }
                        }
                    }
                }
                .padding(DNSpacing.md)

                Divider().background(Color(hex: "#2A3447"))

                // Distance Unit
                VStack(alignment: .leading, spacing: DNSpacing.sm) {
                    Text("Distance Unit")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#F3F5F8"))
                    HStack(spacing: DNSpacing.sm) {
                        ForEach(["km", "mi"], id: \.self) { unit in
                            Button(action: { appState.distanceUnit = unit }) {
                                Text(unit.uppercased())
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(appState.distanceUnit == unit ? .white : Color(hex: "#A7B0BE"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: DNRadius.sm)
                                            .fill(appState.distanceUnit == unit ? Color(hex: "#4DA3FF") : Color(hex: "#2A3447"))
                                    )
                            }
                        }
                    }
                }
                .padding(DNSpacing.md)

                Divider().background(Color(hex: "#2A3447"))

                // Fuel Unit
                VStack(alignment: .leading, spacing: DNSpacing.sm) {
                    Text("Fuel Unit")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#F3F5F8"))
                    HStack(spacing: DNSpacing.sm) {
                        ForEach(["L", "gal"], id: \.self) { unit in
                            Button(action: { appState.fuelUnit = unit }) {
                                Text(unit)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(appState.fuelUnit == unit ? .white : Color(hex: "#A7B0BE"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: DNRadius.sm)
                                            .fill(appState.fuelUnit == unit ? Color(hex: "#4DA3FF") : Color(hex: "#2A3447"))
                                    )
                            }
                        }
                    }
                }
                .padding(DNSpacing.md)
            }
        }
    }

    // MARK: - Notifications Section
    var notificationsSection: some View {
        SettingsSection(title: "Notifications", icon: "bell.fill", iconColor: Color(hex: "#FF9F43")) {
            VStack(spacing: 0) {
                HStack {
                    Text("Enable Notifications")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#F3F5F8"))
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { appState.notificationsEnabled },
                        set: { newValue in
                            if newValue {
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                                    DispatchQueue.main.async {
                                        appState.notificationsEnabled = granted
                                        if granted {
                                            // Reschedule all reminders
                                            dataStore.reminders.forEach { reminder in
                                                dataStore.scheduleNotification(for: reminder)
                                            }
                                        }
                                    }
                                }
                            } else {
                                appState.notificationsEnabled = false
                                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                            }
                        }
                    ))
                    .tint(Color(hex: "#4DA3FF"))
                }
                .padding(DNSpacing.md)

                if appState.notificationsEnabled {
                    Divider().background(Color(hex: "#2A3447"))
                    VStack(alignment: .leading, spacing: DNSpacing.sm) {
                        Text("Active Reminders: \(dataStore.reminders.count)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#A7B0BE"))
                        if !dataStore.reminders.isEmpty {
                            ForEach(dataStore.reminders.prefix(3)) { r in
                                HStack {
                                    Image(systemName: "bell.badge.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#FF9F43"))
                                    Text(r.title)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: "#F3F5F8"))
                                    Spacer()
                                    Text(NumberHelper.shortDate(r.dueDate))
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(hex: "#A7B0BE"))
                                }
                            }
                        }
                    }
                    .padding(DNSpacing.md)
                }
            }
        }
    }

    // MARK: - Data Section
    var dataSection: some View {
        SettingsSection(title: "Data", icon: "externaldrive.fill", iconColor: Color(hex: "#4DA3FF")) {
            VStack(spacing: 0) {
                Button(action: { exportData() }) {
                    SettingsRow(icon: "square.and.arrow.up", label: "Export Data (JSON)", color: Color(hex: "#4DA3FF"), value: nil, showChevron: true)
                }

                Divider().background(Color(hex: "#2A3447"))

                Button(action: { clearOldData() }) {
                    SettingsRow(icon: "trash.fill", label: "Clear Old Records (1+ year)", color: Color(hex: "#F25F5C"), value: nil, showChevron: false)
                }

                Divider().background(Color(hex: "#2A3447"))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Storage Used")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#F3F5F8"))
                        Text(storageSize())
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#A7B0BE"))
                    }
                    Spacer()
                    Image(systemName: "internaldrive")
                        .foregroundColor(Color(hex: "#A7B0BE"))
                }
                .padding(DNSpacing.md)
            }
        }
    }

    // MARK: - About Section
    var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle.fill", iconColor: Color(hex: "#A7B0BE")) {
            VStack(spacing: 0) {
                HStack {
                    Text("Version")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#F3F5F8"))
                    Spacer()
                    Text("1.0.0")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#A7B0BE"))
                }
                .padding(DNSpacing.md)

                Divider().background(Color(hex: "#2A3447"))

                HStack {
                    Text("App Name")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#F3F5F8"))
                    Spacer()
                    Text("Drive Nest Log 🐔")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#A7B0BE"))
                }
                .padding(DNSpacing.md)

                Divider().background(Color(hex: "#2A3447"))

                HStack {
                    Text("Built with")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#F3F5F8"))
                    Spacer()
                    Text("SwiftUI + ❤️")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#A7B0BE"))
                }
                .padding(DNSpacing.md)
            }
        }
    }

    // MARK: - Helpers
    func exportData() {
        var exportDict: [String: Any] = [:]
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        if let vehiclesData = try? encoder.encode(dataStore.vehicles),
           let vehiclesJson = String(data: vehiclesData, encoding: .utf8) {
            exportDict["vehicles"] = vehiclesJson
        }
        if let expensesData = try? encoder.encode(dataStore.expenses),
           let expensesJson = String(data: expensesData, encoding: .utf8) {
            exportDict["expenses"] = expensesJson
        }
        if let servicesData = try? encoder.encode(dataStore.serviceRecords),
           let servicesJson = String(data: servicesData, encoding: .utf8) {
            exportDict["services"] = servicesJson
        }
        if let fuelData = try? encoder.encode(dataStore.fuelLogs),
           let fuelJson = String(data: fuelData, encoding: .utf8) {
            exportDict["fuelLogs"] = fuelJson
        }

        let text = """
        DRIVE NEST LOG - DATA EXPORT
        Date: \(Date())
        Vehicles: \(dataStore.vehicles.count)
        Service Records: \(dataStore.serviceRecords.count)
        Expenses: \(dataStore.expenses.count)
        Fuel Logs: \(dataStore.fuelLogs.count)
        Trips: \(dataStore.trips.count)
        Problems: \(dataStore.problemLogs.count)
        
        --- VEHICLES ---
        \(dataStore.vehicles.map { "\($0.brand) \($0.model) \($0.year) - \($0.currentMileage)km" }.joined(separator: "\n"))
        
        --- EXPENSES ---
        \(dataStore.expenses.map { "\(NumberHelper.shortDate($0.date)) \($0.category.rawValue) \($0.amount)" }.joined(separator: "\n"))
        """
        exportText = text
        showingExportResult = true
    }

    func clearOldData() {
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        dataStore.expenses.removeAll { $0.date < oneYearAgo }
        dataStore.serviceRecords.removeAll { $0.date < oneYearAgo }
        dataStore.fuelLogs.removeAll { $0.date < oneYearAgo }
        dataStore.saveAll()
    }

    func storageSize() -> String {
        let totalRecords = dataStore.vehicles.count + dataStore.serviceRecords.count + dataStore.expenses.count + dataStore.fuelLogs.count + dataStore.trips.count
        let estimatedKB = totalRecords * 2
        return "\(estimatedKB) KB (estimated)"
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: DNSpacing.sm) {
            HStack(spacing: DNSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#A7B0BE"))
            }
            .padding(.horizontal, DNSpacing.xs)

            VStack(spacing: 0) {
                content()
            }
            .background(Color(hex: "#1C2230"))
            .cornerRadius(DNRadius.lg)
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let label: String
    let color: Color
    let value: String?
    let showChevron: Bool

    var body: some View {
        HStack(spacing: DNSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#F3F5F8"))
            Spacer()
            if let value = value {
                Text(value)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#A7B0BE"))
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#4A5568"))
            }
        }
        .padding(DNSpacing.md)
    }
}

// MARK: - Mini Stat
struct MiniStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        DNCard {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#F3F5F8"))
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#A7B0BE"))
            }
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var showSaved = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DNSpacing.lg) {
                    DNCard {
                        VStack(spacing: DNSpacing.md) {
                            DNTextField(title: "Full Name", text: $name, placeholder: "Full Name", icon: "person.fill", isSecure: false)
                            DNTextField(title: "Email", text: $email, placeholder: "Email", icon: "envelope.fill", isSecure: false)
                        }
                    }

                    if showSaved {
                        DNAlertCard(title: "Saved!", message: "Your profile has been updated.", type: .success)
                    }

                    DNButton("Save Changes") {
                        if !name.isEmpty {
                            appState.updateProfile(name: name, email: email)
                            showSaved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
                .padding(DNSpacing.md)
            }
            .background(Color(hex: "#12151C").ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(Color(hex: "#4DA3FF"))
                }
            }
            .onAppear {
                name = appState.currentUser?.name ?? ""
                email = appState.currentUser?.email ?? ""
            }
        }
    }
}

// MARK: - Export Data View
struct ExportDataView: View {
    let text: String
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                Text(text)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(hex: "#F3F5F8"))
                    .padding(DNSpacing.md)
            }
            .background(Color(hex: "#12151C").ignoresSafeArea())
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(Color(hex: "#4DA3FF"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        UIPasteboard.general.string = text
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(Color(hex: "#4DA3FF"))
                    }
                }
            }
        }
    }
}
