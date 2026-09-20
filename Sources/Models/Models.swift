import Foundation

// MARK: - Enums
enum VehicleType: String, CaseIterable, Codable {
    case truck = "Truck"
    case van = "Van"
    case car = "Car"
    case bike = "Bike"
    case bus = "Bus"

    var icon: String {
        switch self {
        case .truck: return "truck.box"
        case .van: return "van"
        case .car: return "car"
        case .bike: return "bicycle"
        case .bus: return "bus"
        }
    }
}

enum VehicleStatus: String, CaseIterable, Codable {
    case available = "Available"
    case inUse = "In Use"
    case maintenance = "Maintenance"
    case retired = "Retired"
}

enum FuelType: String, CaseIterable, Codable {
    case gasoline = "Gasoline"
    case diesel = "Diesel"
    case electric = "Electric"
    case hybrid = "Hybrid"
    case propane = "Propane"
}

enum MaintenanceType: String, CaseIterable, Codable {
    case oilChange = "Oil Change"
    case tireRotation = "Tire Rotation"
    case brakeService = "Brake Service"
    case engine = "Engine"
    case transmission = "Transmission"
    case electrical = "Electrical"
    case body = "Body"
    case inspection = "Inspection"
    case other = "Other"
}

enum DriverStatus: String, CaseIterable, Codable {
    case active = "Active"
    case onLeave = "On Leave"
    case suspended = "Suspended"
    case terminated = "Terminated"
}

enum CertificationType: String, CaseIterable, Codable {
    case cdl = "CDL"
    case hazmat = "Hazmat"
    case tanker = "Tanker"
    case doublesTriples = "Doubles/Triples"
    case medicalCard = "Medical Card"
    case dotPhysical = "DOT Physical"
    case defensiveDriving = "Defensive Driving"
    case firstAid = "First Aid"
    case other = "Other"
}

enum TripStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case assigned = "Assigned"
    case inTransit = "In Transit"
    case delivered = "Delivered"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .assigned: return "person.badge.clock"
        case .inTransit: return "arrow.right"
        case .delivered: return "checkmark.circle"
        case .completed: return "checkmark.seal"
        case .cancelled: return "xmark.circle"
        }
    }
}

enum CustomerType: String, CaseIterable, Codable {
    case commercial = "Commercial"
    case residential = "Residential"
    case government = "Government"
}

enum InvoiceStatus: String, CaseIterable, Codable {
    case draft = "Draft"
    case sent = "Sent"
    case paid = "Paid"
    case overdue = "Overdue"
    case cancelled = "Cancelled"
}

enum ExpenseCategory: String, CaseIterable, Codable {
    case fuel = "Fuel"
    case maintenance = "Maintenance"
    case insurance = "Insurance"
    case payroll = "Payroll"
    case permits = "Permits"
    case equipment = "Equipment"
    case office = "Office"
    case utilities = "Utilities"
    case marketing = "Marketing"
    case other = "Other"
}

// MARK: - Vehicle
struct Vehicle: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var type: VehicleType
    var licensePlate: String
    var make: String
    var model: String
    var year: Int
    var vin: String
    var status: VehicleStatus
    var purchaseDate: Date?
    var purchasePrice: Double?
    var currentOdometer: Int
    var fuelType: FuelType
    var notes: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var displayName: String {
        "\(year) \(make) \(model)"
    }
}

// MARK: - Maintenance Record
struct MaintenanceRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var vehicleId: UUID
    var type: MaintenanceType
    var description: String
    var date: Date
    var odometer: Int
    var cost: Double
    var vendor: String?
    var notes: String?
    var createdAt: Date = Date()
}

// MARK: - Fuel Log
struct FuelLog: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var vehicleId: UUID
    var date: Date
    var odometer: Int
    var quantity: Double
    var pricePerUnit: Double
    var totalCost: Double
    var fuelType: FuelType
    var location: String?
    var notes: String?
    var createdAt: Date = Date()
}

// MARK: - Driver
struct Driver: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var address: String?
    var emergencyContact: String?
    var emergencyPhone: String?
    var licenseNumber: String
    var licenseState: String
    var licenseExpiry: Date
    var status: DriverStatus
    var hireDate: Date
    var terminationDate: Date?
    var notes: String?
    var rating: Double
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

// MARK: - Certification
struct Certification: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var driverId: UUID
    var type: CertificationType
    var name: String
    var issuedDate: Date
    var expiryDate: Date?
    var documentNumber: String?
    var createdAt: Date = Date()
}

// MARK: - Trip
struct Trip: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var jobNumber: String
    var customerId: UUID
    var driverId: UUID?
    var vehicleId: UUID?
    var status: TripStatus
    var pickupAddress: String
    var pickupCity: String
    var pickupState: String
    var pickupZip: String
    var pickupDate: Date
    var deliveryAddress: String
    var deliveryCity: String
    var deliveryState: String
    var deliveryZip: String
    var deliveryDate: Date?
    var distance: Double?
    var cargoDescription: String?
    var cargoWeight: Double?
    var rate: Double
    var fuelSurcharge: Double
    var totalAmount: Double
    var notes: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    static func generateJobNumber() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateStr = dateFormatter.string(from: Date())
        let suffix = UUID().uuidString.prefix(8).uppercased()
        return "TF-\(dateStr)-\(suffix)"
    }
}

// MARK: - Trip Update
struct TripUpdate: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var tripId: UUID
    var status: TripStatus
    var timestamp: Date
    var location: String?
    var notes: String?
}

// MARK: - Customer
struct Customer: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var companyName: String
    var contactName: String
    var email: String
    var phone: String
    var type: CustomerType
    var address: String
    var city: String
    var state: String
    var zip: String
    var creditLimit: Double
    var paymentTerms: Int
    var taxId: String?
    var notes: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

// MARK: - Invoice
struct Invoice: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var invoiceNumber: String
    var customerId: UUID
    var tripIds: [UUID]
    var invoiceDate: Date
    var dueDate: Date
    var subtotal: Double
    var tax: Double
    var total: Double
    var status: InvoiceStatus
    var paidDate: Date?
    var notes: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    static func generateInvoiceNumber() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        let dateStr = dateFormatter.string(from: Date())
        let suffix = UUID().uuidString.prefix(8).uppercased()
        return "INV-\(dateStr)-\(suffix)"
    }
}

// MARK: - Expense
struct Expense: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var category: ExpenseCategory
    var vendor: String?
    var description: String
    var amount: Double
    var date: Date
    var vehicleId: UUID?
    var driverId: UUID?
    var receiptNumber: String?
    var notes: String?
    var createdAt: Date = Date()
}

// MARK: - Business Settings
struct BusinessSettings: Codable, Hashable {
    var companyName: String
    var address: String
    var city: String
    var state: String
    var zip: String
    var phone: String
    var email: String
    var taxRate: Double
    var currency: String
    var distanceUnit: String
    var invoicePrefix: String

    static var `default`: BusinessSettings {
        BusinessSettings(
            companyName: "",
            address: "",
            city: "",
            state: "",
            zip: "",
            phone: "",
            email: "",
            taxRate: 0.0,
            currency: "USD",
            distanceUnit: "miles",
            invoicePrefix: "INV"
        )
    }
}

// MARK: - Dashboard Stats
struct DashboardStats: Codable, Hashable {
    var totalVehicles: Int
    var activeVehicles: Int
    var totalDrivers: Int
    var activeDrivers: Int
    var todayTrips: Int
    var pendingTrips: Int
    var monthlyRevenue: Double
    var monthlyExpenses: Double
    var fleetUtilization: Double
    var overdueMaintenance: Int
    var expiringLicenses: Int
    var activeCustomers: Int
}