import SwiftUI

// MARK: - Service Log View
struct ServiceLogView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var showAdd = false
    @State private var selectedRecord: ServiceRecord? = nil
    
    var records: [ServiceRecord] { dataStore.vehicleServices(vehicleId) }
    
    var body: some View {
        VStack(spacing: 0) {
            DNNavBar(title: "Service Log", subtitle: "\(records.count) records",
                     trailingContent: AnyView(
                        Button(action: { showAdd = true }) {
                            ZStack {
                                Circle().fill(Color.dnAccentBlue).frame(width: 34, height: 34)
                                Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            }
                        }
                     ))
            
            if records.isEmpty {
                DNEmptyState(icon: "wrench.fill", title: "No Services Yet", message: "Record your first service to track maintenance history.", actionTitle: "Add Service", action: { showAdd = true })
            } else {
                ScrollView {
                    VStack(spacing: DNSpacing.sm) {
                        ForEach(records) { record in
                            ServiceDetailCard(record: record)
                                .onTapGesture { selectedRecord = record }
                        }
                        Color.clear.frame(height: 30)
                    }
                    .padding(.horizontal, DNSpacing.md)
                    .padding(.top, DNSpacing.sm)
                }
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
        .sheet(isPresented: $showAdd) { AddServiceView(vehicleId: vehicleId) }
        .sheet(item: $selectedRecord) { r in EditServiceView(record: r) }
    }
}

struct ServiceDetailCard: View {
    let record: ServiceRecord
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var showDelete = false
    
    var body: some View {
        DNCard {
            VStack(alignment: .leading, spacing: DNSpacing.sm) {
                HStack {
                    HStack(spacing: DNSpacing.sm) {
                        ZStack {
                            Circle().fill(Color.dnAccentBlue.opacity(0.15)).frame(width: 40, height: 40)
                            Image(systemName: record.serviceType.icon).font(.system(size: 18)).foregroundColor(.dnAccentBlue)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(record.serviceType.rawValue).font(DNFont.heading(15)).foregroundColor(.dnText)
                            Text(NumberHelper.shortDate(record.date)).font(DNFont.body(12)).foregroundColor(.dnTextSecondary)
                        }
                    }
                    Spacer()
                    Text(NumberHelper.currency(record.cost, appState.currency))
                        .font(DNFont.mono(15))
                        .foregroundColor(.dnAccentOrange)
                }
                
                Divider().background(Color.dnBorder)
                
                HStack {
                    Label(NumberHelper.distance(record.mileage, unit: appState.distanceUnit), systemImage: "speedometer")
                        .font(DNFont.body(12)).foregroundColor(.dnTextSecondary)
                    Spacer()
                    if !record.garageName.isEmpty {
                        Label(record.garageName, systemImage: "building.2.fill")
                            .font(DNFont.body(12)).foregroundColor(.dnTextSecondary)
                            .lineLimit(1)
                    }
                }
                
                if !record.notes.isEmpty {
                    Text(record.notes).font(DNFont.body(12)).foregroundColor(.dnTextSecondary).lineLimit(2)
                }
                
                if !record.partsUsed.isEmpty {
                    DNBadge(text: "Parts: \(record.partsUsed)", color: .dnGreen)
                }
            }
        }
        .contextMenu {
            Button(role: .destructive, action: { showDelete = true }) { Label("Delete", systemImage: "trash") }
        }
        .alert("Delete Service Record", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { dataStore.deleteService(record) }
        }
    }
}

// MARK: - Add Service View
struct AddServiceView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var serviceType = ServiceRecord.ServiceType.oilChange
    @State private var date = Date()
    @State private var mileage = ""
    @State private var cost = ""
    @State private var garageName = ""
    @State private var partsUsed = ""
    @State private var notes = ""
    @State private var showSuccess = false
    @State private var showError = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                DNNavBar(title: "Add Service", trailingContent: AnyView(EmptyView()))
                
                VStack(spacing: DNSpacing.md) {
                    // Service Type
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Service Type").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ServiceRecord.ServiceType.allCases, id: \.self) { type in
                                    Button(action: { serviceType = type }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: type.icon).font(.system(size: 13))
                                            Text(type.rawValue).font(DNFont.label(12))
                                        }
                                        .foregroundColor(serviceType == type ? .white : .dnTextSecondary)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(serviceType == type ? Color.dnAccentBlue : Color.dnCardElevated)
                                        .cornerRadius(DNRadius.pill)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Date
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(.horizontal, DNSpacing.md).padding(.vertical, 10)
                            .background(Color.dnCardElevated).cornerRadius(DNRadius.md)
                            .colorScheme(.dark)
                    }
                    
                    DNTextField(title: "Mileage (\(appState.distanceUnit))", text: $mileage, icon: "speedometer", keyboardType: .decimalPad)
                    DNTextField(title: "Cost (\(appState.currency))", text: $cost, icon: "dollarsign.circle.fill", keyboardType: .decimalPad)
                    DNTextField(title: "Garage / Mechanic", text: $garageName, icon: "building.2.fill")
                    DNTextField(title: "Parts Used", text: $partsUsed, icon: "gearshape.fill")
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        TextEditor(text: $notes)
                            .frame(height: 80).padding(8)
                            .background(Color.dnCardElevated).cornerRadius(DNRadius.md)
                            .foregroundColor(.dnText).font(DNFont.body(15))
                    }
                }
                .padding(.horizontal, DNSpacing.md)
                
                if showError { DNAlertCard(title: "Error", message: "Please fill in mileage and cost.", type: .danger).padding(.horizontal, DNSpacing.md) }
                if showSuccess { DNAlertCard(title: "Service Added!", message: "Record saved.", type: .success).padding(.horizontal, DNSpacing.md) }
                
                DNButton("Save Service") { saveService() }
                    .padding(.horizontal, DNSpacing.md)
                    .padding(.bottom, DNSpacing.xxl)
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
    }
    
    private func saveService() {
        guard !mileage.isEmpty, !cost.isEmpty else { showError = true; return }
        let record = ServiceRecord(vehicleId: vehicleId, serviceType: serviceType, date: date,
                                   mileage: Double(mileage) ?? 0, cost: Double(cost) ?? 0,
                                   garageName: garageName, partsUsed: partsUsed, notes: notes)
        dataStore.addService(record)
        withAnimation(.dnSpring) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { presentationMode.wrappedValue.dismiss() }
    }
}

struct EditServiceView: View {
    let record: ServiceRecord
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var cost: String
    @State private var garageName: String
    @State private var partsUsed: String
    @State private var notes: String
    @State private var showSuccess = false
    
    init(record: ServiceRecord) {
        self.record = record
        _cost = State(initialValue: String(format: "%.2f", record.cost))
        _garageName = State(initialValue: record.garageName)
        _partsUsed = State(initialValue: record.partsUsed)
        _notes = State(initialValue: record.notes)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                DNNavBar(title: "Edit Service", trailingContent: AnyView(EmptyView()))
                VStack(spacing: DNSpacing.md) {
                    DNTextField(title: "Cost (\(appState.currency))", text: $cost, icon: "dollarsign.circle.fill", keyboardType: .decimalPad)
                    DNTextField(title: "Garage / Mechanic", text: $garageName, icon: "building.2.fill")
                    DNTextField(title: "Parts Used", text: $partsUsed, icon: "gearshape.fill")
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        TextEditor(text: $notes).frame(height: 80).padding(8)
                            .background(Color.dnCardElevated).cornerRadius(DNRadius.md)
                            .foregroundColor(.dnText).font(DNFont.body(15))
                    }
                }.padding(.horizontal, DNSpacing.md)
                if showSuccess { DNAlertCard(title: "Saved!", message: "Service record updated.", type: .success).padding(.horizontal, DNSpacing.md) }
                DNButton("Save Changes") {
                    var updated = record
                    updated.cost = Double(cost) ?? record.cost
                    updated.garageName = garageName
                    updated.partsUsed = partsUsed
                    updated.notes = notes
                    dataStore.updateService(updated)
                    withAnimation { showSuccess = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { presentationMode.wrappedValue.dismiss() }
                }.padding(.horizontal, DNSpacing.md).padding(.bottom, DNSpacing.xxl)
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
    }
}

// MARK: - Fuel Log View
struct FuelLogView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var showAdd = false
    
    var logs: [FuelLog] { dataStore.vehicleFuelLogs(vehicleId) }
    var totalSpent: Double { logs.reduce(0) { $0 + $1.totalCost } }
    var totalLiters: Double { logs.reduce(0) { $0 + $1.liters } }
    var avgConsumption: Double? { dataStore.averageFuelConsumption(vehicleId: vehicleId) }
    
    var body: some View {
        VStack(spacing: 0) {
            DNNavBar(title: "Fuel Log", subtitle: "\(logs.count) entries",
                     trailingContent: AnyView(
                        Button(action: { showAdd = true }) {
                            ZStack {
                                Circle().fill(Color.dnAccentOrange).frame(width: 34, height: 34)
                                Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            }
                        }
                     ))
            
            if !logs.isEmpty {
                // Stats bar
                HStack(spacing: 0) {
                    FuelStatMini(title: "Total Spent", value: NumberHelper.currency(totalSpent, appState.currency), color: .dnAccentOrange)
                    Divider().frame(height: 40).background(Color.dnBorder)
                    FuelStatMini(title: "Total Fuel", value: NumberHelper.fuel(totalLiters, unit: appState.fuelUnit), color: .dnAccentBlue)
                    Divider().frame(height: 40).background(Color.dnBorder)
                    FuelStatMini(title: "Avg Consumption", value: avgConsumption != nil ? String(format: "%.1f L/100\(appState.distanceUnit)", avgConsumption!) : "—", color: .dnGreen)
                }
                .padding(.horizontal, DNSpacing.md)
                .padding(.vertical, DNSpacing.sm)
                .background(Color.dnCard)
            }
            
            if logs.isEmpty {
                DNEmptyState(icon: "fuelpump.fill", title: "No Fuel Logs", message: "Track your fuel expenses to see consumption stats.", actionTitle: "Add Fuel Log", action: { showAdd = true })
            } else {
                ScrollView {
                    VStack(spacing: DNSpacing.sm) {
                        ForEach(logs) { log in
                            FuelLogCard(log: log)
                        }
                        Color.clear.frame(height: 30)
                    }
                    .padding(.horizontal, DNSpacing.md)
                    .padding(.top, DNSpacing.sm)
                }
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
        .sheet(isPresented: $showAdd) { AddFuelLogView(vehicleId: vehicleId) }
    }
}

struct FuelStatMini: View {
    let title: String
    let value: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(DNFont.mono(13)).foregroundColor(color)
            Text(title).font(DNFont.label(10)).foregroundColor(.dnTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FuelLogCard: View {
    let log: FuelLog
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var showDelete = false
    
    var body: some View {
        DNCard {
            HStack(spacing: DNSpacing.md) {
                ChickenMascot(type: .fuel, size: 36)
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(NumberHelper.shortDate(log.date)).font(DNFont.label(14)).foregroundColor(.dnText)
                        Spacer()
                        Text(NumberHelper.currency(log.totalCost, appState.currency))
                            .font(DNFont.mono(15)).foregroundColor(.dnAccentOrange)
                    }
                    HStack(spacing: 12) {
                        Label(NumberHelper.fuel(log.liters, unit: appState.fuelUnit), systemImage: "drop.fill")
                            .font(DNFont.body(12)).foregroundColor(.dnTextSecondary)
                        Label(String(format: "%.2f/\(appState.fuelUnit)", log.pricePerLiter), systemImage: "tag.fill")
                            .font(DNFont.body(12)).foregroundColor(.dnTextSecondary)
                        if log.fullTank { DNBadge(text: "Full", color: .dnGreen) }
                    }
                    Text(NumberHelper.distance(log.odometer, unit: appState.distanceUnit))
                        .font(DNFont.body(11)).foregroundColor(.dnTextSecondary)
                }
            }
        }
        .contextMenu {
            Button(role: .destructive, action: { showDelete = true }) { Label("Delete", systemImage: "trash") }
        }
        .alert("Delete Fuel Log", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { dataStore.deleteFuelLog(log) }
        }
    }
}

// MARK: - Add Fuel Log View
struct AddFuelLogView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var date = Date()
    @State private var odometer = ""
    @State private var liters = ""
    @State private var totalCost = ""
    @State private var pricePerLiter = ""
    @State private var fuelType = Vehicle.FuelType.petrol
    @State private var fullTank = true
    @State private var notes = ""
    @State private var showSuccess = false
    @State private var showError = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                DNNavBar(title: "Add Fuel Log", trailingContent: AnyView(EmptyView()))
                
                VStack(spacing: DNSpacing.md) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact).labelsHidden()
                            .padding(.horizontal, DNSpacing.md).padding(.vertical, 10)
                            .background(Color.dnCardElevated).cornerRadius(DNRadius.md).colorScheme(.dark)
                    }
                    
                    DNTextField(title: "Odometer (\(appState.distanceUnit))", text: $odometer, icon: "speedometer", keyboardType: .decimalPad)
                    DNTextField(title: "Liters / \(appState.fuelUnit)", text: $liters, icon: "drop.fill", keyboardType: .decimalPad)
                    DNTextField(title: "Total Cost (\(appState.currency))", text: $totalCost, icon: "creditcard.fill", keyboardType: .decimalPad)
                    DNTextField(title: "Price per \(appState.fuelUnit)", text: $pricePerLiter, icon: "tag.fill", keyboardType: .decimalPad)
                    
                    // Full Tank Toggle
                    HStack {
                        Label("Full Tank", systemImage: "fuelpump.fill")
                            .font(DNFont.label(14)).foregroundColor(.dnText)
                        Spacer()
                        Toggle("", isOn: $fullTank)
                            .tint(.dnGreen)
                    }
                    .padding(.horizontal, DNSpacing.md).padding(.vertical, 13)
                    .background(Color.dnCardElevated).cornerRadius(DNRadius.md)
                    
                    DNTextField(title: "Notes", text: $notes, icon: "note.text")
                }
                .padding(.horizontal, DNSpacing.md)
                
                if showError { DNAlertCard(title: "Error", message: "Please fill in odometer and liters.", type: .danger).padding(.horizontal, DNSpacing.md) }
                if showSuccess { DNAlertCard(title: "Added!", message: "Fuel log saved.", type: .success).padding(.horizontal, DNSpacing.md) }
                
                DNButton("Save Fuel Log", gradient: .dnOrangeGradient) { saveFuelLog() }
                    .padding(.horizontal, DNSpacing.md).padding(.bottom, DNSpacing.xxl)
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
    }
    
    private func saveFuelLog() {
        guard !odometer.isEmpty, !liters.isEmpty else { showError = true; return }
        let log = FuelLog(vehicleId: vehicleId, date: date, odometer: Double(odometer) ?? 0,
                          liters: Double(liters) ?? 0, totalCost: Double(totalCost) ?? 0,
                          pricePerLiter: Double(pricePerLiter) ?? 0, fuelType: fuelType,
                          fullTank: fullTank, notes: notes)
        dataStore.addFuelLog(log)
        withAnimation(.dnSpring) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { presentationMode.wrappedValue.dismiss() }
    }
}

// MARK: - Problem Log View
struct ProblemLogView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var showAdd = false
    @State private var filterStatus: ProblemLog.ProblemStatus? = nil
    
    var problems: [ProblemLog] {
        let base = dataStore.problemLogs.filter { $0.vehicleId == vehicleId }.sorted { $0.date > $1.date }
        if let status = filterStatus { return base.filter { $0.status == status } }
        return base
    }
    
    var body: some View {
        VStack(spacing: 0) {
            DNNavBar(title: "Problem Log", subtitle: "\(problems.count) issues",
                     trailingContent: AnyView(
                        Button(action: { showAdd = true }) {
                            ZStack {
                                Circle().fill(Color.dnRed).frame(width: 34, height: 34)
                                Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            }
                        }
                     ))
            
            // Filter bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: filterStatus == nil) { filterStatus = nil }
                    ForEach(ProblemLog.ProblemStatus.allCases, id: \.self) { status in
                        FilterChip(title: status.rawValue, color: status.color, isSelected: filterStatus == status) { filterStatus = status }
                    }
                }
                .padding(.horizontal, DNSpacing.md)
            }
            .padding(.vertical, DNSpacing.sm)
            
            if problems.isEmpty {
                DNEmptyState(icon: "exclamationmark.triangle.fill", title: "No Problems Found", message: "Record vehicle issues to track and resolve them.", actionTitle: "Add Problem", action: { showAdd = true })
            } else {
                ScrollView {
                    VStack(spacing: DNSpacing.sm) {
                        ForEach(problems) { problem in
                            ProblemCard(problem: problem)
                        }
                        Color.clear.frame(height: 30)
                    }
                    .padding(.horizontal, DNSpacing.md).padding(.top, DNSpacing.sm)
                }
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
        .sheet(isPresented: $showAdd) { AddProblemView(vehicleId: vehicleId) }
    }
}

struct FilterChip: View {
    let title: String
    var color: Color = .dnAccentBlue
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DNFont.label(12))
                .foregroundColor(isSelected ? .white : .dnTextSecondary)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(isSelected ? color : Color.dnCard)
                .cornerRadius(DNRadius.pill)
                .overlay(RoundedRectangle(cornerRadius: DNRadius.pill).stroke(color.opacity(0.4), lineWidth: 1))
        }
    }
}

struct ProblemCard: View {
    let problem: ProblemLog
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var showStatusPicker = false
    @State private var showDelete = false
    
    var body: some View {
        DNCard {
            VStack(alignment: .leading, spacing: DNSpacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(problem.title).font(DNFont.heading(15)).foregroundColor(.dnText)
                        Text(NumberHelper.shortDate(problem.date)).font(DNFont.body(12)).foregroundColor(.dnTextSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        DNBadge(text: problem.severity.rawValue, color: problem.severity.color, filled: true)
                        DNBadge(text: problem.status.rawValue, color: problem.status.color)
                    }
                }
                
                if !problem.description.isEmpty {
                    Text(problem.description).font(DNFont.body(13)).foregroundColor(.dnTextSecondary).lineLimit(3)
                }
                
                HStack {
                    Label(NumberHelper.distance(problem.mileage, unit: appState.distanceUnit), systemImage: "speedometer")
                        .font(DNFont.body(11)).foregroundColor(.dnTextSecondary)
                    Spacer()
                    
                    if problem.status != .fixed {
                        Button(action: { showStatusPicker = true }) {
                            Label("Update Status", systemImage: "arrow.triangle.2.circlepath")
                                .font(DNFont.label(12)).foregroundColor(.dnAccentBlue)
                        }
                    }
                }
            }
        }
        .contextMenu {
            Button(action: { showStatusPicker = true }) { Label("Update Status", systemImage: "arrow.triangle.2.circlepath") }
            Button(role: .destructive, action: { showDelete = true }) { Label("Delete", systemImage: "trash") }
        }
        .confirmationDialog("Update Status", isPresented: $showStatusPicker) {
            ForEach(ProblemLog.ProblemStatus.allCases, id: \.self) { status in
                Button(status.rawValue) {
                    var updated = problem
                    updated.status = status
                    dataStore.updateProblem(updated)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Problem", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { dataStore.deleteProblem(problem) }
        }
    }
}

// MARK: - Add Problem View
struct AddProblemView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var severity = ProblemLog.Severity.medium
    @State private var date = Date()
    @State private var mileage = ""
    @State private var description = ""
    @State private var status = ProblemLog.ProblemStatus.new
    @State private var showSuccess = false
    @State private var showError = false
    
    let problemSuggestions = ["Engine Sound", "Vibration", "Hard Start", "Coolant Leak", "Dashboard Warning", "Brake Noise", "Oil Leak", "AC Issue"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                DNNavBar(title: "Add Problem", trailingContent: AnyView(EmptyView()))
                
                VStack(spacing: DNSpacing.md) {
                    // Quick suggestions
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Quick Select").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(problemSuggestions, id: \.self) { s in
                                    Button(action: { title = s }) {
                                        Text(s).font(DNFont.label(12)).foregroundColor(.dnText)
                                            .padding(.horizontal, 12).padding(.vertical, 7)
                                            .background(title == s ? Color.dnAccentBlue.opacity(0.2) : Color.dnCardElevated)
                                            .cornerRadius(DNRadius.pill)
                                    }
                                }
                            }
                        }
                    }
                    
                    DNTextField(title: "Problem Title", text: $title, icon: "exclamationmark.triangle.fill")
                    
                    // Severity
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Severity").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        HStack(spacing: 8) {
                            ForEach(ProblemLog.Severity.allCases, id: \.self) { s in
                                Button(action: { severity = s }) {
                                    Text(s.rawValue).font(DNFont.label(13))
                                        .foregroundColor(severity == s ? .white : s.color)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(severity == s ? s.color : s.color.opacity(0.15))
                                        .cornerRadius(DNRadius.pill)
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact).labelsHidden()
                            .padding(.horizontal, DNSpacing.md).padding(.vertical, 10)
                            .background(Color.dnCardElevated).cornerRadius(DNRadius.md).colorScheme(.dark)
                    }
                    
                    DNTextField(title: "Mileage (\(appState.distanceUnit))", text: $mileage, icon: "speedometer", keyboardType: .decimalPad)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        TextEditor(text: $description).frame(height: 100).padding(8)
                            .background(Color.dnCardElevated).cornerRadius(DNRadius.md)
                            .foregroundColor(.dnText).font(DNFont.body(15))
                    }
                    
                    // Initial status
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Initial Status").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        HStack(spacing: 8) {
                            ForEach([ProblemLog.ProblemStatus.new, .watching, .diagnosing], id: \.self) { s in
                                Button(action: { status = s }) {
                                    Text(s.rawValue).font(DNFont.label(12))
                                        .foregroundColor(status == s ? .white : s.color)
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(status == s ? s.color : s.color.opacity(0.15))
                                        .cornerRadius(DNRadius.pill)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, DNSpacing.md)
                
                if showError { DNAlertCard(title: "Error", message: "Please enter a problem title.", type: .danger).padding(.horizontal, DNSpacing.md) }
                if showSuccess { DNAlertCard(title: "Problem Logged!", message: "Issue has been recorded.", type: .success).padding(.horizontal, DNSpacing.md) }
                
                DNButton("Log Problem", gradient: LinearGradient(colors: [Color.dnRed, Color(hex: "#C0392B")], startPoint: .leading, endPoint: .trailing)) { saveProblem() }
                    .padding(.horizontal, DNSpacing.md).padding(.bottom, DNSpacing.xxl)
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
    }
    
    private func saveProblem() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { showError = true; return }
        let problem = ProblemLog(vehicleId: vehicleId, title: title, severity: severity, date: date,
                                  mileage: Double(mileage) ?? 0, description: description, status: status)
        dataStore.addProblem(problem)
        withAnimation(.dnSpring) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { presentationMode.wrappedValue.dismiss() }
    }
}

// MARK: - Color extension for dnAccentGreen
extension Color {
    static var dnAccentGreen: Color { Color(hex: "#45C486") }
}
