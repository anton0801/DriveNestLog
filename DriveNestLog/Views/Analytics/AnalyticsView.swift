import SwiftUI

// MARK: - Analytics View
struct AnalyticsView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var selectedPeriod: AnalyticsPeriod = .threeMonths
    @State private var selectedVehicleId: UUID? = nil
    @State private var animateCharts = false

    enum AnalyticsPeriod: String, CaseIterable {
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case allTime = "All"

        var months: Int {
            switch self {
            case .oneMonth: return 1
            case .threeMonths: return 3
            case .sixMonths: return 6
            case .oneYear: return 12
            case .allTime: return 999
            }
        }
    }

    var vehicle: Vehicle? {
        if let id = selectedVehicleId {
            return dataStore.vehicles.first(where: { $0.id == id })
        }
        return dataStore.vehicles.first(where: { $0.id == appState.selectedVehicleId }) ?? dataStore.vehicles.first
    }

    var filteredExpenses: [Expense] {
        guard let v = vehicle else { return [] }
        let cutoff = Calendar.current.date(byAdding: .month, value: -selectedPeriod.months, to: Date()) ?? Date.distantPast
        return dataStore.expenses.filter { $0.vehicleId == v.id && ($0.date >= cutoff || selectedPeriod == .allTime) }
    }

    var filteredFuelLogs: [FuelLog] {
        guard let v = vehicle else { return [] }
        let cutoff = Calendar.current.date(byAdding: .month, value: -selectedPeriod.months, to: Date()) ?? Date.distantPast
        return dataStore.fuelLogs.filter { $0.vehicleId == v.id && ($0.date >= cutoff || selectedPeriod == .allTime) }
    }

    var filteredServices: [ServiceRecord] {
        guard let v = vehicle else { return [] }
        let cutoff = Calendar.current.date(byAdding: .month, value: -selectedPeriod.months, to: Date()) ?? Date.distantPast
        return dataStore.serviceRecords.filter { $0.vehicleId == v.id && ($0.date >= cutoff || selectedPeriod == .allTime) }
    }

    var totalCost: Double { filteredExpenses.reduce(0) { $0 + $1.amount } }

    var expensesByCategory: [(Expense.ExpenseCategory, Double)] {
        var dict = [Expense.ExpenseCategory: Double]()
        for e in filteredExpenses { dict[e.category, default: 0] += e.amount }
        return dict.sorted { $0.value > $1.value }
    }

    var monthlyExpenses: [(String, Double)] {
        var dict = [String: Double]()
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        for e in filteredExpenses {
            let key = fmt.string(from: e.date)
            dict[key, default: 0] += e.amount
        }
        // Return sorted by month
        let allMonths = (0..<selectedPeriod.months).compactMap { offset -> String? in
            guard let d = Calendar.current.date(byAdding: .month, value: -offset, to: Date()) else { return nil }
            return fmt.string(from: d)
        }.reversed()
        return allMonths.map { ($0, dict[$0, default: 0]) }
    }

    var fuelTrend: [(String, Double)] {
        var dict = [String: Double]()
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        for f in filteredFuelLogs {
            let key = fmt.string(from: f.date)
            let existing = dict[key]
            if let e = existing {
                dict[key] = max(e, f.pricePerLiter)
            } else {
                dict[key] = f.pricePerLiter
            }
        }
        let allMonths = (0..<min(selectedPeriod.months, 6)).compactMap { offset -> String? in
            guard let d = Calendar.current.date(byAdding: .month, value: -offset, to: Date()) else { return nil }
            return fmt.string(from: d)
        }.reversed()
        return allMonths.map { ($0, dict[$0, default: 0]) }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DNSpacing.lg) {
                    // Vehicle selector
                    if dataStore.vehicles.count > 1 {
                        vehiclePicker
                    }

                    // Period selector
                    periodSelector

                    // Overview cards
                    overviewCards

                    // Monthly expenses bar chart
                    if !monthlyExpenses.isEmpty {
                        monthlyExpensesChart
                    }

                    // Category breakdown
                    if !expensesByCategory.isEmpty {
                        categoryBreakdown
                    }

                    // Fuel trend
                    if !fuelTrend.isEmpty {
                        fuelTrendChart
                    }

                    // Service frequency
                    serviceFrequency

                    // Smart insights
                    smartInsights
                }
                .padding(DNSpacing.md)
            }
            .background(Color(hex: "#12151C").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Analytics")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#F3F5F8"))
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateCharts = true
            }
        }
    }

    // MARK: - Vehicle Picker
    var vehiclePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DNSpacing.sm) {
                ForEach(dataStore.vehicles) { v in
                    Button(action: { selectedVehicleId = v.id }) {
                        Text("\(v.brand) \(v.model)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedVehicleId == v.id || (selectedVehicleId == nil && appState.selectedVehicleId == v.id) ? .white : Color(hex: "#A7B0BE"))
                            .padding(.horizontal, DNSpacing.md)
                            .padding(.vertical, DNSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DNRadius.md)
                                    .fill(selectedVehicleId == v.id || (selectedVehicleId == nil && appState.selectedVehicleId == v.id) ? Color(hex: "#4DA3FF") : Color(hex: "#1C2230"))
                            )
                    }
                }
            }
            .padding(.horizontal, DNSpacing.xs)
        }
    }

    // MARK: - Period Selector
    var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                Button(action: {
                    withAnimation(.dnSpring) { selectedPeriod = period }
                }) {
                    Text(period.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selectedPeriod == period ? .white : Color(hex: "#A7B0BE"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: DNRadius.sm)
                                .fill(selectedPeriod == period ? Color(hex: "#4DA3FF") : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(Color(hex: "#1C2230"))
        .cornerRadius(DNRadius.md)
    }

    // MARK: - Overview Cards
    var overviewCards: some View {
        let fuelTotal = filteredFuelLogs.reduce(0.0) { $0 + $1.totalCost }
        let serviceTotal = filteredServices.reduce(0.0) { $0 + $1.cost }
        let avgMonthly = selectedPeriod.months > 0 ? totalCost / Double(min(selectedPeriod.months, 12)) : totalCost

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DNSpacing.sm) {
            AnalyticsCard(title: "Total Spent", value: NumberHelper.currency(totalCost, appState.currency), icon: "dollarsign.circle.fill", color: Color(hex: "#4DA3FF"))
            AnalyticsCard(title: "Fuel Costs", value: NumberHelper.currency(fuelTotal, appState.currency), icon: "fuelpump.fill", color: Color(hex: "#FF9F43"))
            AnalyticsCard(title: "Service Costs", value: NumberHelper.currency(serviceTotal, appState.currency), icon: "wrench.fill", color: Color(hex: "#45C486"))
            AnalyticsCard(title: "Avg/Month", value: NumberHelper.currency(avgMonthly, appState.currency), icon: "calendar", color: Color(hex: "#9B59B6"))
        }
    }

    // MARK: - Monthly Expenses Chart
    var monthlyExpensesChart: some View {
        let maxVal = monthlyExpenses.map { $0.1 }.max() ?? 1
        return DNCard {
            VStack(alignment: .leading, spacing: DNSpacing.md) {
                DNSectionHeader(title: "Monthly Expenses", subtitle: nil, action: nil)
                HStack(alignment: .bottom, spacing: DNSpacing.sm) {
                    ForEach(Array(monthlyExpenses.enumerated()), id: \.0) { idx, item in
                        VStack(spacing: 4) {
                            Text(NumberHelper.shortCurrency(item.1, appState.currency))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Color(hex: "#A7B0BE"))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient.dnBlueGradient)
                                .frame(height: animateCharts ? CGFloat(item.1 / maxVal) * 100 : 0)
                                .animation(.dnSpring.delay(Double(idx) * 0.05), value: animateCharts)
                            Text(item.0)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "#A7B0BE"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 130)
            }
        }
    }

    // MARK: - Category Breakdown
    var categoryBreakdown: some View {
        DNCard {
            VStack(alignment: .leading, spacing: DNSpacing.md) {
                DNSectionHeader(title: "By Category", subtitle: nil, action: nil)
                let topCategories = Array(expensesByCategory.prefix(6))
                let total = topCategories.reduce(0.0) { $0 + $1.1 }
                ForEach(Array(topCategories.enumerated()), id: \.0) { idx, item in
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: item.0.icon)
                                .font(.system(size: 13))
                                .foregroundColor(item.0.color)
                                .frame(width: 24)
                            Text(item.0.rawValue)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "#F3F5F8"))
                            Spacer()
                            Text(NumberHelper.currency(item.1, appState.currency))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "#F3F5F8"))
                            Text("(\(Int(total > 0 ? item.1 / total * 100 : 0))%)")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "#A7B0BE"))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(hex: "#2A3447"))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(item.0.color)
                                    .frame(width: animateCharts ? geo.size.width * CGFloat(total > 0 ? item.1 / total : 0) : 0, height: 6)
                                    .animation(.dnSpring.delay(Double(idx) * 0.06), value: animateCharts)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
    }

    // MARK: - Fuel Trend
    var fuelTrendChart: some View {
        let points = fuelTrend.filter { $0.1 > 0 }
        guard points.count >= 2 else {
            return AnyView(EmptyView())
        }
        let maxVal = points.map { $0.1 }.max() ?? 1
        let minVal = points.map { $0.1 }.min() ?? 0
        return AnyView(
            DNCard {
                VStack(alignment: .leading, spacing: DNSpacing.md) {
                    DNSectionHeader(title: "Fuel Price Trend", subtitle: nil, action: nil)
                    GeometryReader { geo in
                        ZStack {
                            // Grid lines
                            ForEach(0..<4) { i in
                                Path { path in
                                    let y = geo.size.height * CGFloat(i) / 3
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                                }
                                .stroke(Color(hex: "#2A3447"), lineWidth: 1)
                            }
                            if animateCharts {
                                // Line
                                Path { path in
                                    let range = maxVal - minVal
                                    for (idx, pt) in points.enumerated() {
                                        let x = geo.size.width * CGFloat(idx) / CGFloat(points.count - 1)
                                        let y = geo.size.height * (1 - CGFloat((pt.1 - minVal) / (range > 0 ? range : 1)))
                                        if idx == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                                    }
                                }
                                .stroke(Color(hex: "#FF9F43"), lineWidth: 2)

                                // Dots
                                ForEach(Array(points.enumerated()), id: \.0) { idx, pt in
                                    let range = maxVal - minVal
                                    let x = geo.size.width * CGFloat(idx) / CGFloat(points.count - 1)
                                    let y = geo.size.height * (1 - CGFloat((pt.1 - minVal) / (range > 0 ? range : 1)))
                                    Circle()
                                        .fill(Color(hex: "#FF9F43"))
                                        .frame(width: 8, height: 8)
                                        .position(x: x, y: y)
                                }
                            }
                        }
                    }
                    .frame(height: 100)
                    HStack {
                        ForEach(Array(points.enumerated()), id: \.0) { _, pt in
                            Text(pt.0)
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "#A7B0BE"))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        )
    }

    // MARK: - Service Frequency
    var serviceTypeCounts: [(key: ServiceRecord.ServiceType, value: Int)] {
        var counts = [ServiceRecord.ServiceType: Int]()
        filteredServices.forEach { counts[$0.serviceType, default: 0] += 1 }
        return counts.sorted { $0.value > $1.value }
    }

    var serviceFrequency: some View {
        DNCard {
            VStack(alignment: .leading, spacing: DNSpacing.md) {
                DNSectionHeader(title: "Service Frequency", subtitle: nil, action: nil)
                if filteredServices.isEmpty {
                    DNEmptyState(icon: "wrench.fill", title: "No Services", message: "No service records in this period", action: nil)
                } else {
                    let sorted = serviceTypeCounts
                    ForEach(Array(sorted.prefix(5).enumerated()), id: \.0) { _, item in
                        HStack(spacing: DNSpacing.sm) {
                            Image(systemName: item.key.icon)
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#4DA3FF"))
                                .frame(width: 24)
                            Text(item.key.rawValue)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "#F3F5F8"))
                            Spacer()
                            Text("\(item.value)x")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#4DA3FF"))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Smart Insights
    var smartInsights: some View {
        let insights = generateInsights()
        guard !insights.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: DNSpacing.sm) {
                Text("Smart Insights")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#F3F5F8"))
                ForEach(Array(insights.enumerated()), id: \.0) { _, insight in
                    DNAlertCard(title: insight.title, message: insight.message, type: insight.type)
                }
            }
        )
    }

    func generateInsights() -> [(type: DNAlertCard.MascotType, title: String, message: String)] {
        var insights = [(type: DNAlertCard.MascotType, title: String, message: String)]()
        guard let v = vehicle else { return insights }

        // Fuel cost trend
        let fuelCosts = filteredFuelLogs.map { $0.totalCost }
        if fuelCosts.count >= 2 {
            let recent = fuelCosts.prefix(fuelCosts.count / 2).reduce(0, +)
            let older = fuelCosts.suffix(fuelCosts.count / 2).reduce(0, +)
            if recent > older * 1.15 {
                insights.append((.warning, "Fuel Costs Rising", "Your fuel spending has increased compared to the previous period."))
            }
        }

        // Service gap
        let lastService = filteredServices.sorted(by: { $0.date > $1.date }).first
        if let ls = lastService {
            let daysSince = Calendar.current.dateComponents([.day], from: ls.date, to: Date()).day ?? 0
            if daysSince > 180 {
                insights.append((.danger, "Long Service Gap", "No service recorded in \(daysSince) days. Consider scheduling a checkup."))
            }
        } else {
            insights.append((.info, "No Services Logged", "Start tracking your service history for better insights."))
        }

        // Mileage insight
        if v.currentMileage > 100000 {
            insights.append((.warning, "High Mileage Vehicle", "Your vehicle has over 100,000 km. Stay on top of maintenance."))
        }

        // Insurance expiry
        let insurance = dataStore.insuranceRecords.filter { $0.vehicleId == v.id }
        if let ins = insurance.sorted(by: { $0.endDate > $1.endDate }).first {
            if ins.daysRemaining < 30 && ins.daysRemaining >= 0 {
                insights.append((.danger, "Insurance Expiring", "Your insurance expires in \(ins.daysRemaining) days."))
            }
        }

        return insights
    }
}

// MARK: - Analytics Card
struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        DNCard {
            VStack(alignment: .leading, spacing: DNSpacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                    Spacer()
                }
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#F3F5F8"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#A7B0BE"))
            }
        }
    }
}

// MARK: - Achievements View
struct AchievementsView: View {
    @EnvironmentObject var dataStore: DataStore

    struct Achievement: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
        let isUnlocked: Bool
        let color: Color
    }

    var achievements: [Achievement] {
        let hasFuelLog = !dataStore.fuelLogs.isEmpty
        let hasService = !dataStore.serviceRecords.isEmpty
        let hasTrip = !dataStore.trips.isEmpty
        let serviceCount = dataStore.serviceRecords.count
        let tripCount = dataStore.trips.count
        let fuelCount = dataStore.fuelLogs.count
        let fulltankCount = dataStore.fuelLogs.filter { $0.fullTank }.count
        let allChecked = dataStore.checklistItems.allSatisfy { $0.isChecked }

        return [
            Achievement(icon: "car.fill", title: "First Ride", description: "Added your first vehicle", isUnlocked: !dataStore.vehicles.isEmpty, color: Color(hex: "#4DA3FF")),
            Achievement(icon: "wrench.fill", title: "Service Master", description: "Logged 5+ service records", isUnlocked: serviceCount >= 5, color: Color(hex: "#45C486")),
            Achievement(icon: "fuelpump.fill", title: "Full Tank Hero", description: "Logged a full tank refuel", isUnlocked: fulltankCount > 0, color: Color(hex: "#FF9F43")),
            Achievement(icon: "map.fill", title: "Road Warrior", description: "Logged 10+ trips", isUnlocked: tripCount >= 10, color: Color(hex: "#9B59B6")),
            Achievement(icon: "checkmark.seal.fill", title: "Pre-Trip Pro", description: "Completed a full checklist", isUnlocked: allChecked, color: Color(hex: "#45C486")),
            Achievement(icon: "clock.fill", title: "Service On Time", description: "No overdue service records", isUnlocked: hasService, color: Color(hex: "#4DA3FF")),
            Achievement(icon: "chart.bar.fill", title: "Data Nerd", description: "Logged 20+ expenses", isUnlocked: dataStore.expenses.count >= 20, color: Color(hex: "#FF9F43")),
            Achievement(icon: "star.fill", title: "Smooth Driver", description: "No critical problems logged", isUnlocked: !dataStore.problemLogs.contains(where: { $0.severity == .critical }), color: Color(hex: "#FFD700")),
            Achievement(icon: "drop.fill", title: "Fuel Tracker", description: "Logged 10+ fuel entries", isUnlocked: fuelCount >= 10, color: Color(hex: "#4DA3FF")),
            Achievement(icon: "photo.fill", title: "Photo Journalist", description: "Added 5+ photos", isUnlocked: dataStore.photos.count >= 5, color: Color(hex: "#E74C3C")),
        ]
    }

    var unlockedCount: Int { achievements.filter { $0.isUnlocked }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                // Progress
                DNCard {
                    VStack(spacing: DNSpacing.sm) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(unlockedCount)/\(achievements.count)")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color(hex: "#F3F5F8"))
                                Text("Achievements Unlocked")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "#A7B0BE"))
                            }
                            Spacer()
                            ZStack {
                                Circle()
                                    .stroke(Color(hex: "#2A3447"), lineWidth: 6)
                                Circle()
                                    .trim(from: 0, to: CGFloat(unlockedCount) / CGFloat(achievements.count))
                                    .stroke(Color(hex: "#4DA3FF"), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                Text("\(Int(CGFloat(unlockedCount) / CGFloat(achievements.count) * 100))%")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(hex: "#4DA3FF"))
                            }
                            .frame(width: 60, height: 60)
                        }
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DNSpacing.sm) {
                    ForEach(achievements) { ach in
                        AchievementCard(achievement: ach)
                    }
                }
            }
            .padding(DNSpacing.md)
        }
        .background(Color(hex: "#12151C").ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Achievements")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#F3F5F8"))
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: AchievementsView.Achievement

    var body: some View {
        DNCard {
            VStack(spacing: DNSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(achievement.isUnlocked ? achievement.color.opacity(0.2) : Color(hex: "#2A3447"))
                        .frame(width: 50, height: 50)
                    Image(systemName: achievement.icon)
                        .font(.system(size: 22))
                        .foregroundColor(achievement.isUnlocked ? achievement.color : Color(hex: "#4A5568"))
                }
                Text(achievement.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(achievement.isUnlocked ? Color(hex: "#F3F5F8") : Color(hex: "#4A5568"))
                    .multilineTextAlignment(.center)
                Text(achievement.description)
                    .font(.system(size: 11))
                    .foregroundColor(achievement.isUnlocked ? Color(hex: "#A7B0BE") : Color(hex: "#3A4557"))
                    .multilineTextAlignment(.center)
                if achievement.isUnlocked {
                    DNBadge(text: "Unlocked", color: achievement.color, filled: true)
                } else {
                    DNBadge(text: "Locked", color: Color(hex: "#4A5568"), filled: false)
                }
            }
            .padding(.vertical, DNSpacing.xs)
        }
    }
}
