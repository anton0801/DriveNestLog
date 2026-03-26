import SwiftUI

// MARK: - Expense Tracker View
struct ExpenseTrackerView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false
    @State private var selectedCategory: Expense.ExpenseCategory? = nil
    @State private var selectedMonth = Date()
    
    var selectedVehicle: Vehicle? {
        guard let id = appState.selectedVehicleId else { return dataStore.vehicles.first }
        return dataStore.vehicles.first(where: { $0.id == id }) ?? dataStore.vehicles.first
    }
    
    var filteredExpenses: [Expense] {
        guard let v = selectedVehicle else { return [] }
        let cal = Calendar.current
        var list = dataStore.expenses.filter { $0.vehicleId == v.id && cal.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
        if let cat = selectedCategory { list = list.filter { $0.category == cat } }
        return list.sorted { $0.date > $1.date }
    }
    
    var totalThisMonth: Double { filteredExpenses.reduce(0) { $0 + $1.amount } }
    
    var categoryTotals: [(Expense.ExpenseCategory, Double)] {
        guard let v = selectedVehicle else { return [] }
        let cal = Calendar.current
        let monthExpenses = dataStore.expenses.filter { $0.vehicleId == v.id && cal.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
        var totals: [Expense.ExpenseCategory: Double] = [:]
        for e in monthExpenses { totals[e.category, default: 0] += e.amount }
        return totals.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                // Header
                HStack {
                    DNSectionHeader(title: "Expenses", subtitle: selectedVehicle?.displayName ?? "No vehicle", action: {
                        
                    }, actionTitle: "")
                    Spacer()
                    Button(action: { showAdd = true }) {
                        ZStack {
                            Circle().fill(Color.dnAccentBlue).frame(width: 36, height: 36)
                            Image(systemName: "plus").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, DNSpacing.md)
                .padding(.top, DNSpacing.md)
                
                // Month picker
                HStack {
                    Button(action: {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    }) {
                        Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.dnAccentBlue)
                    }
                    Spacer()
                    Text(monthYearString(selectedMonth))
                        .font(DNFont.heading(16)).foregroundColor(.dnText)
                    Spacer()
                    Button(action: {
                        let next = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                        if next <= Date() { selectedMonth = next }
                    }) {
                        Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month) ? Color.dnTextSecondary.opacity(0.3) : Color.dnAccentBlue)
                    }
                }
                .padding(.horizontal, DNSpacing.lg)
                
                // Total card
                DNCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Total This Month")
                                .font(DNFont.label(13)).foregroundColor(.dnTextSecondary)
                            Text(NumberHelper.currency(totalThisMonth, appState.currency))
                                .font(DNFont.display(28)).foregroundColor(.dnText)
                        }
                        Spacer()
                        ChickenMascot(type: .service, size: 40)
                    }
                }
                .padding(.horizontal, DNSpacing.md)
                
                // Category breakdown
                if !categoryTotals.isEmpty {
                    VStack(alignment: .leading, spacing: DNSpacing.md) {
                        DNSectionHeader(title: "By Category")
                            .padding(.horizontal, DNSpacing.md)
                        
                        ForEach(categoryTotals, id: \.0) { cat, amount in
                            CategoryExpenseRow(category: cat, amount: amount, total: totalThisMonth, currency: appState.currency, isSelected: selectedCategory == cat) {
                                withAnimation(.dnFast) {
                                    selectedCategory = selectedCategory == cat ? nil : cat
                                }
                            }
                            .padding(.horizontal, DNSpacing.md)
                        }
                    }
                }
                
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedCategory == nil) { selectedCategory = nil }
                        ForEach(Expense.ExpenseCategory.allCases, id: \.self) { cat in
                            FilterChip(title: cat.rawValue, color: cat.color, isSelected: selectedCategory == cat) { selectedCategory = cat }
                        }
                    }
                    .padding(.horizontal, DNSpacing.md)
                }
                
                // Expense list
                if filteredExpenses.isEmpty {
                    DNEmptyState(icon: "creditcard.fill", title: "No Expenses", message: "Start tracking your car expenses this month.", actionTitle: "Add Expense", action: { showAdd = true })
                } else {
                    VStack(spacing: DNSpacing.sm) {
                        ForEach(filteredExpenses) { expense in
                            ExpenseCard(expense: expense)
                                .padding(.horizontal, DNSpacing.md)
                        }
                    }
                }
                
                Color.clear.frame(height: 90)
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
        .sheet(isPresented: $showAdd) {
            if let v = selectedVehicle {
                AddExpenseView(vehicleId: v.id)
            } else {
                NoVehicleView()
            }
        }
    }
    
    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

struct CategoryExpenseRow: View {
    let category: Expense.ExpenseCategory
    let amount: Double
    let total: Double
    let currency: String
    let isSelected: Bool
    let action: () -> Void
    
    var percentage: Double { total > 0 ? (amount / total) * 100 : 0 }
    
    var body: some View {
        Button(action: action) {
            DNCard {
                HStack(spacing: DNSpacing.md) {
                    ZStack {
                        Circle().fill(category.color.opacity(0.15)).frame(width: 38, height: 38)
                        Image(systemName: category.icon).font(.system(size: 16)).foregroundColor(category.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(category.rawValue).font(DNFont.label(13)).foregroundColor(.dnText)
                            Spacer()
                            Text(NumberHelper.currency(amount, currency)).font(DNFont.mono(13)).foregroundColor(category.color)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2).fill(category.color.opacity(0.15)).frame(height: 4)
                                RoundedRectangle(cornerRadius: 2).fill(category.color)
                                    .frame(width: geo.size.width * CGFloat(percentage / 100), height: 4)
                                    .animation(.dnSpring, value: percentage)
                            }
                        }
                        .frame(height: 4)
                    }
                    
                    Text(String(format: "%.0f%%", percentage))
                        .font(DNFont.mono(12)).foregroundColor(.dnTextSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: DNRadius.lg)
                .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
        )
    }
}

struct ExpenseCard: View {
    let expense: Expense
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var showDelete = false
    
    var body: some View {
        DNCard {
            HStack(spacing: DNSpacing.md) {
                ZStack {
                    Circle().fill(expense.category.color.opacity(0.15)).frame(width: 42, height: 42)
                    Image(systemName: expense.category.icon).font(.system(size: 18)).foregroundColor(expense.category.color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.description.isEmpty ? expense.category.rawValue : expense.description)
                        .font(DNFont.label(14)).foregroundColor(.dnText)
                    Text(NumberHelper.shortDate(expense.date))
                        .font(DNFont.body(12)).foregroundColor(.dnTextSecondary)
                }
                Spacer()
                Text(NumberHelper.currency(expense.amount, appState.currency))
                    .font(DNFont.mono(15)).foregroundColor(expense.category.color)
            }
        }
        .contextMenu {
            Button(role: .destructive, action: { showDelete = true }) { Label("Delete", systemImage: "trash") }
        }
        .alert("Delete Expense", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { dataStore.deleteExpense(expense) }
        }
    }
}

// MARK: - Add Expense View
struct AddExpenseView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var category = Expense.ExpenseCategory.service
    @State private var amount = ""
    @State private var date = Date()
    @State private var description = ""
    @State private var notes = ""
    @State private var showSuccess = false
    @State private var showError = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                DNNavBar(title: "Add Expense", trailingContent: AnyView(EmptyView()))
                
                VStack(spacing: DNSpacing.md) {
                    // Category grid
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Category").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(Expense.ExpenseCategory.allCases, id: \.self) { cat in
                                Button(action: { category = cat }) {
                                    VStack(spacing: 5) {
                                        ZStack {
                                            Circle().fill(cat.color.opacity(category == cat ? 1 : 0.15))
                                                .frame(width: 42, height: 42)
                                            Image(systemName: cat.icon).font(.system(size: 18))
                                                .foregroundColor(category == cat ? .white : cat.color)
                                        }
                                        Text(cat.rawValue).font(DNFont.label(9)).foregroundColor(category == cat ? cat.color : .dnTextSecondary)
                                            .lineLimit(1).minimumScaleFactor(0.7)
                                    }
                                }
                            }
                        }
                    }
                    
                    DNTextField(title: "Amount (\(appState.currency))", text: $amount, icon: "dollarsign.circle.fill", keyboardType: .decimalPad)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact).labelsHidden()
                            .padding(.horizontal, DNSpacing.md).padding(.vertical, 10)
                            .background(Color.dnCardElevated).cornerRadius(DNRadius.md).colorScheme(.dark)
                    }
                    
                    DNTextField(title: "Description", text: $description, icon: "text.alignleft")
                    DNTextField(title: "Notes", text: $notes, icon: "note.text")
                }
                .padding(.horizontal, DNSpacing.md)
                
                if showError { DNAlertCard(title: "Error", message: "Please enter an amount.", type: .danger).padding(.horizontal, DNSpacing.md) }
                if showSuccess { DNAlertCard(title: "Expense Added!", message: "Expense recorded.", type: .success).padding(.horizontal, DNSpacing.md) }
                
                DNButton("Save Expense") { saveExpense() }
                    .padding(.horizontal, DNSpacing.md).padding(.bottom, DNSpacing.xxl)
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
    }
    
    private func saveExpense() {
        guard !amount.isEmpty, let amountDouble = Double(amount), amountDouble > 0 else { showError = true; return }
        let expense = Expense(vehicleId: vehicleId, category: category, amount: amountDouble,
                              date: date, description: description, notes: notes)
        dataStore.addExpense(expense)
        withAnimation(.dnSpring) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { presentationMode.wrappedValue.dismiss() }
    }
}

// MARK: - Trip List View
struct TripListView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var showAdd = false
    
    var trips: [Trip] { dataStore.trips.filter { $0.vehicleId == vehicleId }.sorted { $0.startDate > $1.startDate } }
    
    var body: some View {
        VStack(spacing: 0) {
            DNNavBar(title: "Trip Assistant", subtitle: "\(trips.count) trips",
                     trailingContent: AnyView(
                        Button(action: { showAdd = true }) {
                            ZStack {
                                Circle().fill(Color.dnGreen).frame(width: 34, height: 34)
                                Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            }
                        }
                     ))
            
            if trips.isEmpty {
                DNEmptyState(icon: "map.fill", title: "No Trips Yet", message: "Log your journeys and track distance, fuel, and costs.", actionTitle: "Add Trip", action: { showAdd = true })
            } else {
                ScrollView {
                    VStack(spacing: DNSpacing.sm) {
                        ForEach(trips) { trip in TripCard(trip: trip) }
                        Color.clear.frame(height: 30)
                    }
                    .padding(.horizontal, DNSpacing.md).padding(.top, DNSpacing.sm)
                }
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
        .sheet(isPresented: $showAdd) { AddTripView(vehicleId: vehicleId) }
    }
}

struct TripCard: View {
    let trip: Trip
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var showDelete = false
    
    var body: some View {
        DNCard {
            VStack(alignment: .leading, spacing: DNSpacing.sm) {
                HStack {
                    HStack(spacing: DNSpacing.sm) {
                        ChickenMascot(type: .trip, size: 34)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(trip.name).font(DNFont.heading(15)).foregroundColor(.dnText)
                            Text(NumberHelper.shortDate(trip.startDate)).font(DNFont.body(12)).foregroundColor(.dnTextSecondary)
                        }
                    }
                    Spacer()
                    if let dist = trip.distance {
                        Text(NumberHelper.distance(dist, unit: appState.distanceUnit))
                            .font(DNFont.mono(15)).foregroundColor(.dnGreen)
                    }
                }
                
                HStack(spacing: DNSpacing.md) {
                    if let fuel = trip.fuelUsed {
                        Label(NumberHelper.fuel(fuel, unit: appState.fuelUnit), systemImage: "fuelpump.fill")
                            .font(DNFont.body(12)).foregroundColor(.dnTextSecondary)
                    }
                    if trip.costs > 0 {
                        Label(NumberHelper.currency(trip.costs, appState.currency), systemImage: "creditcard.fill")
                            .font(DNFont.body(12)).foregroundColor(.dnTextSecondary)
                    }
                }
                
                if !trip.notes.isEmpty {
                    Text(trip.notes).font(DNFont.body(12)).foregroundColor(.dnTextSecondary).lineLimit(2)
                }
            }
        }
        .contextMenu {
            Button(role: .destructive, action: { showDelete = true }) { Label("Delete", systemImage: "trash") }
        }
        .alert("Delete Trip", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { dataStore.deleteTrip(trip) }
        }
    }
}

// MARK: - Add Trip View
struct AddTripView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var startMileage = ""
    @State private var endMileage = ""
    @State private var fuelUsed = ""
    @State private var costs = ""
    @State private var notes = ""
    @State private var isOngoing = false
    @State private var showSuccess = false
    @State private var showError = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                DNNavBar(title: "Add Trip", trailingContent: AnyView(EmptyView()))
                
                VStack(spacing: DNSpacing.md) {
                    DNTextField(title: "Trip Name", text: $name, placeholder: "e.g. Weekend Road Trip", icon: "map.fill")
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Start Date").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(.compact).labelsHidden()
                            .padding(.horizontal, DNSpacing.md).padding(.vertical, 10)
                            .background(Color.dnCardElevated).cornerRadius(DNRadius.md).colorScheme(.dark)
                    }
                    
                    // Ongoing toggle
                    HStack {
                        Text("Ongoing Trip").font(DNFont.label(14)).foregroundColor(.dnText)
                        Spacer()
                        Toggle("", isOn: $isOngoing).tint(.dnAccentBlue)
                    }
                    .padding(.horizontal, DNSpacing.md).padding(.vertical, 13)
                    .background(Color.dnCardElevated).cornerRadius(DNRadius.md)
                    
                    if !isOngoing {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("End Date").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                            DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                                .datePickerStyle(.compact).labelsHidden()
                                .padding(.horizontal, DNSpacing.md).padding(.vertical, 10)
                                .background(Color.dnCardElevated).cornerRadius(DNRadius.md).colorScheme(.dark)
                        }
                    }
                    
                    DNTextField(title: "Start Mileage (\(appState.distanceUnit))", text: $startMileage, icon: "speedometer", keyboardType: .decimalPad)
                    
                    if !isOngoing {
                        DNTextField(title: "End Mileage (\(appState.distanceUnit))", text: $endMileage, icon: "speedometer", keyboardType: .decimalPad)
                    }
                    
                    DNTextField(title: "Fuel Used (\(appState.fuelUnit))", text: $fuelUsed, icon: "fuelpump.fill", keyboardType: .decimalPad)
                    DNTextField(title: "Total Costs (\(appState.currency))", text: $costs, icon: "creditcard.fill", keyboardType: .decimalPad)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        TextEditor(text: $notes).frame(height: 80).padding(8)
                            .background(Color.dnCardElevated).cornerRadius(DNRadius.md)
                            .foregroundColor(.dnText).font(DNFont.body(15))
                    }
                }
                .padding(.horizontal, DNSpacing.md)
                
                if showError { DNAlertCard(title: "Error", message: "Please enter a trip name and start mileage.", type: .danger).padding(.horizontal, DNSpacing.md) }
                if showSuccess { DNAlertCard(title: "Trip Added!", message: "Journey recorded.", type: .success).padding(.horizontal, DNSpacing.md) }
                
                DNButton("Save Trip", gradient: .dnGreenGradient) { saveTrip() }
                    .padding(.horizontal, DNSpacing.md).padding(.bottom, DNSpacing.xxl)
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
    }
    
    private func saveTrip() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty, !startMileage.isEmpty else { showError = true; return }
        let trip = Trip(vehicleId: vehicleId, name: name, startDate: startDate,
                        endDate: isOngoing ? nil : endDate,
                        startMileage: Double(startMileage) ?? 0,
                        endMileage: isOngoing ? nil : Double(endMileage),
                        fuelUsed: fuelUsed.isEmpty ? nil : Double(fuelUsed),
                        costs: Double(costs) ?? 0, notes: notes, photoData: [])
        dataStore.addTrip(trip)
        withAnimation(.dnSpring) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { presentationMode.wrappedValue.dismiss() }
    }
}

// MARK: - Pre-Trip Checklist View
struct PreTripChecklistView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedCategory: ChecklistItem.ChecklistCategory = .cityDrive
    
    var items: [ChecklistItem] { dataStore.checklistItems.filter { $0.category == selectedCategory } }
    var completedCount: Int { items.filter { $0.isChecked }.count }
    var isComplete: Bool { completedCount == items.count && !items.isEmpty }
    
    var body: some View {
        VStack(spacing: 0) {
            DNNavBar(title: "Pre-Trip Checklist", subtitle: "\(completedCount)/\(items.count) done",
                     trailingContent: AnyView(EmptyView()))
            
            // Category selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ChecklistItem.ChecklistCategory.allCases, id: \.self) { cat in
                        Button(action: { withAnimation(.dnFast) { selectedCategory = cat } }) {
                            Text(cat.rawValue).font(DNFont.label(13))
                                .foregroundColor(selectedCategory == cat ? .white : .dnTextSecondary)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(selectedCategory == cat ? Color.dnAccentBlue : Color.dnCard)
                                .cornerRadius(DNRadius.pill)
                        }
                    }
                }
                .padding(.horizontal, DNSpacing.md)
            }
            .padding(.vertical, DNSpacing.sm)
            
            // Progress bar
            VStack(spacing: 8) {
                HStack {
                    Text(isComplete ? "✅ All Done!" : "\(completedCount) of \(items.count) items checked")
                        .font(DNFont.label(13)).foregroundColor(isComplete ? .dnGreen : .dnTextSecondary)
                    Spacer()
                    Button(action: { dataStore.resetChecklist(category: selectedCategory) }) {
                        Text("Reset").font(DNFont.label(12)).foregroundColor(.dnAccentBlue)
                    }
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.dnBorder).frame(height: 6)
                        RoundedRectangle(cornerRadius: 4).fill(isComplete ? Color.dnGreen : Color.dnAccentBlue)
                            .frame(width: items.isEmpty ? 0 : geo.size.width * CGFloat(completedCount) / CGFloat(items.count), height: 6)
                            .animation(.dnSpring, value: completedCount)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, DNSpacing.md)
            .padding(.bottom, DNSpacing.sm)
            
            ScrollView {
                VStack(spacing: DNSpacing.sm) {
                    ForEach(items) { item in
                        ChecklistRowView(item: item)
                            .padding(.horizontal, DNSpacing.md)
                    }
                    Color.clear.frame(height: 30)
                }
                .padding(.top, DNSpacing.sm)
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
    }
}

struct ChecklistRowView: View {
    let item: ChecklistItem
    @EnvironmentObject var dataStore: DataStore
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            withAnimation(.dnFast) { scale = 0.96 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.dnSpring) { scale = 1.0 }
                dataStore.toggleChecklistItem(item)
            }
        }) {
            DNCard {
                HStack(spacing: DNSpacing.md) {
                    ZStack {
                        Circle()
                            .stroke(item.isChecked ? Color.dnGreen : Color.dnBorder, lineWidth: 2)
                            .frame(width: 26, height: 26)
                        if item.isChecked {
                            Circle().fill(Color.dnGreen).frame(width: 26, height: 26)
                            Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                        }
                    }
                    
                    Text(item.title)
                        .font(DNFont.label(14))
                        .foregroundColor(item.isChecked ? .dnTextSecondary : .dnText)
                        .strikethrough(item.isChecked, color: .dnTextSecondary)
                    
                    Spacer()
                }
            }
            .scaleEffect(scale)
        }
        .buttonStyle(.plain)
    }
}
