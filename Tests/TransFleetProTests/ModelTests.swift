import XCTest
@testable import TransFleetProApp

final class ModelTests: XCTestCase {

    // MARK: - Vehicle Tests
    func testVehicleDisplayName() {
        let vehicle = Vehicle(name: "Test", type: .truck, licensePlate: "ABC123", make: "Ford", model: "F-150", year: 2024, vin: "12345", status: .available, currentOdometer: 1000, fuelType: .gasoline)
        XCTAssertEqual(vehicle.displayName, "2024 Ford F-150")
    }

    func testVehicleDefaults() {
        let vehicle = Vehicle(name: "Test", type: .truck, licensePlate: "ABC", make: "Ford", model: "F-150", year: 2024, vin: "12345", status: .available, currentOdometer: 0, fuelType: .diesel)
        XCTAssertNotNil(vehicle.id)
        XCTAssertNotNil(vehicle.createdAt)
        XCTAssertNotNil(vehicle.updatedAt)
    }

    // MARK: - Driver Tests
    func testDriverFullName() {
        let driver = Driver(firstName: "John", lastName: "Doe", email: "john@test.com", phone: "555-0100", licenseNumber: "DL123", licenseState: "CA", licenseExpiry: Date(), status: .active, hireDate: Date(), rating: 4.5)
        XCTAssertEqual(driver.fullName, "John Doe")
    }

    // MARK: - Trip Tests
    func testTripJobNumberFormat() {
        let jobNumber = Trip.generateJobNumber()
        XCTAssertTrue(jobNumber.hasPrefix("TF-"))
        XCTAssertTrue(jobNumber.contains("-"))
        XCTAssertEqual(jobNumber.count, 20)
    }

    // MARK: - Invoice Tests
    func testInvoiceNumberFormat() {
        let invoiceNumber = Invoice.generateInvoiceNumber()
        XCTAssertTrue(invoiceNumber.hasPrefix("INV-"))
    }

    // MARK: - BusinessSettings Tests
    func testDefaultSettings() {
        let settings = BusinessSettings.default
        XCTAssertEqual(settings.currency, "USD")
        XCTAssertEqual(settings.distanceUnit, "miles")
        XCTAssertEqual(settings.taxRate, 0.0)
    }

    // MARK: - DashboardStats Tests
    func testDashboardStatsInitialization() {
        let stats = DashboardStats(totalVehicles: 10, activeVehicles: 8, totalDrivers: 5, activeDrivers: 4, todayTrips: 3, pendingTrips: 2, monthlyRevenue: 50000, monthlyExpenses: 30000, fleetUtilization: 75.0, overdueMaintenance: 1, expiringLicenses: 2, activeCustomers: 15)
        XCTAssertEqual(stats.totalVehicles, 10)
        XCTAssertEqual(stats.monthlyRevenue, 50000)
    }

    // MARK: - VehicleStatus Color Tests
    func testVehicleStatusColors() {
        XCTAssertEqual(VehicleStatus.available.color, .green)
        XCTAssertEqual(VehicleStatus.inUse.color, .blue)
        XCTAssertEqual(VehicleStatus.maintenance.color, .orange)
        XCTAssertEqual(VehicleStatus.retired.color, .gray)
    }

    // MARK: - DriverStatus Color Tests
    func testDriverStatusColors() {
        XCTAssertEqual(DriverStatus.active.color, .green)
        XCTAssertEqual(DriverStatus.onLeave.color, .orange)
        XCTAssertEqual(DriverStatus.suspended.color, .red)
        XCTAssertEqual(DriverStatus.terminated.color, .gray)
    }

    // MARK: - InvoiceStatus Color Tests
    func testInvoiceStatusColors() {
        XCTAssertEqual(InvoiceStatus.draft.color, .gray)
        XCTAssertEqual(InvoiceStatus.sent.color, .blue)
        XCTAssertEqual(InvoiceStatus.paid.color, .green)
        XCTAssertEqual(InvoiceStatus.overdue.color, .red)
    }

    // MARK: - TripStatus Color Tests
    func testTripStatusColors() {
        XCTAssertEqual(TripStatus.pending.color, .gray)
        XCTAssertEqual(TripStatus.inTransit.color, .orange)
        XCTAssertEqual(TripStatus.completed.color, .green)
        XCTAssertEqual(TripStatus.cancelled.color, .red)
    }

    // MARK: - Codable Tests
    func testVehicleCodable() throws {
        let vehicle = Vehicle(name: "Test", type: .truck, licensePlate: "ABC", make: "Ford", model: "F-150", year: 2024, vin: "12345", status: .available, currentOdometer: 1000, fuelType: .diesel)
        let data = try JSONEncoder().encode(vehicle)
        let decoded = try JSONDecoder().decode(Vehicle.self, from: data)
        XCTAssertEqual(vehicle.name, decoded.name)
        XCTAssertEqual(vehicle.make, decoded.make)
        XCTAssertEqual(vehicle.id, decoded.id)
    }

    func testDriverCodable() throws {
        let driver = Driver(firstName: "John", lastName: "Doe", email: "john@test.com", phone: "555-0100", licenseNumber: "DL123", licenseState: "CA", licenseExpiry: Date(), status: .active, hireDate: Date(), rating: 4.5)
        let data = try JSONEncoder().encode(driver)
        let decoded = try JSONDecoder().decode(Driver.self, from: data)
        XCTAssertEqual(driver.firstName, decoded.firstName)
        XCTAssertEqual(driver.fullName, decoded.fullName)
    }

    func testTripCodable() throws {
        let trip = Trip(jobNumber: "TF-20260101-12345678", customerId: UUID(), status: .pending, pickupAddress: "123 Main St", pickupCity: "LA", pickupState: "CA", pickupZip: "90001", pickupDate: Date(), deliveryAddress: "456 Oak Ave", deliveryCity: "SF", deliveryState: "CA", deliveryZip: "94102", rate: 100, fuelSurcharge: 10, totalAmount: 110)
        let data = try JSONEncoder().encode(trip)
        let decoded = try JSONDecoder().decode(Trip.self, from: data)
        XCTAssertEqual(trip.jobNumber, decoded.jobNumber)
        XCTAssertEqual(trip.rate, decoded.rate)
    }

    func testInvoiceCodable() throws {
        let invoice = Invoice(invoiceNumber: "INV-202601-12345678", customerId: UUID(), tripIds: [], invoiceDate: Date(), dueDate: Date(), subtotal: 100, tax: 10, total: 110, status: .draft)
        let data = try JSONEncoder().encode(invoice)
        let decoded = try JSONDecoder().decode(Invoice.self, from: data)
        XCTAssertEqual(invoice.invoiceNumber, decoded.invoiceNumber)
        XCTAssertEqual(invoice.total, decoded.total)
    }

    func testBusinessSettingsCodable() throws {
        let settings = BusinessSettings(companyName: "Test Co", address: "123 St", city: "LA", state: "CA", zip: "90001", phone: "555-0100", email: "test@co.com", taxRate: 8.5, currency: "USD", distanceUnit: "miles", invoicePrefix: "INV")
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(BusinessSettings.self, from: data)
        XCTAssertEqual(settings.companyName, decoded.companyName)
        XCTAssertEqual(settings.taxRate, decoded.taxRate)
    }

    func testExpenseCodable() throws {
        let expense = Expense(category: .fuel, vendor: "Shell", description: "Gas fillup", amount: 75.50, date: Date(), notes: nil)
        let data = try JSONEncoder().encode(expense)
        let decoded = try JSONDecoder().decode(Expense.self, from: data)
        XCTAssertEqual(expense.category, decoded.category)
        XCTAssertEqual(expense.amount, decoded.amount)
    }
}
