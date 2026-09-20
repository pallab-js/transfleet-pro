import Foundation
import SQLite

typealias SQLExpression = SQLite.Expression

enum DatabaseError: Error, LocalizedError {
    case notConnected
    case saveFailed(String)
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Database not connected"
        case .saveFailed(let msg): return "Save failed: \(msg)"
        case .deleteFailed(let msg): return "Delete failed: \(msg)"
        }
    }
}

@MainActor
final class DatabaseManager: DatabaseManagerProtocol {
    static let shared = DatabaseManager()

    private var db: Connection?
    private let dbPath: String
    private(set) var databaseError: String?

    // MARK: - Tables
    private let vehicles = Table("vehicles")
    private let maintenanceRecords = Table("maintenance_records")
    private let fuelLogs = Table("fuel_logs")
    private let drivers = Table("drivers")
    private let certifications = Table("certifications")
    private let trips = Table("trips")
    private let tripUpdates = Table("trip_updates")
    private let customers = Table("customers")
    private let invoices = Table("invoices")
    private let invoiceTrips = Table("invoice_trips")
    private let expenses = Table("expenses")
    private let settings = Table("settings")

    // MARK: - Vehicle Columns
    private let id = SQLExpression<String>("id")
    private let name = SQLExpression<String>("name")
    private let type = SQLExpression<String>("type")
    private let licensePlate = SQLExpression<String>("license_plate")
    private let make = SQLExpression<String>("make")
    private let model = SQLExpression<String>("model")
    private let year = SQLExpression<Int>("year")
    private let vin = SQLExpression<String>("vin")
    private let status = SQLExpression<String>("status")
    private let purchaseDate = SQLExpression<Double?>("purchase_date")
    private let purchasePrice = SQLExpression<Double?>("purchase_price")
    private let currentOdometer = SQLExpression<Int>("current_odometer")
    private let fuelType = SQLExpression<String>("fuel_type")
    private let notes = SQLExpression<String?>("notes")
    private let createdAt = SQLExpression<Double>("created_at")
    private let updatedAt = SQLExpression<Double>("updated_at")

    // MARK: - Maintenance Columns
    private let vehicleId = SQLExpression<String>("vehicle_id")
    private let maintenanceType = SQLExpression<String>("maintenance_type")
    private let description = SQLExpression<String>("description")
    private let date = SQLExpression<Double>("date")
    private let odometer = SQLExpression<Int>("odometer")
    private let cost = SQLExpression<Double>("cost")
    private let vendor = SQLExpression<String?>("vendor")

    // MARK: - Fuel Log Columns
    private let quantity = SQLExpression<Double>("quantity")
    private let pricePerUnit = SQLExpression<Double>("price_per_unit")
    private let totalCost = SQLExpression<Double>("total_cost")
    private let location = SQLExpression<String?>("location")

    // MARK: - Driver Columns
    private let firstName = SQLExpression<String>("first_name")
    private let lastName = SQLExpression<String>("last_name")
    private let email = SQLExpression<String>("email")
    private let phone = SQLExpression<String>("phone")
    private let address = SQLExpression<String?>("address")
    private let emergencyContact = SQLExpression<String?>("emergency_contact")
    private let emergencyPhone = SQLExpression<String?>("emergency_phone")
    private let licenseNumber = SQLExpression<String>("license_number")
    private let licenseState = SQLExpression<String>("license_state")
    private let licenseExpiry = SQLExpression<Double>("license_expiry")
    private let hireDate = SQLExpression<Double>("hire_date")
    private let terminationDate = SQLExpression<Double?>("termination_date")
    private let rating = SQLExpression<Double>("rating")

    // MARK: - Certification Columns
    private let driverId = SQLExpression<String>("driver_id")
    private let certificationType = SQLExpression<String>("certification_type")
    private let issuedDate = SQLExpression<Double>("issued_date")
    private let expiryDate = SQLExpression<Double?>("expiry_date")
    private let documentNumber = SQLExpression<String?>("document_number")

    // MARK: - Trip Columns
    private let jobNumber = SQLExpression<String>("job_number")
    private let customerId = SQLExpression<String>("customer_id")
    private let tripDriverId = SQLExpression<String?>("driver_id")
    private let tripVehicleId = SQLExpression<String?>("vehicle_id")
    private let tripStatus = SQLExpression<String>("status")
    private let pickupAddress = SQLExpression<String>("pickup_address")
    private let pickupCity = SQLExpression<String>("pickup_city")
    private let pickupState = SQLExpression<String>("pickup_state")
    private let pickupZip = SQLExpression<String>("pickup_zip")
    private let pickupDate = SQLExpression<Double>("pickup_date")
    private let deliveryAddress = SQLExpression<String>("delivery_address")
    private let deliveryCity = SQLExpression<String>("delivery_city")
    private let deliveryState = SQLExpression<String>("delivery_state")
    private let deliveryZip = SQLExpression<String>("delivery_zip")
    private let deliveryDate = SQLExpression<Double?>("delivery_date")
    private let distance = SQLExpression<Double?>("distance")
    private let cargoDescription = SQLExpression<String?>("cargo_description")
    private let cargoWeight = SQLExpression<Double?>("cargo_weight")
    private let rate = SQLExpression<Double>("rate")
    private let fuelSurcharge = SQLExpression<Double>("fuel_surcharge")
    private let totalAmount = SQLExpression<Double>("total_amount")

    // MARK: - Trip Update Columns
    private let tripId = SQLExpression<String>("trip_id")

    // MARK: - Customer Columns
    private let companyName = SQLExpression<String>("company_name")
    private let contactName = SQLExpression<String>("contact_name")
    private let customerType = SQLExpression<String>("type")
    private let city = SQLExpression<String>("city")
    private let state = SQLExpression<String>("state")
    private let zip = SQLExpression<String>("zip")
    private let creditLimit = SQLExpression<Double>("credit_limit")
    private let paymentTerms = SQLExpression<Int>("payment_terms")
    private let taxId = SQLExpression<String?>("tax_id")

    // MARK: - Invoice Columns
    private let invoiceNumber = SQLExpression<String>("invoice_number")
    private let tripIds = SQLExpression<String>("trip_ids")
    private let invoiceDate = SQLExpression<Double>("invoice_date")
    private let dueDate = SQLExpression<Double>("due_date")
    private let subtotal = SQLExpression<Double>("subtotal")
    private let tax = SQLExpression<Double>("tax")
    private let total = SQLExpression<Double>("total")
    private let invoiceStatus = SQLExpression<String>("status")
    private let paidDate = SQLExpression<Double?>("paid_date")

    // MARK: - Invoice Trips Junction Columns
    private let invoiceTripInvoiceId = SQLExpression<String>("invoice_id")
    private let invoiceTripTripId = SQLExpression<String>("trip_id")

    // MARK: - Expense Columns
    private let category = SQLExpression<String>("category")
    private let expenseVendor = SQLExpression<String?>("vendor")
    private let amount = SQLExpression<Double>("amount")
    private let receiptNumber = SQLExpression<String?>("receipt_number")
    private let expenseVehicleId = SQLExpression<String?>("vehicle_id")
    private let expenseDriverId = SQLExpression<String?>("driver_id")

    // MARK: - Settings
    private let settingsKey = SQLExpression<String>("key")
    private let settingsValue = SQLExpression<String>("value")

    private static let currentSchemaVersion: Int32 = 3

    private init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("TransFleetPro", isDirectory: true)

        try? fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)

        dbPath = appFolder.appendingPathComponent("transfleet.sqlite3").path
    }

    // MARK: - Database Initialization

    func initializeDatabase() {
        do {
            db = try Connection(dbPath)
            try db!.run("PRAGMA foreign_keys = ON")
            migrateIfNeeded()
            createTables()
            databaseError = nil
        } catch {
            let msg = "Failed to initialize database: \(error.localizedDescription)"
            databaseError = msg
            print(msg)
        }
    }

    // MARK: - Schema Migration

    private func migrateIfNeeded() {
        guard let db = db else { return }
        do {
            let version = try db.scalar("PRAGMA user_version") as! Int64
            if version < 1 {
                createTables()
            }
            if version < 2 {
                // Migration for version 2 would go here
            }
            if version < 3 {
                // Migration: add invoice_trips junction table
                try db.run(invoiceTrips.create(ifNotExists: true) { t in
                    t.column(invoiceTripInvoiceId)
                    t.column(invoiceTripTripId)
                    t.primaryKey(invoiceTripInvoiceId, invoiceTripTripId)
                })
            }
            try db.run("PRAGMA user_version = \(Self.currentSchemaVersion)")
        } catch {
            print("Schema migration failed: \(error)")
        }
    }

    // MARK: - Table Creation

    private func createTables() {
        guard let db = db else { return }

        do {
            try db.run(vehicles.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(name)
                t.column(type)
                t.column(licensePlate)
                t.column(make)
                t.column(model)
                t.column(year)
                t.column(vin)
                t.column(status)
                t.column(purchaseDate)
                t.column(purchasePrice)
                t.column(currentOdometer)
                t.column(fuelType)
                t.column(notes)
                t.column(createdAt)
                t.column(updatedAt)
            })

            try db.run(maintenanceRecords.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(vehicleId)
                t.column(maintenanceType)
                t.column(description)
                t.column(date)
                t.column(odometer)
                t.column(cost)
                t.column(vendor)
                t.column(notes)
                t.column(createdAt)
            })

            try db.run(fuelLogs.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(vehicleId)
                t.column(date)
                t.column(odometer)
                t.column(quantity)
                t.column(pricePerUnit)
                t.column(totalCost)
                t.column(fuelType)
                t.column(location)
                t.column(notes)
                t.column(createdAt)
            })

            try db.run(drivers.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(firstName)
                t.column(lastName)
                t.column(email)
                t.column(phone)
                t.column(address)
                t.column(emergencyContact)
                t.column(emergencyPhone)
                t.column(licenseNumber)
                t.column(licenseState)
                t.column(licenseExpiry)
                t.column(status)
                t.column(hireDate)
                t.column(terminationDate)
                t.column(notes)
                t.column(rating)
                t.column(createdAt)
                t.column(updatedAt)
            })

            try db.run(certifications.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(driverId)
                t.column(certificationType)
                t.column(name)
                t.column(issuedDate)
                t.column(expiryDate)
                t.column(documentNumber)
                t.column(createdAt)
            })

            try db.run(trips.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(jobNumber, unique: true)
                t.column(customerId)
                t.column(tripDriverId)
                t.column(tripVehicleId)
                t.column(tripStatus)
                t.column(pickupAddress)
                t.column(pickupCity)
                t.column(pickupState)
                t.column(pickupZip)
                t.column(pickupDate)
                t.column(deliveryAddress)
                t.column(deliveryCity)
                t.column(deliveryState)
                t.column(deliveryZip)
                t.column(deliveryDate)
                t.column(distance)
                t.column(cargoDescription)
                t.column(cargoWeight)
                t.column(rate)
                t.column(fuelSurcharge)
                t.column(totalAmount)
                t.column(notes)
                t.column(createdAt)
                t.column(updatedAt)
            })

            try db.run(tripUpdates.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(tripId)
                t.column(tripStatus)
                t.column(date)
                t.column(location)
                t.column(notes)
            })

            try db.run(customers.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(companyName)
                t.column(contactName)
                t.column(email)
                t.column(phone)
                t.column(customerType)
                t.column(address)
                t.column(city)
                t.column(state)
                t.column(zip)
                t.column(creditLimit)
                t.column(paymentTerms)
                t.column(taxId)
                t.column(notes)
                t.column(createdAt)
                t.column(updatedAt)
            })

            try db.run(invoices.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(invoiceNumber, unique: true)
                t.column(customerId)
                t.column(tripIds)
                t.column(invoiceDate)
                t.column(dueDate)
                t.column(subtotal)
                t.column(tax)
                t.column(total)
                t.column(invoiceStatus)
                t.column(paidDate)
                t.column(notes)
                t.column(createdAt)
                t.column(updatedAt)
            })

            try db.run(invoiceTrips.create(ifNotExists: true) { t in
                t.column(invoiceTripInvoiceId)
                t.column(invoiceTripTripId)
                t.primaryKey(invoiceTripInvoiceId, invoiceTripTripId)
            })

            try db.run(expenses.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(category)
                t.column(vendor)
                t.column(description)
                t.column(amount)
                t.column(date)
                t.column(vehicleId)
                t.column(driverId)
                t.column(receiptNumber)
                t.column(notes)
                t.column(createdAt)
            })

            try db.run(settings.create(ifNotExists: true) { t in
                t.column(settingsKey, primaryKey: true)
                t.column(settingsValue)
            })

        } catch {
            let msg = "Table creation failed: \(error)"
            databaseError = msg
            print(msg)
        }
    }

    // MARK: - Transaction Helper

    private func transaction(_ block: () throws -> Void) throws {
        guard let db = db else {
            throw DatabaseError.notConnected
        }
        try db.transaction {
            try block()
        }
    }

    // MARK: - Vehicle CRUD

    func saveVehicle(_ vehicle: Vehicle) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        try transaction {
            let existing = try db.pluck(vehicles.filter(id == vehicle.id.uuidString))
            if existing != nil {
                let row = vehicles.filter(id == vehicle.id.uuidString)
                try db.run(row.update(
                    name <- vehicle.name,
                    type <- vehicle.type.rawValue,
                    licensePlate <- vehicle.licensePlate,
                    make <- vehicle.make,
                    model <- vehicle.model,
                    year <- vehicle.year,
                    vin <- vehicle.vin,
                    status <- vehicle.status.rawValue,
                    purchaseDate <- vehicle.purchaseDate?.timeIntervalSince1970,
                    purchasePrice <- vehicle.purchasePrice,
                    currentOdometer <- vehicle.currentOdometer,
                    fuelType <- vehicle.fuelType.rawValue,
                    notes <- vehicle.notes,
                    updatedAt <- Date().timeIntervalSince1970
                ))
            } else {
                try db.run(vehicles.insert(
                    id <- vehicle.id.uuidString,
                    name <- vehicle.name,
                    type <- vehicle.type.rawValue,
                    licensePlate <- vehicle.licensePlate,
                    make <- vehicle.make,
                    model <- vehicle.model,
                    year <- vehicle.year,
                    vin <- vehicle.vin,
                    status <- vehicle.status.rawValue,
                    purchaseDate <- vehicle.purchaseDate?.timeIntervalSince1970,
                    purchasePrice <- vehicle.purchasePrice,
                    currentOdometer <- vehicle.currentOdometer,
                    fuelType <- vehicle.fuelType.rawValue,
                    notes <- vehicle.notes,
                    createdAt <- vehicle.createdAt.timeIntervalSince1970,
                    updatedAt <- Date().timeIntervalSince1970
                ))
            }
        }
    }

    func getAllVehicles() throws -> [Vehicle] {
        guard let db = db else { throw DatabaseError.notConnected }
        var result: [Vehicle] = []
        for row in try db.prepare(vehicles.order(createdAt.desc)) {
            var vehicle = Vehicle(
                name: row[name],
                type: VehicleType(rawValue: row[type]) ?? .truck,
                licensePlate: row[licensePlate],
                make: row[make],
                model: row[model],
                year: row[year],
                vin: row[vin],
                status: VehicleStatus(rawValue: row[status]) ?? .available,
                currentOdometer: row[currentOdometer],
                fuelType: FuelType(rawValue: row[fuelType]) ?? .diesel,
                notes: row[notes]
            )
            vehicle.id = UUID(uuidString: row[id]) ?? UUID()
            if let pd = row[purchaseDate] {
                vehicle.purchaseDate = Date(timeIntervalSince1970: pd)
            }
            vehicle.purchasePrice = row[purchasePrice]
            vehicle.createdAt = Date(timeIntervalSince1970: row[createdAt])
            vehicle.updatedAt = Date(timeIntervalSince1970: row[updatedAt])
            result.append(vehicle)
        }
        return result
    }

    func deleteVehicle(_ vehicle: Vehicle) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        try transaction {
            let vid = vehicle.id.uuidString
            let relatedMaintenance = maintenanceRecords.filter(self.vehicleId == vid)
            try db.run(relatedMaintenance.delete())
            let relatedFuel = fuelLogs.filter(self.vehicleId == vid)
            try db.run(relatedFuel.delete())
            let relatedExpenses = expenses.filter(expenseVehicleId == vid)
            try db.run(relatedExpenses.delete())
            let vehicleRow = vehicles.filter(id == vid)
            try db.run(vehicleRow.delete())
        }
    }

    // MARK: - Driver CRUD

    func saveDriver(_ driver: Driver) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        try transaction {
            let existing = try db.pluck(drivers.filter(id == driver.id.uuidString))
            if existing != nil {
                let row = drivers.filter(id == driver.id.uuidString)
                try db.run(row.update(
                    firstName <- driver.firstName,
                    lastName <- driver.lastName,
                    email <- driver.email,
                    phone <- driver.phone,
                    address <- driver.address,
                    emergencyContact <- driver.emergencyContact,
                    emergencyPhone <- driver.emergencyPhone,
                    licenseNumber <- driver.licenseNumber,
                    licenseState <- driver.licenseState,
                    licenseExpiry <- driver.licenseExpiry.timeIntervalSince1970,
                    status <- driver.status.rawValue,
                    hireDate <- driver.hireDate.timeIntervalSince1970,
                    terminationDate <- driver.terminationDate?.timeIntervalSince1970,
                    notes <- driver.notes,
                    rating <- driver.rating,
                    updatedAt <- Date().timeIntervalSince1970
                ))
            } else {
                try db.run(drivers.insert(
                    id <- driver.id.uuidString,
                    firstName <- driver.firstName,
                    lastName <- driver.lastName,
                    email <- driver.email,
                    phone <- driver.phone,
                    address <- driver.address,
                    emergencyContact <- driver.emergencyContact,
                    emergencyPhone <- driver.emergencyPhone,
                    licenseNumber <- driver.licenseNumber,
                    licenseState <- driver.licenseState,
                    licenseExpiry <- driver.licenseExpiry.timeIntervalSince1970,
                    status <- driver.status.rawValue,
                    hireDate <- driver.hireDate.timeIntervalSince1970,
                    terminationDate <- driver.terminationDate?.timeIntervalSince1970,
                    notes <- driver.notes,
                    rating <- driver.rating,
                    createdAt <- driver.createdAt.timeIntervalSince1970,
                    updatedAt <- Date().timeIntervalSince1970
                ))
            }
        }
    }

    func getAllDrivers() throws -> [Driver] {
        guard let db = db else { throw DatabaseError.notConnected }
        var result: [Driver] = []
        for row in try db.prepare(drivers.order(createdAt.desc)) {
            var driver = Driver(
                firstName: row[firstName],
                lastName: row[lastName],
                email: row[email],
                phone: row[phone],
                address: row[address],
                emergencyContact: row[emergencyContact],
                emergencyPhone: row[emergencyPhone],
                licenseNumber: row[licenseNumber],
                licenseState: row[licenseState],
                licenseExpiry: Date(timeIntervalSince1970: row[licenseExpiry]),
                status: DriverStatus(rawValue: row[status]) ?? .active,
                hireDate: Date(timeIntervalSince1970: row[hireDate]),
                terminationDate: row[terminationDate].map { Date(timeIntervalSince1970: $0) },
                notes: row[notes],
                rating: row[rating]
            )
            driver.id = UUID(uuidString: row[id]) ?? UUID()
            driver.createdAt = Date(timeIntervalSince1970: row[createdAt])
            driver.updatedAt = Date(timeIntervalSince1970: row[updatedAt])
            result.append(driver)
        }
        return result
    }

    func deleteDriver(_ driver: Driver) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        try transaction {
            let did = driver.id.uuidString
            let relatedCerts = certifications.filter(self.driverId == did)
            try db.run(relatedCerts.delete())
            let relatedExpenses = expenses.filter(expenseDriverId == did)
            try db.run(relatedExpenses.delete())
            let driverRow = drivers.filter(id == did)
            try db.run(driverRow.delete())
        }
    }

    // MARK: - Trip CRUD

    func saveTrip(_ trip: Trip) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        try transaction {
            let existing = try db.pluck(trips.filter(id == trip.id.uuidString))
            if existing != nil {
                let row = trips.filter(id == trip.id.uuidString)
                try db.run(row.update(
                    jobNumber <- trip.jobNumber,
                    customerId <- trip.customerId.uuidString,
                    tripDriverId <- trip.driverId?.uuidString,
                    tripVehicleId <- trip.vehicleId?.uuidString,
                    tripStatus <- trip.status.rawValue,
                    pickupAddress <- trip.pickupAddress,
                    pickupCity <- trip.pickupCity,
                    pickupState <- trip.pickupState,
                    pickupZip <- trip.pickupZip,
                    pickupDate <- trip.pickupDate.timeIntervalSince1970,
                    deliveryAddress <- trip.deliveryAddress,
                    deliveryCity <- trip.deliveryCity,
                    deliveryState <- trip.deliveryState,
                    deliveryZip <- trip.deliveryZip,
                    deliveryDate <- trip.deliveryDate?.timeIntervalSince1970,
                    distance <- trip.distance,
                    cargoDescription <- trip.cargoDescription,
                    cargoWeight <- trip.cargoWeight,
                    rate <- trip.rate,
                    fuelSurcharge <- trip.fuelSurcharge,
                    totalAmount <- trip.totalAmount,
                    notes <- trip.notes,
                    updatedAt <- Date().timeIntervalSince1970
                ))
            } else {
                try db.run(trips.insert(
                    id <- trip.id.uuidString,
                    jobNumber <- trip.jobNumber,
                    customerId <- trip.customerId.uuidString,
                    tripDriverId <- trip.driverId?.uuidString,
                    tripVehicleId <- trip.vehicleId?.uuidString,
                    tripStatus <- trip.status.rawValue,
                    pickupAddress <- trip.pickupAddress,
                    pickupCity <- trip.pickupCity,
                    pickupState <- trip.pickupState,
                    pickupZip <- trip.pickupZip,
                    pickupDate <- trip.pickupDate.timeIntervalSince1970,
                    deliveryAddress <- trip.deliveryAddress,
                    deliveryCity <- trip.deliveryCity,
                    deliveryState <- trip.deliveryState,
                    deliveryZip <- trip.deliveryZip,
                    deliveryDate <- trip.deliveryDate?.timeIntervalSince1970,
                    distance <- trip.distance,
                    cargoDescription <- trip.cargoDescription,
                    cargoWeight <- trip.cargoWeight,
                    rate <- trip.rate,
                    fuelSurcharge <- trip.fuelSurcharge,
                    totalAmount <- trip.totalAmount,
                    notes <- trip.notes,
                    createdAt <- trip.createdAt.timeIntervalSince1970,
                    updatedAt <- Date().timeIntervalSince1970
                ))
            }
        }
    }

    func getAllTrips() throws -> [Trip] {
        guard let db = db else { throw DatabaseError.notConnected }
        var result: [Trip] = []
        for row in try db.prepare(trips.order(pickupDate.desc)) {
            var trip = Trip(
                jobNumber: row[jobNumber],
                customerId: UUID(uuidString: row[customerId]) ?? UUID(),
                driverId: row[tripDriverId].flatMap { UUID(uuidString: $0) },
                vehicleId: row[tripVehicleId].flatMap { UUID(uuidString: $0) },
                status: TripStatus(rawValue: row[tripStatus]) ?? .pending,
                pickupAddress: row[pickupAddress],
                pickupCity: row[pickupCity],
                pickupState: row[pickupState],
                pickupZip: row[pickupZip],
                pickupDate: Date(timeIntervalSince1970: row[pickupDate]),
                deliveryAddress: row[deliveryAddress],
                deliveryCity: row[deliveryCity],
                deliveryState: row[deliveryState],
                deliveryZip: row[deliveryZip],
                distance: row[distance],
                cargoDescription: row[cargoDescription],
                cargoWeight: row[cargoWeight],
                rate: row[rate],
                fuelSurcharge: row[fuelSurcharge],
                totalAmount: row[totalAmount],
                notes: row[notes]
            )
            trip.id = UUID(uuidString: row[id]) ?? UUID()
            trip.deliveryDate = row[deliveryDate].map { Date(timeIntervalSince1970: $0) }
            trip.createdAt = Date(timeIntervalSince1970: row[createdAt])
            trip.updatedAt = Date(timeIntervalSince1970: row[updatedAt])
            result.append(trip)
        }
        return result
    }

    func deleteTrip(_ trip: Trip) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        try transaction {
            let tid = trip.id.uuidString
            let relatedUpdates = tripUpdates.filter(self.tripId == tid)
            try db.run(relatedUpdates.delete())
            let relatedInvoiceTrips = invoiceTrips.filter(invoiceTripTripId == tid)
            try db.run(relatedInvoiceTrips.delete())
            let tripRow = trips.filter(id == tid)
            try db.run(tripRow.delete())
        }
    }

    // MARK: - Customer CRUD

    func saveCustomer(_ customer: Customer) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        try transaction {
            let existing = try db.pluck(customers.filter(id == customer.id.uuidString))
            if existing != nil {
                let row = customers.filter(id == customer.id.uuidString)
                try db.run(row.update(
                    companyName <- customer.companyName,
                    contactName <- customer.contactName,
                    email <- customer.email,
                    phone <- customer.phone,
                    customerType <- customer.type.rawValue,
                    address <- customer.address,
                    city <- customer.city,
                    state <- customer.state,
                    zip <- customer.zip,
                    creditLimit <- customer.creditLimit,
                    paymentTerms <- customer.paymentTerms,
                    taxId <- customer.taxId,
                    notes <- customer.notes,
                    updatedAt <- Date().timeIntervalSince1970
                ))
            } else {
                try db.run(customers.insert(
                    id <- customer.id.uuidString,
                    companyName <- customer.companyName,
                    contactName <- customer.contactName,
                    email <- customer.email,
                    phone <- customer.phone,
                    customerType <- customer.type.rawValue,
                    address <- customer.address,
                    city <- customer.city,
                    state <- customer.state,
                    zip <- customer.zip,
                    creditLimit <- customer.creditLimit,
                    paymentTerms <- customer.paymentTerms,
                    taxId <- customer.taxId,
                    notes <- customer.notes,
                    createdAt <- customer.createdAt.timeIntervalSince1970,
                    updatedAt <- Date().timeIntervalSince1970
                ))
            }
        }
    }

    func getAllCustomers() throws -> [Customer] {
        guard let db = db else { throw DatabaseError.notConnected }
        var result: [Customer] = []
        for row in try db.prepare(customers.order(companyName)) {
            var customer = Customer(
                companyName: row[companyName],
                contactName: row[contactName],
                email: row[email],
                phone: row[phone],
                type: CustomerType(rawValue: row[customerType]) ?? .commercial,
                address: row[address] ?? "",
                city: row[city],
                state: row[state],
                zip: row[zip],
                creditLimit: row[creditLimit],
                paymentTerms: row[paymentTerms],
                taxId: row[taxId],
                notes: row[notes]
            )
            customer.id = UUID(uuidString: row[id]) ?? UUID()
            customer.createdAt = Date(timeIntervalSince1970: row[createdAt])
            customer.updatedAt = Date(timeIntervalSince1970: row[updatedAt])
            result.append(customer)
        }
        return result
    }

    func deleteCustomer(_ customer: Customer) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        try transaction {
            let cid = customer.id.uuidString
            let relatedTrips = trips.filter(self.customerId == cid)
            let tripIdsToDelete: [String] = try db.prepare(relatedTrips.select(id)).map { $0[id] }
            let invoiceIds: [String] = try db.prepare(invoices.filter(self.customerId == cid).select(id)).map { $0[id] }
            for invId in invoiceIds {
                try db.run(invoiceTrips.filter(invoiceTripInvoiceId == invId).delete())
            }
            try db.run(invoices.filter(self.customerId == cid).delete())
            for tid in tripIdsToDelete {
                let relatedUpdates = tripUpdates.filter(self.tripId == tid)
                try db.run(relatedUpdates.delete())
            }
            try db.run(relatedTrips.delete())
            let customerRow = customers.filter(id == cid)
            try db.run(customerRow.delete())
        }
    }

    // MARK: - Invoice CRUD

    func saveInvoice(_ invoice: Invoice) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        try transaction {
            let existing = try db.pluck(invoices.filter(id == invoice.id.uuidString))
            let tripIdStrings = invoice.tripIds.map { $0.uuidString }
            if existing != nil {
                let row = invoices.filter(id == invoice.id.uuidString)
                try db.run(row.update(
                    invoiceNumber <- invoice.invoiceNumber,
                    customerId <- invoice.customerId.uuidString,
                    tripIds <- tripIdStrings.joined(separator: ","),
                    invoiceDate <- invoice.invoiceDate.timeIntervalSince1970,
                    dueDate <- invoice.dueDate.timeIntervalSince1970,
                    subtotal <- invoice.subtotal,
                    tax <- invoice.tax,
                    total <- invoice.total,
                    invoiceStatus <- invoice.status.rawValue,
                    paidDate <- invoice.paidDate?.timeIntervalSince1970,
                    notes <- invoice.notes,
                    updatedAt <- Date().timeIntervalSince1970
                ))
                let deleteJunction = invoiceTrips.filter(invoiceTripInvoiceId == invoice.id.uuidString)
                try db.run(deleteJunction.delete())
            } else {
                try db.run(invoices.insert(
                    id <- invoice.id.uuidString,
                    invoiceNumber <- invoice.invoiceNumber,
                    customerId <- invoice.customerId.uuidString,
                    tripIds <- tripIdStrings.joined(separator: ","),
                    invoiceDate <- invoice.invoiceDate.timeIntervalSince1970,
                    dueDate <- invoice.dueDate.timeIntervalSince1970,
                    subtotal <- invoice.subtotal,
                    tax <- invoice.tax,
                    total <- invoice.total,
                    invoiceStatus <- invoice.status.rawValue,
                    paidDate <- invoice.paidDate?.timeIntervalSince1970,
                    notes <- invoice.notes,
                    createdAt <- invoice.createdAt.timeIntervalSince1970,
                    updatedAt <- Date().timeIntervalSince1970
                ))
            }
            for tripIdStr in tripIdStrings {
                try db.run(invoiceTrips.insert(
                    invoiceTripInvoiceId <- invoice.id.uuidString,
                    invoiceTripTripId <- tripIdStr
                ))
            }
        }
    }

    func getAllInvoices() throws -> [Invoice] {
        guard let db = db else { throw DatabaseError.notConnected }
        var result: [Invoice] = []
        for row in try db.prepare(invoices.order(invoiceDate.desc)) {
            let invoiceIdStr = row[id]
            var linkedTripIds: [UUID] = []
            let junctionQuery = invoiceTrips.filter(invoiceTripInvoiceId == invoiceIdStr)
            for junctionRow in try db.prepare(junctionQuery) {
                if let tripUUID = UUID(uuidString: junctionRow[invoiceTripTripId]) {
                    linkedTripIds.append(tripUUID)
                }
            }
            if linkedTripIds.isEmpty {
                linkedTripIds = row[tripIds].split(separator: ",").compactMap { UUID(uuidString: String($0)) }
            }
            var invoice = Invoice(
                invoiceNumber: row[invoiceNumber],
                customerId: UUID(uuidString: row[customerId]) ?? UUID(),
                tripIds: linkedTripIds,
                invoiceDate: Date(timeIntervalSince1970: row[invoiceDate]),
                dueDate: Date(timeIntervalSince1970: row[dueDate]),
                subtotal: row[subtotal],
                tax: row[tax],
                total: row[total],
                status: InvoiceStatus(rawValue: row[invoiceStatus]) ?? .draft,
                paidDate: row[paidDate].map { Date(timeIntervalSince1970: $0) },
                notes: row[notes]
            )
            invoice.id = UUID(uuidString: invoiceIdStr) ?? UUID()
            invoice.createdAt = Date(timeIntervalSince1970: row[createdAt])
            invoice.updatedAt = Date(timeIntervalSince1970: row[updatedAt])
            result.append(invoice)
        }
        return result
    }

    func deleteInvoice(_ invoice: Invoice) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        try transaction {
            let iid = invoice.id.uuidString
            let relatedJunction = invoiceTrips.filter(invoiceTripInvoiceId == iid)
            try db.run(relatedJunction.delete())
            let invoiceRow = invoices.filter(id == iid)
            try db.run(invoiceRow.delete())
        }
    }

    // MARK: - Expense CRUD

    func saveExpense(_ expense: Expense) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        try transaction {
            let existing = try db.pluck(expenses.filter(id == expense.id.uuidString))
            if existing != nil {
                let row = expenses.filter(id == expense.id.uuidString)
                try db.run(row.update(
                    category <- expense.category.rawValue,
                    expenseVendor <- expense.vendor,
                    description <- expense.description,
                    amount <- expense.amount,
                    date <- expense.date.timeIntervalSince1970,
                    expenseVehicleId <- expense.vehicleId?.uuidString,
                    expenseDriverId <- expense.driverId?.uuidString,
                    receiptNumber <- expense.receiptNumber,
                    notes <- expense.notes
                ))
            } else {
                try db.run(expenses.insert(
                    id <- expense.id.uuidString,
                    category <- expense.category.rawValue,
                    expenseVendor <- expense.vendor,
                    description <- expense.description,
                    amount <- expense.amount,
                    date <- expense.date.timeIntervalSince1970,
                    expenseVehicleId <- expense.vehicleId?.uuidString,
                    expenseDriverId <- expense.driverId?.uuidString,
                    receiptNumber <- expense.receiptNumber,
                    notes <- expense.notes,
                    createdAt <- expense.createdAt.timeIntervalSince1970
                ))
            }
        }
    }

    func getAllExpenses() throws -> [Expense] {
        guard let db = db else { throw DatabaseError.notConnected }
        var result: [Expense] = []
        for row in try db.prepare(expenses.order(date.desc)) {
            var expense = Expense(
                category: ExpenseCategory(rawValue: row[category]) ?? .other,
                vendor: row[expenseVendor],
                description: row[description],
                amount: row[amount],
                date: Date(timeIntervalSince1970: row[date]),
                vehicleId: row[expenseVehicleId].flatMap { UUID(uuidString: $0) },
                driverId: row[expenseDriverId].flatMap { UUID(uuidString: $0) },
                receiptNumber: row[receiptNumber],
                notes: row[notes]
            )
            expense.id = UUID(uuidString: row[id]) ?? UUID()
            expense.createdAt = Date(timeIntervalSince1970: row[createdAt])
            result.append(expense)
        }
        return result
    }

    func deleteExpense(_ expense: Expense) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        let expenseRow = expenses.filter(id == expense.id.uuidString)
        try db.run(expenseRow.delete())
    }

    // MARK: - Maintenance Record CRUD

    func saveMaintenanceRecord(_ record: MaintenanceRecord) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        try transaction {
            let existing = try db.pluck(maintenanceRecords.filter(id == record.id.uuidString))
            if existing != nil {
                let row = maintenanceRecords.filter(id == record.id.uuidString)
                try db.run(row.update(
                    vehicleId <- record.vehicleId.uuidString,
                    maintenanceType <- record.type.rawValue,
                    description <- record.description,
                    date <- record.date.timeIntervalSince1970,
                    odometer <- record.odometer,
                    cost <- record.cost,
                    vendor <- record.vendor,
                    notes <- record.notes
                ))
            } else {
                try db.run(maintenanceRecords.insert(
                    id <- record.id.uuidString,
                    vehicleId <- record.vehicleId.uuidString,
                    maintenanceType <- record.type.rawValue,
                    description <- record.description,
                    date <- record.date.timeIntervalSince1970,
                    odometer <- record.odometer,
                    cost <- record.cost,
                    vendor <- record.vendor,
                    notes <- record.notes,
                    createdAt <- record.createdAt.timeIntervalSince1970
                ))
            }
        }
    }

    func getAllMaintenanceRecords(for vehicleId: UUID? = nil) throws -> [MaintenanceRecord] {
        guard let db = db else { throw DatabaseError.notConnected }
        var result: [MaintenanceRecord] = []
        var query = maintenanceRecords.order(date.desc)
        if let vid = vehicleId {
            query = query.filter(self.vehicleId == vid.uuidString)
        }
        for row in try db.prepare(query) {
            var record = MaintenanceRecord(
                vehicleId: UUID(uuidString: row[self.vehicleId]) ?? UUID(),
                type: MaintenanceType(rawValue: row[maintenanceType]) ?? .other,
                description: row[description],
                date: Date(timeIntervalSince1970: row[date]),
                odometer: row[odometer],
                cost: row[cost],
                vendor: row[vendor],
                notes: row[notes]
            )
            record.id = UUID(uuidString: row[id]) ?? UUID()
            record.createdAt = Date(timeIntervalSince1970: row[createdAt])
            result.append(record)
        }
        return result
    }

    func deleteMaintenanceRecord(_ record: MaintenanceRecord) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        let row = maintenanceRecords.filter(id == record.id.uuidString)
        try db.run(row.delete())
    }

    // MARK: - Fuel Log CRUD

    func saveFuelLog(_ log: FuelLog) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        try transaction {
            let existing = try db.pluck(fuelLogs.filter(id == log.id.uuidString))
            if existing != nil {
                let row = fuelLogs.filter(id == log.id.uuidString)
                try db.run(row.update(
                    vehicleId <- log.vehicleId.uuidString,
                    date <- log.date.timeIntervalSince1970,
                    odometer <- log.odometer,
                    quantity <- log.quantity,
                    pricePerUnit <- log.pricePerUnit,
                    totalCost <- log.totalCost,
                    fuelType <- log.fuelType.rawValue,
                    location <- log.location,
                    notes <- log.notes
                ))
            } else {
                try db.run(fuelLogs.insert(
                    id <- log.id.uuidString,
                    vehicleId <- log.vehicleId.uuidString,
                    date <- log.date.timeIntervalSince1970,
                    odometer <- log.odometer,
                    quantity <- log.quantity,
                    pricePerUnit <- log.pricePerUnit,
                    totalCost <- log.totalCost,
                    fuelType <- log.fuelType.rawValue,
                    location <- log.location,
                    notes <- log.notes,
                    createdAt <- log.createdAt.timeIntervalSince1970
                ))
            }
        }
    }

    func getAllFuelLogs(for vehicleId: UUID? = nil) throws -> [FuelLog] {
        guard let db = db else { throw DatabaseError.notConnected }
        var result: [FuelLog] = []
        var query = fuelLogs.order(date.desc)
        if let vid = vehicleId {
            query = query.filter(self.vehicleId == vid.uuidString)
        }
        for row in try db.prepare(query) {
            var log = FuelLog(
                vehicleId: UUID(uuidString: row[self.vehicleId]) ?? UUID(),
                date: Date(timeIntervalSince1970: row[date]),
                odometer: row[odometer],
                quantity: row[quantity],
                pricePerUnit: row[pricePerUnit],
                totalCost: row[totalCost],
                fuelType: FuelType(rawValue: row[fuelType]) ?? .diesel,
                location: row[location],
                notes: row[notes]
            )
            log.id = UUID(uuidString: row[id]) ?? UUID()
            log.createdAt = Date(timeIntervalSince1970: row[createdAt])
            result.append(log)
        }
        return result
    }

    func deleteFuelLog(_ log: FuelLog) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        let row = fuelLogs.filter(id == log.id.uuidString)
        try db.run(row.delete())
    }

    // MARK: - Certification CRUD

    func saveCertification(_ cert: Certification) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        try transaction {
            let existing = try db.pluck(certifications.filter(id == cert.id.uuidString))
            if existing != nil {
                let row = certifications.filter(id == cert.id.uuidString)
                try db.run(row.update(
                    driverId <- cert.driverId.uuidString,
                    certificationType <- cert.type.rawValue,
                    name <- cert.name,
                    issuedDate <- cert.issuedDate.timeIntervalSince1970,
                    expiryDate <- cert.expiryDate?.timeIntervalSince1970,
                    documentNumber <- cert.documentNumber
                ))
            } else {
                try db.run(certifications.insert(
                    id <- cert.id.uuidString,
                    driverId <- cert.driverId.uuidString,
                    certificationType <- cert.type.rawValue,
                    name <- cert.name,
                    issuedDate <- cert.issuedDate.timeIntervalSince1970,
                    expiryDate <- cert.expiryDate?.timeIntervalSince1970,
                    documentNumber <- cert.documentNumber,
                    createdAt <- cert.createdAt.timeIntervalSince1970
                ))
            }
        }
    }

    func getAllCertifications(for driverId: UUID? = nil) throws -> [Certification] {
        guard let db = db else { throw DatabaseError.notConnected }
        var result: [Certification] = []
        var query = certifications.order(issuedDate.desc)
        if let did = driverId {
            query = query.filter(self.driverId == did.uuidString)
        }
        for row in try db.prepare(query) {
            var cert = Certification(
                driverId: UUID(uuidString: row[self.driverId]) ?? UUID(),
                type: CertificationType(rawValue: row[certificationType]) ?? .other,
                name: row[name],
                issuedDate: Date(timeIntervalSince1970: row[issuedDate]),
                expiryDate: row[expiryDate].map { Date(timeIntervalSince1970: $0) },
                documentNumber: row[documentNumber]
            )
            cert.id = UUID(uuidString: row[id]) ?? UUID()
            cert.createdAt = Date(timeIntervalSince1970: row[createdAt])
            result.append(cert)
        }
        return result
    }

    func deleteCertification(_ cert: Certification) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        let row = certifications.filter(id == cert.id.uuidString)
        try db.run(row.delete())
    }

    // MARK: - Settings

    func saveSettings(_ settings: BusinessSettings) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        guard let data = try? JSONEncoder().encode(settings),
              let json = String(data: data, encoding: .utf8) else {
            throw DatabaseError.saveFailed("Failed to encode settings")
        }
        let existing = try db.pluck(self.settings.filter(settingsKey == "business_settings"))
        if existing != nil {
            let row = self.settings.filter(settingsKey == "business_settings")
            try db.run(row.update(settingsValue <- json))
        } else {
            try db.run(self.settings.insert(
                settingsKey <- "business_settings",
                settingsValue <- json
            ))
        }
    }

    func loadSettings() -> BusinessSettings {
        guard let db = db else { return .default }
        do {
            let query = self.settings.filter(self.settingsKey == "business_settings")
            if let row = try db.pluck(query) {
                let json = row[self.settingsValue]
                if let data = json.data(using: .utf8),
                   let settings = try? JSONDecoder().decode(BusinessSettings.self, from: data) {
                    return settings
                }
            }
        } catch {
            print("Load settings failed: \(error)")
        }
        return .default
    }

    // MARK: - Dashboard Stats (SQL Aggregates)

    func getDashboardStats() throws -> DashboardStats {
        guard let db = db else {
            return DashboardStats(
                totalVehicles: 0, activeVehicles: 0, totalDrivers: 0, activeDrivers: 0,
                todayTrips: 0, pendingTrips: 0, monthlyRevenue: 0, monthlyExpenses: 0,
                fleetUtilization: 0, overdueMaintenance: 0, expiringLicenses: 0, activeCustomers: 0
            )
        }

        let totalVehicles = try db.scalar(vehicles.count) ?? 0
        let activeVehicles = try db.scalar(vehicles.filter(status != "Retired").count) ?? 0
        let inUseVehicles = try db.scalar(vehicles.filter(status == "In Use").count) ?? 0
        let maintenanceVehicles = try db.scalar(vehicles.filter(status == "Maintenance").count) ?? 0

        let totalDrivers = try db.scalar(drivers.count) ?? 0
        let activeDrivers = try db.scalar(drivers.filter(status == "Active").count) ?? 0

        let totalCustomers = try db.scalar(customers.count) ?? 0

        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let startOfMonthTimestamp = startOfMonth.timeIntervalSince1970

        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let todayTimestamp = today.timeIntervalSince1970
        let tomorrowTimestamp = tomorrow.timeIntervalSince1970

        let todayTrips = try db.scalar(trips.filter(pickupDate >= todayTimestamp && pickupDate < tomorrowTimestamp).count) ?? 0
        let pendingTrips = try db.scalar(trips.filter(tripStatus == "Pending").count) ?? 0

        let monthlyRevenue = try db.scalar(
            trips.filter(pickupDate >= startOfMonthTimestamp && tripStatus == "Completed").select(totalAmount.sum)
        ) as? Double ?? 0

        let monthlyExpenses = try db.scalar(
            expenses.filter(date >= startOfMonthTimestamp).select(amount.sum)
        ) as? Double ?? 0

        let fleetUtilization = activeVehicles > 0 ? Double(inUseVehicles) / Double(activeVehicles) * 100 : 0

        let thirtyDaysFromNow = Date().addingTimeInterval(30 * 24 * 60 * 60)
        let thirtyDaysTimestamp = thirtyDaysFromNow.timeIntervalSince1970
        let nowTimestamp = Date().timeIntervalSince1970
        let expiringLicenses = try db.scalar(
            drivers.filter(licenseExpiry > nowTimestamp && licenseExpiry <= thirtyDaysTimestamp && status == "Active").count
        ) ?? 0

        return DashboardStats(
            totalVehicles: totalVehicles,
            activeVehicles: activeVehicles,
            totalDrivers: totalDrivers,
            activeDrivers: activeDrivers,
            todayTrips: todayTrips,
            pendingTrips: pendingTrips,
            monthlyRevenue: monthlyRevenue,
            monthlyExpenses: monthlyExpenses,
            fleetUtilization: fleetUtilization,
            overdueMaintenance: maintenanceVehicles,
            expiringLicenses: expiringLicenses,
            activeCustomers: totalCustomers
        )
    }

    // MARK: - Reports Data

    func getRevenueByMonth(months: Int = 12) throws -> [(Date, Double)] {
        guard let db = db else { return [] }
        let calendar = Calendar.current
        let now = Date()
        var result: [(Date, Double)] = []

        for i in 0..<months {
            let monthDate = calendar.date(byAdding: .month, value: -i, to: now)!
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
            guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { continue }

            let startTs = startOfMonth.timeIntervalSince1970
            let endTs = endOfMonth.timeIntervalSince1970

            let monthRevenue = try db.scalar(
                trips.filter(pickupDate >= startTs && pickupDate < endTs && (tripStatus == "Completed" || tripStatus == "Delivered"))
                    .select(totalAmount.sum)
            ) as? Double ?? 0

            result.append((startOfMonth, monthRevenue))
        }
        return result.reversed()
    }

    func getExpensesByCategory() throws -> [(ExpenseCategory, Double)] {
        guard let db = db else { return [] }
        var result: [(ExpenseCategory, Double)] = []
        let categoryColumn = SQLExpression<String>("category")
        for row in try db.prepare(expenses.group(categoryColumn)) {
            let cat = ExpenseCategory(rawValue: row[categoryColumn]) ?? .other
            let sum = try db.scalar(expenses.filter(categoryColumn == row[categoryColumn]).select(amount.sum)) as? Double ?? 0
            result.append((cat, sum))
        }
        return result.sorted { $0.1 > $1.1 }
    }

    func getFleetUtilization(includeRetired: Bool = false) throws -> [(VehicleStatus, Int)] {
        guard let db = db else { return [] }
        var result: [(VehicleStatus, Int)] = []
        let statusColumn = SQLExpression<String>("status")
        var query = vehicles.group(statusColumn)
        if !includeRetired {
            query = vehicles.filter(status != "Retired").group(statusColumn)
        }
        for row in try db.prepare(query) {
            let st = VehicleStatus(rawValue: row[statusColumn]) ?? .available
            let count = try db.scalar(vehicles.filter(statusColumn == row[statusColumn]).count) ?? 0
            result.append((st, count))
        }
        return result.sorted { $0.1 > $1.1 }
    }

    func getTripsByStatus() throws -> [(TripStatus, Int)] {
        guard let db = db else { return [] }
        var result: [(TripStatus, Int)] = []
        let statusColumn = SQLExpression<String>("status")
        for row in try db.prepare(trips.group(statusColumn)) {
            let st = TripStatus(rawValue: row[statusColumn]) ?? .pending
            let count = try db.scalar(trips.filter(statusColumn == row[statusColumn]).count) ?? 0
            result.append((st, count))
        }
        return result.sorted { $0.1 > $1.1 }
    }

    // MARK: - Import / Export

    func exportAllData() throws -> Data {
        guard let db = db else { throw DatabaseError.notConnected }

        var exportVehicles: [Vehicle] = []
        for row in try db.prepare(vehicles.order(createdAt.desc)) {
            var vehicle = Vehicle(
                name: row[name],
                type: VehicleType(rawValue: row[type]) ?? .truck,
                licensePlate: row[licensePlate],
                make: row[make],
                model: row[model],
                year: row[year],
                vin: row[vin],
                status: VehicleStatus(rawValue: row[status]) ?? .available,
                currentOdometer: row[currentOdometer],
                fuelType: FuelType(rawValue: row[fuelType]) ?? .diesel,
                notes: row[notes]
            )
            vehicle.id = UUID(uuidString: row[id]) ?? UUID()
            if let pd = row[purchaseDate] {
                vehicle.purchaseDate = Date(timeIntervalSince1970: pd)
            }
            vehicle.purchasePrice = row[purchasePrice]
            vehicle.createdAt = Date(timeIntervalSince1970: row[createdAt])
            vehicle.updatedAt = Date(timeIntervalSince1970: row[updatedAt])
            exportVehicles.append(vehicle)
        }

        var exportDrivers: [Driver] = []
        for row in try db.prepare(drivers.order(createdAt.desc)) {
            var driver = Driver(
                firstName: row[firstName],
                lastName: row[lastName],
                email: row[email],
                phone: row[phone],
                address: row[address],
                emergencyContact: row[emergencyContact],
                emergencyPhone: row[emergencyPhone],
                licenseNumber: row[licenseNumber],
                licenseState: row[licenseState],
                licenseExpiry: Date(timeIntervalSince1970: row[licenseExpiry]),
                status: DriverStatus(rawValue: row[status]) ?? .active,
                hireDate: Date(timeIntervalSince1970: row[hireDate]),
                terminationDate: row[terminationDate].map { Date(timeIntervalSince1970: $0) },
                notes: row[notes],
                rating: row[rating]
            )
            driver.id = UUID(uuidString: row[id]) ?? UUID()
            driver.createdAt = Date(timeIntervalSince1970: row[createdAt])
            driver.updatedAt = Date(timeIntervalSince1970: row[updatedAt])
            exportDrivers.append(driver)
        }

        var exportTrips: [Trip] = []
        for row in try db.prepare(trips.order(pickupDate.desc)) {
            var trip = Trip(
                jobNumber: row[jobNumber],
                customerId: UUID(uuidString: row[customerId]) ?? UUID(),
                driverId: row[tripDriverId].flatMap { UUID(uuidString: $0) },
                vehicleId: row[tripVehicleId].flatMap { UUID(uuidString: $0) },
                status: TripStatus(rawValue: row[tripStatus]) ?? .pending,
                pickupAddress: row[pickupAddress],
                pickupCity: row[pickupCity],
                pickupState: row[pickupState],
                pickupZip: row[pickupZip],
                pickupDate: Date(timeIntervalSince1970: row[pickupDate]),
                deliveryAddress: row[deliveryAddress],
                deliveryCity: row[deliveryCity],
                deliveryState: row[deliveryState],
                deliveryZip: row[deliveryZip],
                distance: row[distance],
                cargoDescription: row[cargoDescription],
                cargoWeight: row[cargoWeight],
                rate: row[rate],
                fuelSurcharge: row[fuelSurcharge],
                totalAmount: row[totalAmount],
                notes: row[notes]
            )
            trip.id = UUID(uuidString: row[id]) ?? UUID()
            trip.deliveryDate = row[deliveryDate].map { Date(timeIntervalSince1970: $0) }
            trip.createdAt = Date(timeIntervalSince1970: row[createdAt])
            trip.updatedAt = Date(timeIntervalSince1970: row[updatedAt])
            exportTrips.append(trip)
        }

        var exportCustomers: [Customer] = []
        for row in try db.prepare(customers.order(companyName)) {
            var customer = Customer(
                companyName: row[companyName],
                contactName: row[contactName],
                email: row[email],
                phone: row[phone],
                type: CustomerType(rawValue: row[customerType]) ?? .commercial,
                address: row[address] ?? "",
                city: row[city],
                state: row[state],
                zip: row[zip],
                creditLimit: row[creditLimit],
                paymentTerms: row[paymentTerms],
                taxId: row[taxId],
                notes: row[notes]
            )
            customer.id = UUID(uuidString: row[id]) ?? UUID()
            customer.createdAt = Date(timeIntervalSince1970: row[createdAt])
            customer.updatedAt = Date(timeIntervalSince1970: row[updatedAt])
            exportCustomers.append(customer)
        }

        var exportInvoices: [Invoice] = []
        for row in try db.prepare(invoices.order(invoiceDate.desc)) {
            let invoiceIdStr = row[id]
            var linkedTripIds: [UUID] = []
            let junctionQuery = invoiceTrips.filter(invoiceTripInvoiceId == invoiceIdStr)
            for junctionRow in try db.prepare(junctionQuery) {
                if let tripUUID = UUID(uuidString: junctionRow[invoiceTripTripId]) {
                    linkedTripIds.append(tripUUID)
                }
            }
            if linkedTripIds.isEmpty {
                linkedTripIds = row[tripIds].split(separator: ",").compactMap { UUID(uuidString: String($0)) }
            }
            var invoice = Invoice(
                invoiceNumber: row[invoiceNumber],
                customerId: UUID(uuidString: row[customerId]) ?? UUID(),
                tripIds: linkedTripIds,
                invoiceDate: Date(timeIntervalSince1970: row[invoiceDate]),
                dueDate: Date(timeIntervalSince1970: row[dueDate]),
                subtotal: row[subtotal],
                tax: row[tax],
                total: row[total],
                status: InvoiceStatus(rawValue: row[invoiceStatus]) ?? .draft,
                paidDate: row[paidDate].map { Date(timeIntervalSince1970: $0) },
                notes: row[notes]
            )
            invoice.id = UUID(uuidString: invoiceIdStr) ?? UUID()
            invoice.createdAt = Date(timeIntervalSince1970: row[createdAt])
            invoice.updatedAt = Date(timeIntervalSince1970: row[updatedAt])
            exportInvoices.append(invoice)
        }

        var exportExpenses: [Expense] = []
        for row in try db.prepare(expenses.order(date.desc)) {
            var expense = Expense(
                category: ExpenseCategory(rawValue: row[category]) ?? .other,
                vendor: row[expenseVendor],
                description: row[description],
                amount: row[amount],
                date: Date(timeIntervalSince1970: row[date]),
                vehicleId: row[expenseVehicleId].flatMap { UUID(uuidString: $0) },
                driverId: row[expenseDriverId].flatMap { UUID(uuidString: $0) },
                receiptNumber: row[receiptNumber],
                notes: row[notes]
            )
            expense.id = UUID(uuidString: row[id]) ?? UUID()
            expense.createdAt = Date(timeIntervalSince1970: row[createdAt])
            exportExpenses.append(expense)
        }

        var exportMaintenanceRecords: [MaintenanceRecord] = []
        for row in try db.prepare(maintenanceRecords.order(date.desc)) {
            var record = MaintenanceRecord(
                vehicleId: UUID(uuidString: row[self.vehicleId]) ?? UUID(),
                type: MaintenanceType(rawValue: row[maintenanceType]) ?? .other,
                description: row[description],
                date: Date(timeIntervalSince1970: row[date]),
                odometer: row[odometer],
                cost: row[cost],
                vendor: row[vendor],
                notes: row[notes]
            )
            record.id = UUID(uuidString: row[id]) ?? UUID()
            record.createdAt = Date(timeIntervalSince1970: row[createdAt])
            exportMaintenanceRecords.append(record)
        }

        var exportFuelLogs: [FuelLog] = []
        for row in try db.prepare(fuelLogs.order(date.desc)) {
            var log = FuelLog(
                vehicleId: UUID(uuidString: row[self.vehicleId]) ?? UUID(),
                date: Date(timeIntervalSince1970: row[date]),
                odometer: row[odometer],
                quantity: row[quantity],
                pricePerUnit: row[pricePerUnit],
                totalCost: row[totalCost],
                fuelType: FuelType(rawValue: row[fuelType]) ?? .diesel,
                location: row[location],
                notes: row[notes]
            )
            log.id = UUID(uuidString: row[id]) ?? UUID()
            log.createdAt = Date(timeIntervalSince1970: row[createdAt])
            exportFuelLogs.append(log)
        }

        var exportCertifications: [Certification] = []
        for row in try db.prepare(certifications.order(issuedDate.desc)) {
            var cert = Certification(
                driverId: UUID(uuidString: row[self.driverId]) ?? UUID(),
                type: CertificationType(rawValue: row[certificationType]) ?? .other,
                name: row[name],
                issuedDate: Date(timeIntervalSince1970: row[issuedDate]),
                expiryDate: row[expiryDate].map { Date(timeIntervalSince1970: $0) },
                documentNumber: row[documentNumber]
            )
            cert.id = UUID(uuidString: row[id]) ?? UUID()
            cert.createdAt = Date(timeIntervalSince1970: row[createdAt])
            exportCertifications.append(cert)
        }

        let settingsData = loadSettings()

        let payload: [String: Any] = [
            "vehicles": exportVehicles.map { vehicleToDict($0) },
            "drivers": exportDrivers.map { driverToDict($0) },
            "trips": exportTrips.map { tripToDict($0) },
            "customers": exportCustomers.map { customerToDict($0) },
            "invoices": exportInvoices.map { invoiceToDict($0) },
            "expenses": exportExpenses.map { expenseToDict($0) },
            "maintenanceRecords": exportMaintenanceRecords.map { maintenanceRecordToDict($0) },
            "fuelLogs": exportFuelLogs.map { fuelLogToDict($0) },
            "certifications": exportCertifications.map { certificationToDict($0) },
            "settings": settingsData
        ]

        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        return data
    }

    func importAllData(from data: Data) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DatabaseError.saveFailed("Invalid JSON format")
        }

        try transaction {
            try db.run(vehicles.delete())
            try db.run(drivers.delete())
            try db.run(trips.delete())
            try db.run(customers.delete())
            try db.run(invoices.delete())
            try db.run(invoiceTrips.delete())
            try db.run(expenses.delete())
            try db.run(maintenanceRecords.delete())
            try db.run(fuelLogs.delete())
            try db.run(certifications.delete())
            try db.run(settings.delete())

            if let vehiclesArray = json["vehicles"] as? [[String: Any]] {
                for dict in vehiclesArray {
                    try importVehicle(from: dict)
                }
            }

            if let driversArray = json["drivers"] as? [[String: Any]] {
                for dict in driversArray {
                    try importDriver(from: dict)
                }
            }

            if let tripsArray = json["trips"] as? [[String: Any]] {
                for dict in tripsArray {
                    try importTrip(from: dict)
                }
            }

            if let customersArray = json["customers"] as? [[String: Any]] {
                for dict in customersArray {
                    try importCustomer(from: dict)
                }
            }

            if let invoicesArray = json["invoices"] as? [[String: Any]] {
                for dict in invoicesArray {
                    try importInvoice(from: dict)
                }
            }

            if let expensesArray = json["expenses"] as? [[String: Any]] {
                for dict in expensesArray {
                    try importExpense(from: dict)
                }
            }

            if let maintenanceArray = json["maintenanceRecords"] as? [[String: Any]] {
                for dict in maintenanceArray {
                    try importMaintenanceRecord(from: dict)
                }
            }

            if let fuelLogsArray = json["fuelLogs"] as? [[String: Any]] {
                for dict in fuelLogsArray {
                    try importFuelLog(from: dict)
                }
            }

            if let certificationsArray = json["certifications"] as? [[String: Any]] {
                for dict in certificationsArray {
                    try importCertification(from: dict)
                }
            }

            if let settingsDict = json["settings"] as? [String: Any],
               let settingsData = try? JSONSerialization.data(withJSONObject: settingsDict),
               let settingsStr = String(data: settingsData, encoding: .utf8) {
                try db.run(self.settings.insert(
                    settingsKey <- "business_settings",
                    settingsValue <- settingsStr
                ))
            }
        }
    }

    // MARK: - Import Helpers

    private func importVehicle(from dict: [String: Any]) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        guard let vid = dict["id"] as? String else { return }
        try db.run(vehicles.insert(
            id <- vid,
            name <- dict["name"] as? String ?? "",
            type <- dict["type"] as? String ?? "",
            licensePlate <- dict["licensePlate"] as? String ?? "",
            make <- dict["make"] as? String ?? "",
            model <- dict["model"] as? String ?? "",
            year <- dict["year"] as? Int ?? 0,
            vin <- dict["vin"] as? String ?? "",
            status <- dict["status"] as? String ?? "",
            purchaseDate <- dict["purchaseDate"] as? Double,
            purchasePrice <- dict["purchasePrice"] as? Double,
            currentOdometer <- dict["currentOdometer"] as? Int ?? 0,
            fuelType <- dict["fuelType"] as? String ?? "",
            notes <- dict["notes"] as? String,
            createdAt <- dict["createdAt"] as? Double ?? Date().timeIntervalSince1970,
            updatedAt <- dict["updatedAt"] as? Double ?? Date().timeIntervalSince1970
        ))
    }

    private func importDriver(from dict: [String: Any]) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        guard let did = dict["id"] as? String else { return }
        try db.run(drivers.insert(
            id <- did,
            firstName <- dict["firstName"] as? String ?? "",
            lastName <- dict["lastName"] as? String ?? "",
            email <- dict["email"] as? String ?? "",
            phone <- dict["phone"] as? String ?? "",
            address <- dict["address"] as? String,
            emergencyContact <- dict["emergencyContact"] as? String,
            emergencyPhone <- dict["emergencyPhone"] as? String,
            licenseNumber <- dict["licenseNumber"] as? String ?? "",
            licenseState <- dict["licenseState"] as? String ?? "",
            licenseExpiry <- dict["licenseExpiry"] as? Double ?? Date().timeIntervalSince1970,
            status <- dict["status"] as? String ?? "Active",
            hireDate <- dict["hireDate"] as? Double ?? Date().timeIntervalSince1970,
            terminationDate <- dict["terminationDate"] as? Double,
            notes <- dict["notes"] as? String,
            rating <- dict["rating"] as? Double ?? 0,
            createdAt <- dict["createdAt"] as? Double ?? Date().timeIntervalSince1970,
            updatedAt <- dict["updatedAt"] as? Double ?? Date().timeIntervalSince1970
        ))
    }

    private func importTrip(from dict: [String: Any]) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        guard let tid = dict["id"] as? String else { return }
        try db.run(trips.insert(
            id <- tid,
            jobNumber <- dict["jobNumber"] as? String ?? "",
            customerId <- dict["customerId"] as? String ?? "",
            tripDriverId <- dict["driverId"] as? String,
            tripVehicleId <- dict["vehicleId"] as? String,
            tripStatus <- dict["status"] as? String ?? "Pending",
            pickupAddress <- dict["pickupAddress"] as? String ?? "",
            pickupCity <- dict["pickupCity"] as? String ?? "",
            pickupState <- dict["pickupState"] as? String ?? "",
            pickupZip <- dict["pickupZip"] as? String ?? "",
            pickupDate <- dict["pickupDate"] as? Double ?? Date().timeIntervalSince1970,
            deliveryAddress <- dict["deliveryAddress"] as? String ?? "",
            deliveryCity <- dict["deliveryCity"] as? String ?? "",
            deliveryState <- dict["deliveryState"] as? String ?? "",
            deliveryZip <- dict["deliveryZip"] as? String ?? "",
            deliveryDate <- dict["deliveryDate"] as? Double,
            distance <- dict["distance"] as? Double,
            cargoDescription <- dict["cargoDescription"] as? String,
            cargoWeight <- dict["cargoWeight"] as? Double,
            rate <- dict["rate"] as? Double ?? 0,
            fuelSurcharge <- dict["fuelSurcharge"] as? Double ?? 0,
            totalAmount <- dict["totalAmount"] as? Double ?? 0,
            notes <- dict["notes"] as? String,
            createdAt <- dict["createdAt"] as? Double ?? Date().timeIntervalSince1970,
            updatedAt <- dict["updatedAt"] as? Double ?? Date().timeIntervalSince1970
        ))
    }

    private func importCustomer(from dict: [String: Any]) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        guard let cid = dict["id"] as? String else { return }
        try db.run(customers.insert(
            id <- cid,
            companyName <- dict["companyName"] as? String ?? "",
            contactName <- dict["contactName"] as? String ?? "",
            email <- dict["email"] as? String ?? "",
            phone <- dict["phone"] as? String ?? "",
            customerType <- dict["type"] as? String ?? "Commercial",
            address <- dict["address"] as? String,
            city <- dict["city"] as? String ?? "",
            state <- dict["state"] as? String ?? "",
            zip <- dict["zip"] as? String ?? "",
            creditLimit <- dict["creditLimit"] as? Double ?? 0,
            paymentTerms <- dict["paymentTerms"] as? Int ?? 30,
            taxId <- dict["taxId"] as? String,
            notes <- dict["notes"] as? String,
            createdAt <- dict["createdAt"] as? Double ?? Date().timeIntervalSince1970,
            updatedAt <- dict["updatedAt"] as? Double ?? Date().timeIntervalSince1970
        ))
    }

    private func importInvoice(from dict: [String: Any]) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        guard let iid = dict["id"] as? String else { return }
        let tripIdStr = dict["tripIds"] as? String ?? ""
        try db.run(invoices.insert(
            id <- iid,
            invoiceNumber <- dict["invoiceNumber"] as? String ?? "",
            customerId <- dict["customerId"] as? String ?? "",
            tripIds <- tripIdStr,
            invoiceDate <- dict["invoiceDate"] as? Double ?? Date().timeIntervalSince1970,
            dueDate <- dict["dueDate"] as? Double ?? Date().timeIntervalSince1970,
            subtotal <- dict["subtotal"] as? Double ?? 0,
            tax <- dict["tax"] as? Double ?? 0,
            total <- dict["total"] as? Double ?? 0,
            invoiceStatus <- dict["status"] as? String ?? "Draft",
            paidDate <- dict["paidDate"] as? Double,
            notes <- dict["notes"] as? String,
            createdAt <- dict["createdAt"] as? Double ?? Date().timeIntervalSince1970,
            updatedAt <- dict["updatedAt"] as? Double ?? Date().timeIntervalSince1970
        ))
        let tripIds = tripIdStr.split(separator: ",").map { String($0) }
        for tid in tripIds {
            try db.run(invoiceTrips.insert(
                invoiceTripInvoiceId <- iid,
                invoiceTripTripId <- tid
            ))
        }
    }

    private func importExpense(from dict: [String: Any]) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        guard let eid = dict["id"] as? String else { return }
        try db.run(expenses.insert(
            id <- eid,
            category <- dict["category"] as? String ?? "",
            expenseVendor <- dict["vendor"] as? String,
            description <- dict["description"] as? String ?? "",
            amount <- dict["amount"] as? Double ?? 0,
            date <- dict["date"] as? Double ?? Date().timeIntervalSince1970,
            expenseVehicleId <- dict["vehicleId"] as? String,
            expenseDriverId <- dict["driverId"] as? String,
            receiptNumber <- dict["receiptNumber"] as? String,
            notes <- dict["notes"] as? String,
            createdAt <- dict["createdAt"] as? Double ?? Date().timeIntervalSince1970
        ))
    }

    private func importMaintenanceRecord(from dict: [String: Any]) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        guard let mid = dict["id"] as? String else { return }
        try db.run(maintenanceRecords.insert(
            id <- mid,
            vehicleId <- dict["vehicleId"] as? String ?? "",
            maintenanceType <- dict["type"] as? String ?? "",
            description <- dict["description"] as? String ?? "",
            date <- dict["date"] as? Double ?? Date().timeIntervalSince1970,
            odometer <- dict["odometer"] as? Int ?? 0,
            cost <- dict["cost"] as? Double ?? 0,
            vendor <- dict["vendor"] as? String,
            notes <- dict["notes"] as? String,
            createdAt <- dict["createdAt"] as? Double ?? Date().timeIntervalSince1970
        ))
    }

    private func importFuelLog(from dict: [String: Any]) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        guard let fid = dict["id"] as? String else { return }
        try db.run(fuelLogs.insert(
            id <- fid,
            vehicleId <- dict["vehicleId"] as? String ?? "",
            date <- dict["date"] as? Double ?? Date().timeIntervalSince1970,
            odometer <- dict["odometer"] as? Int ?? 0,
            quantity <- dict["quantity"] as? Double ?? 0,
            pricePerUnit <- dict["pricePerUnit"] as? Double ?? 0,
            totalCost <- dict["totalCost"] as? Double ?? 0,
            fuelType <- dict["fuelType"] as? String ?? "Diesel",
            location <- dict["location"] as? String,
            notes <- dict["notes"] as? String,
            createdAt <- dict["createdAt"] as? Double ?? Date().timeIntervalSince1970
        ))
    }

    private func importCertification(from dict: [String: Any]) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        guard let cid = dict["id"] as? String else { return }
        try db.run(certifications.insert(
            id <- cid,
            driverId <- dict["driverId"] as? String ?? "",
            certificationType <- dict["type"] as? String ?? "",
            name <- dict["name"] as? String ?? "",
            issuedDate <- dict["issuedDate"] as? Double ?? Date().timeIntervalSince1970,
            expiryDate <- dict["expiryDate"] as? Double,
            documentNumber <- dict["documentNumber"] as? String,
            createdAt <- dict["createdAt"] as? Double ?? Date().timeIntervalSince1970
        ))
    }

    // MARK: - Export Helpers

    private func vehicleToDict(_ v: Vehicle) -> [String: Any] {
        var d: [String: Any] = [
            "id": v.id.uuidString,
            "name": v.name,
            "type": v.type.rawValue,
            "licensePlate": v.licensePlate,
            "make": v.make,
            "model": v.model,
            "year": v.year,
            "vin": v.vin,
            "status": v.status.rawValue,
            "currentOdometer": v.currentOdometer,
            "fuelType": v.fuelType.rawValue,
            "createdAt": v.createdAt.timeIntervalSince1970,
            "updatedAt": v.updatedAt.timeIntervalSince1970
        ]
        if let pd = v.purchaseDate { d["purchaseDate"] = pd.timeIntervalSince1970 }
        if let pp = v.purchasePrice { d["purchasePrice"] = pp }
        if let n = v.notes { d["notes"] = n }
        return d
    }

    private func driverToDict(_ d: Driver) -> [String: Any] {
        var dict: [String: Any] = [
            "id": d.id.uuidString,
            "firstName": d.firstName,
            "lastName": d.lastName,
            "email": d.email,
            "phone": d.phone,
            "licenseNumber": d.licenseNumber,
            "licenseState": d.licenseState,
            "licenseExpiry": d.licenseExpiry.timeIntervalSince1970,
            "status": d.status.rawValue,
            "hireDate": d.hireDate.timeIntervalSince1970,
            "rating": d.rating,
            "createdAt": d.createdAt.timeIntervalSince1970,
            "updatedAt": d.updatedAt.timeIntervalSince1970
        ]
        if let a = d.address { dict["address"] = a }
        if let ec = d.emergencyContact { dict["emergencyContact"] = ec }
        if let ep = d.emergencyPhone { dict["emergencyPhone"] = ep }
        if let td = d.terminationDate { dict["terminationDate"] = td.timeIntervalSince1970 }
        if let n = d.notes { dict["notes"] = n }
        return dict
    }

    private func tripToDict(_ t: Trip) -> [String: Any] {
        var d: [String: Any] = [
            "id": t.id.uuidString,
            "jobNumber": t.jobNumber,
            "customerId": t.customerId.uuidString,
            "status": t.status.rawValue,
            "pickupAddress": t.pickupAddress,
            "pickupCity": t.pickupCity,
            "pickupState": t.pickupState,
            "pickupZip": t.pickupZip,
            "pickupDate": t.pickupDate.timeIntervalSince1970,
            "deliveryAddress": t.deliveryAddress,
            "deliveryCity": t.deliveryCity,
            "deliveryState": t.deliveryState,
            "deliveryZip": t.deliveryZip,
            "rate": t.rate,
            "fuelSurcharge": t.fuelSurcharge,
            "totalAmount": t.totalAmount,
            "createdAt": t.createdAt.timeIntervalSince1970,
            "updatedAt": t.updatedAt.timeIntervalSince1970
        ]
        if let did = t.driverId { d["driverId"] = did.uuidString }
        if let vid = t.vehicleId { d["vehicleId"] = vid.uuidString }
        if let dd = t.deliveryDate { d["deliveryDate"] = dd.timeIntervalSince1970 }
        if let dist = t.distance { d["distance"] = dist }
        if let cd = t.cargoDescription { d["cargoDescription"] = cd }
        if let cw = t.cargoWeight { d["cargoWeight"] = cw }
        if let n = t.notes { d["notes"] = n }
        return d
    }

    private func customerToDict(_ c: Customer) -> [String: Any] {
        var d: [String: Any] = [
            "id": c.id.uuidString,
            "companyName": c.companyName,
            "contactName": c.contactName,
            "email": c.email,
            "phone": c.phone,
            "type": c.type.rawValue,
            "city": c.city,
            "state": c.state,
            "zip": c.zip,
            "creditLimit": c.creditLimit,
            "paymentTerms": c.paymentTerms,
            "createdAt": c.createdAt.timeIntervalSince1970,
            "updatedAt": c.updatedAt.timeIntervalSince1970
        ]
        d["address"] = c.address
        if let tid = c.taxId { d["taxId"] = tid }
        if let n = c.notes { d["notes"] = n }
        return d
    }

    private func invoiceToDict(_ inv: Invoice) -> [String: Any] {
        var d: [String: Any] = [
            "id": inv.id.uuidString,
            "invoiceNumber": inv.invoiceNumber,
            "customerId": inv.customerId.uuidString,
            "tripIds": inv.tripIds.map { $0.uuidString }.joined(separator: ","),
            "invoiceDate": inv.invoiceDate.timeIntervalSince1970,
            "dueDate": inv.dueDate.timeIntervalSince1970,
            "subtotal": inv.subtotal,
            "tax": inv.tax,
            "total": inv.total,
            "status": inv.status.rawValue,
            "createdAt": inv.createdAt.timeIntervalSince1970,
            "updatedAt": inv.updatedAt.timeIntervalSince1970
        ]
        if let pd = inv.paidDate { d["paidDate"] = pd.timeIntervalSince1970 }
        if let n = inv.notes { d["notes"] = n }
        return d
    }

    private func expenseToDict(_ e: Expense) -> [String: Any] {
        var d: [String: Any] = [
            "id": e.id.uuidString,
            "category": e.category.rawValue,
            "description": e.description,
            "amount": e.amount,
            "date": e.date.timeIntervalSince1970,
            "createdAt": e.createdAt.timeIntervalSince1970
        ]
        if let v = e.vendor { d["vendor"] = v }
        if let vid = e.vehicleId { d["vehicleId"] = vid.uuidString }
        if let did = e.driverId { d["driverId"] = did.uuidString }
        if let rn = e.receiptNumber { d["receiptNumber"] = rn }
        if let n = e.notes { d["notes"] = n }
        return d
    }

    private func maintenanceRecordToDict(_ r: MaintenanceRecord) -> [String: Any] {
        var d: [String: Any] = [
            "id": r.id.uuidString,
            "vehicleId": r.vehicleId.uuidString,
            "type": r.type.rawValue,
            "description": r.description,
            "date": r.date.timeIntervalSince1970,
            "odometer": r.odometer,
            "cost": r.cost,
            "createdAt": r.createdAt.timeIntervalSince1970
        ]
        if let v = r.vendor { d["vendor"] = v }
        if let n = r.notes { d["notes"] = n }
        return d
    }

    private func fuelLogToDict(_ l: FuelLog) -> [String: Any] {
        var d: [String: Any] = [
            "id": l.id.uuidString,
            "vehicleId": l.vehicleId.uuidString,
            "date": l.date.timeIntervalSince1970,
            "odometer": l.odometer,
            "quantity": l.quantity,
            "pricePerUnit": l.pricePerUnit,
            "totalCost": l.totalCost,
            "fuelType": l.fuelType.rawValue,
            "createdAt": l.createdAt.timeIntervalSince1970
        ]
        if let loc = l.location { d["location"] = loc }
        if let n = l.notes { d["notes"] = n }
        return d
    }

    private func certificationToDict(_ c: Certification) -> [String: Any] {
        var d: [String: Any] = [
            "id": c.id.uuidString,
            "driverId": c.driverId.uuidString,
            "type": c.type.rawValue,
            "name": c.name,
            "issuedDate": c.issuedDate.timeIntervalSince1970,
            "createdAt": c.createdAt.timeIntervalSince1970
        ]
        if let ed = c.expiryDate { d["expiryDate"] = ed.timeIntervalSince1970 }
        if let dn = c.documentNumber { d["documentNumber"] = dn }
        return d
    }
}
