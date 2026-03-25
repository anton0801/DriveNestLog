import Foundation
import SwiftUI
import Combine
import UserNotifications

// MARK: - App State (EnvironmentObject)
class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: AppUser?
    @Published var selectedVehicleId: UUID?
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("appTheme") var appTheme: String = "system"
    @AppStorage("currency") var currency: String = "USD"
    @AppStorage("distanceUnit") var distanceUnit: String = "km"
    @AppStorage("fuelUnit") var fuelUnit: String = "L"
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("userName") private var savedUserName: String = ""
    @AppStorage("userEmail") private var savedUserEmail: String = ""
    
    var colorScheme: ColorScheme? {
        switch appTheme {
        case "dark": return .dark
        case "light": return .light
        default: return nil
        }
    }
    
    init() {
        if !savedUserName.isEmpty && !savedUserEmail.isEmpty {
            currentUser = AppUser(name: savedUserName, email: savedUserEmail)
            isAuthenticated = true
        }
    }
    
    func signIn(email: String, password: String, name: String = "") -> Bool {
        guard !email.isEmpty, !password.isEmpty else { return false }
        let user = AppUser(name: name.isEmpty ? email.components(separatedBy: "@").first ?? "Driver" : name, email: email)
        currentUser = user
        savedUserName = user.name
        savedUserEmail = user.email
        isAuthenticated = true
        return true
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        savedUserName = ""
        savedUserEmail = ""
    }
    
    func updateUser(name: String) {
        currentUser?.name = name
        savedUserName = name
    }

    func updateProfile(name: String, email: String) {
        if !name.isEmpty { currentUser?.name = name; savedUserName = name }
        if !email.isEmpty { currentUser?.email = email; savedUserEmail = email }
        objectWillChange.send()
    }
}

// MARK: - Data Store
class DataStore: ObservableObject {
    static let shared = DataStore()
    
    @Published var vehicles: [Vehicle] = []
    @Published var serviceRecords: [ServiceRecord] = []
    @Published var expenses: [Expense] = []
    @Published var fuelLogs: [FuelLog] = []
    @Published var problemLogs: [ProblemLog] = []
    @Published var trips: [Trip] = []
    @Published var checklistItems: [ChecklistItem] = []
    @Published var documents: [CarDocument] = []
    @Published var photos: [CarPhoto] = []
    @Published var parts: [CarPart] = []
    @Published var tireSets: [TireSet] = []
    @Published var insuranceRecords: [InsuranceRecord] = []
    @Published var reminders: [Reminder] = []
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadAll()
        if checklistItems.isEmpty { seedDefaultChecklists() }
    }
    
    // MARK: - Persistence
    func loadAll() {
        vehicles = load([Vehicle].self, key: "vehicles") ?? []
        serviceRecords = load([ServiceRecord].self, key: "serviceRecords") ?? []
        expenses = load([Expense].self, key: "expenses") ?? []
        fuelLogs = load([FuelLog].self, key: "fuelLogs") ?? []
        problemLogs = load([ProblemLog].self, key: "problemLogs") ?? []
        trips = load([Trip].self, key: "trips") ?? []
        checklistItems = load([ChecklistItem].self, key: "checklistItems") ?? []
        documents = load([CarDocument].self, key: "documents") ?? []
        photos = load([CarPhoto].self, key: "photos") ?? []
        parts = load([CarPart].self, key: "parts") ?? []
        tireSets = load([TireSet].self, key: "tireSets") ?? []
        insuranceRecords = load([InsuranceRecord].self, key: "insuranceRecords") ?? []
        reminders = load([Reminder].self, key: "reminders") ?? []
    }
    
    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            userDefaults.set(data, forKey: key)
        }
    }
    
    // MARK: - Vehicle CRUD
    func addVehicle(_ vehicle: Vehicle) {
        vehicles.append(vehicle)
        save(vehicles, key: "vehicles")
    }
    
    func updateVehicle(_ vehicle: Vehicle) {
        if let idx = vehicles.firstIndex(where: { $0.id == vehicle.id }) {
            vehicles[idx] = vehicle
            save(vehicles, key: "vehicles")
        }
    }
    
    func deleteVehicle(_ vehicle: Vehicle) {
        vehicles.removeAll { $0.id == vehicle.id }
        save(vehicles, key: "vehicles")
    }
    
    // MARK: - Service CRUD
    func addService(_ record: ServiceRecord) {
        serviceRecords.append(record)
        save(serviceRecords, key: "serviceRecords")
        updateVehicleMileage(vehicleId: record.vehicleId, mileage: record.mileage)
    }
    
    func updateService(_ record: ServiceRecord) {
        if let idx = serviceRecords.firstIndex(where: { $0.id == record.id }) {
            serviceRecords[idx] = record
            save(serviceRecords, key: "serviceRecords")
        }
    }
    
    func deleteService(_ record: ServiceRecord) {
        serviceRecords.removeAll { $0.id == record.id }
        save(serviceRecords, key: "serviceRecords")
    }
    
    // MARK: - Expense CRUD
    func addExpense(_ expense: Expense) {
        expenses.append(expense)
        save(expenses, key: "expenses")
    }
    
    func updateExpense(_ expense: Expense) {
        if let idx = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[idx] = expense
            save(expenses, key: "expenses")
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
        save(expenses, key: "expenses")
    }
    
    // MARK: - Fuel CRUD
    func addFuelLog(_ log: FuelLog) {
        fuelLogs.append(log)
        save(fuelLogs, key: "fuelLogs")
        updateVehicleMileage(vehicleId: log.vehicleId, mileage: log.odometer)
    }
    
    func deleteFuelLog(_ log: FuelLog) {
        fuelLogs.removeAll { $0.id == log.id }
        save(fuelLogs, key: "fuelLogs")
    }
    
    // MARK: - Problem CRUD
    func addProblem(_ problem: ProblemLog) {
        problemLogs.append(problem)
        save(problemLogs, key: "problemLogs")
    }
    
    func updateProblem(_ problem: ProblemLog) {
        if let idx = problemLogs.firstIndex(where: { $0.id == problem.id }) {
            problemLogs[idx] = problem
            save(problemLogs, key: "problemLogs")
        }
    }
    
    func deleteProblem(_ problem: ProblemLog) {
        problemLogs.removeAll { $0.id == problem.id }
        save(problemLogs, key: "problemLogs")
    }
    
    // MARK: - Trip CRUD
    func addTrip(_ trip: Trip) {
        trips.append(trip)
        save(trips, key: "trips")
    }
    
    func updateTrip(_ trip: Trip) {
        if let idx = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[idx] = trip
            save(trips, key: "trips")
        }
    }
    
    func deleteTrip(_ trip: Trip) {
        trips.removeAll { $0.id == trip.id }
        save(trips, key: "trips")
    }
    
    // MARK: - Checklist
    func toggleChecklistItem(_ item: ChecklistItem) {
        if let idx = checklistItems.firstIndex(where: { $0.id == item.id }) {
            checklistItems[idx].isChecked.toggle()
            save(checklistItems, key: "checklistItems")
        }
    }
    
    func resetChecklist(category: ChecklistItem.ChecklistCategory) {
        for idx in checklistItems.indices {
            if checklistItems[idx].category == category {
                checklistItems[idx].isChecked = false
            }
        }
        save(checklistItems, key: "checklistItems")
    }
    
    // MARK: - Documents CRUD
    func addDocument(_ doc: CarDocument) {
        documents.append(doc)
        save(documents, key: "documents")
    }
    
    func deleteDocument(_ doc: CarDocument) {
        documents.removeAll { $0.id == doc.id }
        save(documents, key: "documents")
    }
    
    // MARK: - Photos CRUD
    func addPhoto(_ photo: CarPhoto) {
        photos.append(photo)
        save(photos, key: "photos")
    }
    
    func deletePhoto(_ photo: CarPhoto) {
        photos.removeAll { $0.id == photo.id }
        save(photos, key: "photos")
    }
    
    // MARK: - Parts CRUD
    func addPart(_ part: CarPart) {
        parts.append(part)
        save(parts, key: "parts")
    }
    
    func updatePart(_ part: CarPart) {
        if let idx = parts.firstIndex(where: { $0.id == part.id }) {
            parts[idx] = part
            save(parts, key: "parts")
        }
    }
    
    func deletePart(_ part: CarPart) {
        parts.removeAll { $0.id == part.id }
        save(parts, key: "parts")
    }
    
    // MARK: - Tires CRUD
    func addTireSet(_ tireSet: TireSet) {
        tireSets.append(tireSet)
        save(tireSets, key: "tireSets")
    }
    
    func updateTireSet(_ tireSet: TireSet) {
        if let idx = tireSets.firstIndex(where: { $0.id == tireSet.id }) {
            tireSets[idx] = tireSet
            save(tireSets, key: "tireSets")
        }
    }
    
    func deleteTireSet(_ tireSet: TireSet) {
        tireSets.removeAll { $0.id == tireSet.id }
        save(tireSets, key: "tireSets")
    }
    
    // MARK: - Insurance CRUD
    func addInsurance(_ record: InsuranceRecord) {
        insuranceRecords.append(record)
        save(insuranceRecords, key: "insuranceRecords")
    }
    
    func updateInsurance(_ record: InsuranceRecord) {
        if let idx = insuranceRecords.firstIndex(where: { $0.id == record.id }) {
            insuranceRecords[idx] = record
            save(insuranceRecords, key: "insuranceRecords")
        }
    }
    
    func deleteInsurance(_ record: InsuranceRecord) {
        insuranceRecords.removeAll { $0.id == record.id }
        save(insuranceRecords, key: "insuranceRecords")
    }
    
    // MARK: - Reminders
    func addReminder(_ reminder: Reminder) {
        reminders.append(reminder)
        save(reminders, key: "reminders")
        scheduleNotification(for: reminder)
    }
    
    func completeReminder(_ reminder: Reminder) {
        if let idx = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[idx].isCompleted = true
            save(reminders, key: "reminders")
            cancelNotification(id: reminder.notificationId)
        }
    }
    
    func deleteReminder(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        save(reminders, key: "reminders")
        cancelNotification(id: reminder.notificationId)
    }
    
    // MARK: - Helpers
    private func updateVehicleMileage(vehicleId: UUID, mileage: Double) {
        if let idx = vehicles.firstIndex(where: { $0.id == vehicleId }) {
            if vehicles[idx].currentMileage < mileage {
                vehicles[idx].currentMileage = mileage
                save(vehicles, key: "vehicles")
            }
        }
    }
    
    func vehicleExpenses(_ vehicleId: UUID, month: Date? = nil) -> Double {
        var filtered = expenses.filter { $0.vehicleId == vehicleId }
        if let month = month {
            let cal = Calendar.current
            filtered = filtered.filter { cal.isDate($0.date, equalTo: month, toGranularity: .month) }
        }
        return filtered.reduce(0) { $0 + $1.amount }
    }
    
    func vehicleServices(_ vehicleId: UUID) -> [ServiceRecord] {
        serviceRecords.filter { $0.vehicleId == vehicleId }.sorted { $0.date > $1.date }
    }
    
    func vehicleFuelLogs(_ vehicleId: UUID) -> [FuelLog] {
        fuelLogs.filter { $0.vehicleId == vehicleId }.sorted { $0.date > $1.date }
    }
    
    func averageFuelConsumption(vehicleId: UUID) -> Double? {
        let logs = vehicleFuelLogs(vehicleId).sorted { $0.odometer < $1.odometer }
        guard logs.count >= 2 else { return nil }
        let totalLiters = logs.dropFirst().reduce(0.0) { $0 + $1.liters }
        let totalKm = (logs.last?.odometer ?? 0) - (logs.first?.odometer ?? 0)
        guard totalKm > 0 else { return nil }
        return (totalLiters / totalKm) * 100
    }
    
    func scheduleNotification(for reminder: Reminder) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = "Reminder: \(reminder.title)"
            content.body = "Don't forget to take care of your vehicle!"
            content.sound = .default
            
            let cal = Calendar.current
            let components = cal.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.dueDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: reminder.notificationId, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    private func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    private func seedDefaultChecklists() {
        let cityItems = ["Tire Pressure", "Oil Level", "Fuel Level", "Lights", "Wipers"]
        let longItems = ["Tire Pressure", "Oil Level", "Coolant", "Lights", "Documents", "Spare Tire", "Tools", "First Aid Kit", "Fuel"]
        let winterItems = ["Winter Tires", "Antifreeze Level", "Battery", "Heating", "Wiper Fluid", "Scrapers", "Snow Chains"]
        let cargoItems = ["Load Security", "Tire Pressure (load)", "Mirrors Adjusted", "Brakes", "Lights", "Documents"]
        
        for title in cityItems {
            checklistItems.append(ChecklistItem(title: title, category: .cityDrive))
        }
        for title in longItems {
            checklistItems.append(ChecklistItem(title: title, category: .longTrip))
        }
        for title in winterItems {
            checklistItems.append(ChecklistItem(title: title, category: .winterTrip))
        }
        for title in cargoItems {
            checklistItems.append(ChecklistItem(title: title, category: .cargoTrip))
        }
        save(checklistItems, key: "checklistItems")
    }

    // MARK: - Save All (bulk persist)
    func saveAll() {
        save(vehicles, key: "vehicles")
        save(serviceRecords, key: "serviceRecords")
        save(expenses, key: "expenses")
        save(fuelLogs, key: "fuelLogs")
        save(problemLogs, key: "problemLogs")
        save(trips, key: "trips")
        save(checklistItems, key: "checklistItems")
        save(documents, key: "documents")
        save(photos, key: "photos")
        save(parts, key: "parts")
        save(tireSets, key: "tireSets")
        save(insuranceRecords, key: "insuranceRecords")
        save(reminders, key: "reminders")
    }
}
