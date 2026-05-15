import Foundation
import SQLite

typealias SQLExpression = SQLite.Expression

@MainActor
class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: Connection?
    private let dbPath: String

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

    private init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("TransFleetPro", isDirectory: true)

        try? fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)

        dbPath = appFolder.appendingPathComponent("transfleet.sqlite3").path
    }

    func initializeDatabase() {
        do {
            db = try Connection(dbPath)
            createTables()

        } catch {
            print("Database connection failed: \(error)")
        }
    }

    private func createTables() {
        guard let db = db else { return }

        do {
            // Vehicles table
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

            // Maintenance records table
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

            // Fuel logs table
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

            // Drivers table
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

            // Certifications table
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

            // Trips table
            try db.run(trips.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(jobNumber, unique: true)
                t.column(customerId)
                t.column(driverId)
                t.column(vehicleId)
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

            // Trip updates table
            try db.run(tripUpdates.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(tripId)
                t.column(tripStatus)
                t.column(date)
                t.column(location)
                t.column(notes)
            })

            // Customers table
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

            // Invoices table
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

            // Expenses table
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

            // Settings table
            try db.run(settings.create(ifNotExists: true) { t in
                t.column(settingsKey, primaryKey: true)
                t.column(settingsValue)
            })

        } catch {
            print("Table creation failed: \(error)")
        }
    }

    // MARK: - Vehicle CRUD
    func saveVehicle(_ vehicle: Vehicle) -> Bool {
        guard let db = db else { return false }

        do {
            let insert = vehicles.insert(or: .replace,
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
            )
            try db.run(insert)
            return true
        } catch {
            print("Save vehicle failed: \(error)")
            return false
        }
    }

    func getAllVehicles() -> [Vehicle] {
        guard let db = db else { return [] }

        var result: [Vehicle] = []
        do {
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
        } catch {
            print("Get vehicles failed: \(error)")
        }
        return result
    }

    func deleteVehicle(_ vehicle: Vehicle) -> Bool {
        guard let db = db else { return false }

        do {
            let vehicleRow = vehicles.filter(id == vehicle.id.uuidString)
            try db.run(vehicleRow.delete())
            return true
        } catch {
            print("Delete vehicle failed: \(error)")
            return false
        }
    }

    // MARK: - Driver CRUD
    func saveDriver(_ driver: Driver) -> Bool {
        guard let db = db else { return false }

        do {
            let insert = drivers.insert(or: .replace,
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
            )
            try db.run(insert)
            return true
        } catch {
            print("Save driver failed: \(error)")
            return false
        }
    }

    func getAllDrivers() -> [Driver] {
        guard let db = db else { return [] }

        var result: [Driver] = []
        do {
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
        } catch {
            print("Get drivers failed: \(error)")
        }
        return result
    }

    func deleteDriver(_ driver: Driver) -> Bool {
        guard let db = db else { return false }

        do {
            let driverRow = drivers.filter(id == driver.id.uuidString)
            try db.run(driverRow.delete())
            return true
        } catch {
            print("Delete driver failed: \(error)")
            return false
        }
    }

    // MARK: - Trip CRUD
    func saveTrip(_ trip: Trip) -> Bool {
        guard let db = db else { return false }

        do {
            let insert = trips.insert(or: .replace,
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
                rate <- trip.rate,
                fuelSurcharge <- trip.fuelSurcharge,
                totalAmount <- trip.totalAmount,
                notes <- trip.notes,
                createdAt <- trip.createdAt.timeIntervalSince1970,
                updatedAt <- Date().timeIntervalSince1970
            )
            try db.run(insert)
            return true
        } catch {
            print("Save trip failed: \(error)")
            return false
        }
    }

    func getAllTrips() -> [Trip] {
        guard let db = db else { return [] }

        var result: [Trip] = []
        do {
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
        } catch {
            print("Get trips failed: \(error)")
        }
        return result
    }

    func deleteTrip(_ trip: Trip) -> Bool {
        guard let db = db else { return false }

        do {
            let tripRow = trips.filter(id == trip.id.uuidString)
            try db.run(tripRow.delete())
            return true
        } catch {
            print("Delete trip failed: \(error)")
            return false
        }
    }

    // MARK: - Customer CRUD
    func saveCustomer(_ customer: Customer) -> Bool {
        guard let db = db else { return false }

        do {
            let insert = customers.insert(or: .replace,
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
            )
            try db.run(insert)
            return true
        } catch {
            print("Save customer failed: \(error)")
            return false
        }
    }

    func getAllCustomers() -> [Customer] {
        guard let db = db else { return [] }

        var result: [Customer] = []
        do {
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
        } catch {
            print("Get customers failed: \(error)")
        }
        return result
    }

    func deleteCustomer(_ customer: Customer) -> Bool {
        guard let db = db else { return false }

        do {
            let customerRow = customers.filter(id == customer.id.uuidString)
            try db.run(customerRow.delete())
            return true
        } catch {
            print("Delete customer failed: \(error)")
            return false
        }
    }

    // MARK: - Invoice CRUD
    func saveInvoice(_ invoice: Invoice) -> Bool {
        guard let db = db else { return false }

        do {
            let insert = invoices.insert(or: .replace,
                id <- invoice.id.uuidString,
                invoiceNumber <- invoice.invoiceNumber,
                customerId <- invoice.customerId.uuidString,
                tripIds <- invoice.tripIds.map { $0.uuidString }.joined(separator: ","),
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
            )
            try db.run(insert)
            return true
        } catch {
            print("Save invoice failed: \(error)")
            return false
        }
    }

    func getAllInvoices() -> [Invoice] {
        guard let db = db else { return [] }

        var result: [Invoice] = []
        do {
            for row in try db.prepare(invoices.order(invoiceDate.desc)) {
                var invoice = Invoice(
                    invoiceNumber: row[invoiceNumber],
                    customerId: UUID(uuidString: row[customerId]) ?? UUID(),
                    tripIds: row[tripIds].split(separator: ",").compactMap { UUID(uuidString: String($0)) },
                    invoiceDate: Date(timeIntervalSince1970: row[invoiceDate]),
                    dueDate: Date(timeIntervalSince1970: row[dueDate]),
                    subtotal: row[subtotal],
                    tax: row[tax],
                    total: row[total],
                    status: InvoiceStatus(rawValue: row[invoiceStatus]) ?? .draft,
                    paidDate: row[paidDate].map { Date(timeIntervalSince1970: $0) },
                    notes: row[notes]
                )
                invoice.id = UUID(uuidString: row[id]) ?? UUID()
                invoice.createdAt = Date(timeIntervalSince1970: row[createdAt])
                invoice.updatedAt = Date(timeIntervalSince1970: row[updatedAt])
                result.append(invoice)
            }
        } catch {
            print("Get invoices failed: \(error)")
        }
        return result
    }

    func deleteInvoice(_ invoice: Invoice) -> Bool {
        guard let db = db else { return false }

        do {
            let invoiceRow = invoices.filter(id == invoice.id.uuidString)
            try db.run(invoiceRow.delete())
            return true
        } catch {
            print("Delete invoice failed: \(error)")
            return false
        }
    }

    // MARK: - Expense CRUD
    func saveExpense(_ expense: Expense) -> Bool {
        guard let db = db else { return false }

        do {
            let insert = expenses.insert(or: .replace,
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
            )
            try db.run(insert)
            return true
        } catch {
            print("Save expense failed: \(error)")
            return false
        }
    }

    func getAllExpenses() -> [Expense] {
        guard let db = db else { return [] }

        var result: [Expense] = []
        do {
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
        } catch {
            print("Get expenses failed: \(error)")
        }
        return result
    }

    func deleteExpense(_ expense: Expense) -> Bool {
        guard let db = db else { return false }

        do {
            let expenseRow = expenses.filter(id == expense.id.uuidString)
            try db.run(expenseRow.delete())
            return true
        } catch {
            print("Delete expense failed: \(error)")
            return false
        }
    }

    // MARK: - Dashboard Stats
    func getDashboardStats() -> DashboardStats {
        let allVehicles = getAllVehicles()
        let allDrivers = getAllDrivers()
        let allTrips = getAllTrips()
        let allCustomers = getAllCustomers()
        let allExpenses = getAllExpenses()

        let activeVehicles = allVehicles.filter { $0.status != .retired }
        let activeDrivers = allDrivers.filter { $0.status == .active }

        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!

        let monthlyTrips = allTrips.filter { $0.pickupDate >= startOfMonth && $0.status == .completed }
        let monthlyRevenue = monthlyTrips.reduce(0) { $0 + $1.totalAmount }

        let monthlyExpenses = allExpenses.filter { $0.date >= startOfMonth }.reduce(0) { $0 + $1.amount }

        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let todayTrips = allTrips.filter { $0.pickupDate >= today && $0.pickupDate < tomorrow }
        let pendingTrips = allTrips.filter { $0.status == .pending }

        let inUseVehicles = allVehicles.filter { $0.status == .inUse }.count
        let fleetUtilization = activeVehicles.isEmpty ? 0 : Double(inUseVehicles) / Double(activeVehicles.count) * 100

        let thirtyDaysFromNow = Date().addingTimeInterval(30*24*60*60)
        let expiringLicenses = allDrivers.filter { $0.licenseExpiry <= thirtyDaysFromNow && $0.status == .active }.count

        return DashboardStats(
            totalVehicles: allVehicles.count,
            activeVehicles: activeVehicles.count,
            totalDrivers: allDrivers.count,
            activeDrivers: activeDrivers.count,
            todayTrips: todayTrips.count,
            pendingTrips: pendingTrips.count,
            monthlyRevenue: monthlyRevenue,
            monthlyExpenses: monthlyExpenses,
            fleetUtilization: fleetUtilization,
            overdueMaintenance: 0,
            expiringLicenses: expiringLicenses,
            activeCustomers: allCustomers.count
        )
    }

    // MARK: - Reports Data
    func getRevenueByMonth(months: Int = 12) -> [(Date, Double)] {
        let allTrips = getAllTrips().filter { $0.status == .completed || $0.status == .delivered }
        let calendar = Calendar.current

        var result: [(Date, Double)] = []
        for i in 0..<months {
            let startOfMonth = calendar.date(byAdding: .month, value: -i, to: Date())!
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

            let monthRevenue = allTrips
                .filter { $0.pickupDate >= startOfMonth && $0.pickupDate < endOfMonth }
                .reduce(0) { $0 + $1.totalAmount }

            result.append((startOfMonth, monthRevenue))
        }

        return result.reversed()
    }

    func getExpensesByCategory() -> [(ExpenseCategory, Double)] {
        let allExpenses = getAllExpenses()
        var result: [ExpenseCategory: Double] = [:]

        for expense in allExpenses {
            result[expense.category, default: 0] += expense.amount
        }

        return result.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }

    func getFleetUtilization() -> [(VehicleStatus, Int)] {
        let allVehicles = getAllVehicles()
        var result: [VehicleStatus: Int] = [:]

        for vehicle in allVehicles {
            result[vehicle.status, default: 0] += 1
        }

        return result.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }

    func getTripsByStatus() -> [(TripStatus, Int)] {
        let allTrips = getAllTrips()
        var result: [TripStatus: Int] = [:]

        for trip in allTrips {
            result[trip.status, default: 0] += 1
        }

        return result.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }
}