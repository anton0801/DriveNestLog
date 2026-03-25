import Foundation
import SwiftUI

// MARK: - Vehicle Model
struct Vehicle: Identifiable, Codable {
    var id: UUID = UUID()
    var brand: String
    var model: String
    var year: Int
    var engine: String
    var licensePlate: String
    var vin: String
    var currentMileage: Double
    var fuelType: FuelType
    var transmission: TransmissionType
    var notes: String
    var photoData: Data?
    var nickname: String
    var createdAt: Date = Date()
    
    enum FuelType: String, Codable, CaseIterable {
        case petrol = "Petrol"
        case diesel = "Diesel"
        case electric = "Electric"
        case hybrid = "Hybrid"
        case lpg = "LPG"
        case cng = "CNG"
    }
    
    enum TransmissionType: String, Codable, CaseIterable {
        case manual = "Manual"
        case automatic = "Automatic"
        case cvt = "CVT"
        case dct = "DCT"
        case amt = "AMT"
    }
    
    var displayName: String { "\(brand) \(model)" }
    var photoImage: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - Service Record
struct ServiceRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var vehicleId: UUID
    var serviceType: ServiceType
    var date: Date
    var mileage: Double
    var cost: Double
    var garageName: String
    var partsUsed: String
    var notes: String
    var photoData: Data?
    
    enum ServiceType: String, Codable, CaseIterable {
        case oilChange = "Oil Change"
        case airFilter = "Air Filter"
        case brakePads = "Brake Pads"
        case battery = "Battery"
        case coolantFlush = "Coolant Flush"
        case sparkPlugs = "Spark Plugs"
        case tireRotation = "Tire Rotation"
        case transmission = "Transmission Service"
        case timing = "Timing Belt/Chain"
        case brakeFluid = "Brake Fluid"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .oilChange: return "drop.fill"
            case .airFilter: return "wind"
            case .brakePads: return "car.fill"
            case .battery: return "battery.100"
            case .coolantFlush: return "thermometer.snowflake"
            case .sparkPlugs: return "bolt.fill"
            case .tireRotation: return "circle.fill"
            case .transmission: return "gear"
            case .timing: return "clock.fill"
            case .brakeFluid: return "drop.circle.fill"
            case .other: return "wrench.fill"
            }
        }
    }
}

// MARK: - Expense
struct Expense: Identifiable, Codable {
    var id: UUID = UUID()
    var vehicleId: UUID
    var category: ExpenseCategory
    var amount: Double
    var date: Date
    var description: String
    var notes: String
    var receiptData: Data?
    
    enum ExpenseCategory: String, Codable, CaseIterable {
        case fuel = "Fuel"
        case service = "Service"
        case repairs = "Repairs"
        case insurance = "Insurance"
        case tax = "Tax"
        case wash = "Wash"
        case parking = "Parking"
        case tolls = "Tolls"
        case accessories = "Accessories"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .fuel: return "fuelpump.fill"
            case .service: return "wrench.fill"
            case .repairs: return "hammer.fill"
            case .insurance: return "shield.fill"
            case .tax: return "doc.text.fill"
            case .wash: return "sparkles"
            case .parking: return "p.square.fill"
            case .tolls: return "road.lanes"
            case .accessories: return "plus.square.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .fuel: return .dnAccentOrange
            case .service: return .dnAccentBlue
            case .repairs: return .dnRed
            case .insurance: return .dnGreen
            case .tax: return Color(hex: "#9B59B6")
            case .wash: return Color(hex: "#3498DB")
            case .parking: return Color(hex: "#E67E22")
            case .tolls: return Color(hex: "#1ABC9C")
            case .accessories: return Color(hex: "#E91E63")
            case .other: return .dnTextSecondary
            }
        }
    }
}

// MARK: - Fuel Log
struct FuelLog: Identifiable, Codable {
    var id: UUID = UUID()
    var vehicleId: UUID
    var date: Date
    var odometer: Double
    var liters: Double
    var totalCost: Double
    var pricePerLiter: Double
    var fuelType: Vehicle.FuelType
    var fullTank: Bool
    var notes: String
    
    var costPer100km: Double? { nil } // calculated based on prev log
}

// MARK: - Problem Log
struct ProblemLog: Identifiable, Codable {
    var id: UUID = UUID()
    var vehicleId: UUID
    var title: String
    var severity: Severity
    var date: Date
    var mileage: Double
    var description: String
    var photoData: Data?
    var status: ProblemStatus
    
    enum Severity: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .low: return .dnGreen
            case .medium: return .dnAccentOrange
            case .high: return .dnRed
            case .critical: return Color(hex: "#C0392B")
            }
        }
    }
    
    enum ProblemStatus: String, Codable, CaseIterable {
        case new = "New"
        case watching = "Watching"
        case diagnosing = "Diagnosing"
        case fixed = "Fixed"
        
        var color: Color {
            switch self {
            case .new: return .dnAccentBlue
            case .watching: return .dnAccentOrange
            case .diagnosing: return Color(hex: "#9B59B6")
            case .fixed: return .dnGreen
            }
        }
    }
}

// MARK: - Trip
struct Trip: Identifiable, Codable {
    var id: UUID = UUID()
    var vehicleId: UUID
    var name: String
    var startDate: Date
    var endDate: Date?
    var startMileage: Double
    var endMileage: Double?
    var fuelUsed: Double?
    var costs: Double
    var notes: String
    var photoData: [Data]
    
    var distance: Double? {
        guard let end = endMileage else { return nil }
        return end - startMileage
    }
}

// MARK: - Checklist Item
struct ChecklistItem: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var isChecked: Bool = false
    var category: ChecklistCategory
    
    enum ChecklistCategory: String, Codable, CaseIterable {
        case cityDrive = "City Drive"
        case longTrip = "Long Trip"
        case winterTrip = "Winter Trip"
        case cargoTrip = "Cargo Trip"
    }
}

// MARK: - Document
struct CarDocument: Identifiable, Codable {
    var id: UUID = UUID()
    var vehicleId: UUID
    var type: DocumentType
    var title: String
    var expiryDate: Date?
    var fileData: Data?
    var notes: String
    var uploadedAt: Date = Date()
    
    enum DocumentType: String, Codable, CaseIterable {
        case insurance = "Insurance"
        case registration = "Registration"
        case diagnosticCard = "Diagnostic Card"
        case serviceReceipt = "Service Receipt"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .insurance: return "shield.fill"
            case .registration: return "doc.fill"
            case .diagnosticCard: return "checkmark.shield.fill"
            case .serviceReceipt: return "receipt.fill"
            case .other: return "doc.circle.fill"
            }
        }
    }
    
    var isExpired: Bool {
        guard let date = expiryDate else { return false }
        return date < Date()
    }
    
    var isExpiringSoon: Bool {
        guard let date = expiryDate else { return false }
        let thirtyDays = Date().addingTimeInterval(30 * 24 * 3600)
        return date < thirtyDays && !isExpired
    }
}

// MARK: - Car Photo
struct CarPhoto: Identifiable, Codable {
    var id: UUID = UUID()
    var vehicleId: UUID
    var category: PhotoCategory
    var imageData: Data
    var caption: String
    var takenAt: Date
    
    enum PhotoCategory: String, Codable, CaseIterable {
        case exterior = "Exterior"
        case interior = "Interior"
        case engine = "Engine"
        case tires = "Tires"
        case damage = "Damage"
        case receipts = "Receipts"
        case parts = "Parts"
        
        var icon: String {
            switch self {
            case .exterior: return "car.fill"
            case .interior: return "seat.fill"
            case .engine: return "engine.combustion.fill"
            case .tires: return "circle.fill"
            case .damage: return "exclamationmark.triangle.fill"
            case .receipts: return "receipt.fill"
            case .parts: return "gearshape.fill"
            }
        }
    }
}

// MARK: - Part
struct CarPart: Identifiable, Codable {
    var id: UUID = UUID()
    var vehicleId: UUID
    var name: String
    var partNumber: String
    var brand: String
    var installDate: Date
    var cost: Double
    var photoData: Data?
    var notes: String
}

// MARK: - Tire Set
struct TireSet: Identifiable, Codable {
    var id: UUID = UUID()
    var vehicleId: UUID
    var season: TireSeason
    var brand: String
    var size: String
    var installDate: Date
    var mileageAtInstall: Double
    var condition: TireCondition
    var notes: String
    
    enum TireSeason: String, Codable, CaseIterable {
        case summer = "Summer"
        case winter = "Winter"
        case allSeason = "All-Season"
    }
    
    enum TireCondition: String, Codable, CaseIterable {
        case new = "New"
        case good = "Good"
        case fair = "Fair"
        case worn = "Worn"
        case replace = "Replace"
        
        var color: Color {
            switch self {
            case .new: return .dnGreen
            case .good: return .dnAccentBlue
            case .fair: return .dnAccentOrange
            case .worn: return .dnRed
            case .replace: return Color(hex: "#C0392B")
            }
        }
    }
}

// MARK: - Insurance
struct InsuranceRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var vehicleId: UUID
    var provider: String
    var policyNumber: String
    var startDate: Date
    var endDate: Date
    var cost: Double
    var notes: String
    
    var isExpired: Bool { endDate < Date() }
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
}

// MARK: - User
struct AppUser: Codable {
    var id: UUID = UUID()
    var name: String
    var email: String
    var avatarData: Data?
    var createdAt: Date = Date()
}

// MARK: - Reminder
struct Reminder: Identifiable, Codable {
    var id: UUID = UUID()
    var vehicleId: UUID
    var title: String
    var dueDate: Date
    var dueMileage: Double?
    var isCompleted: Bool = false
    var notificationId: String = UUID().uuidString
}
