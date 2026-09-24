import XCTest
@testable import TransFleetProApp

@MainActor
final class DatabaseManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        DatabaseManager.shared.initializeDatabase()
    }

    func testSeedAndRetrieveDemoData() throws {
        try DatabaseManager.shared.seedDemoData()

        let vehicles = try DatabaseManager.shared.getAllVehicles()
        XCTAssertFalse(vehicles.isEmpty, "Vehicles should be populated after seed")

        let drivers = try DatabaseManager.shared.getAllDrivers()
        XCTAssertFalse(drivers.isEmpty, "Drivers should be populated after seed")

        let trips = try DatabaseManager.shared.getAllTrips()
        XCTAssertFalse(trips.isEmpty, "Trips should be populated after seed")

        let customers = try DatabaseManager.shared.getAllCustomers()
        XCTAssertFalse(customers.isEmpty, "Customers should be populated after seed")

        let invoices = try DatabaseManager.shared.getAllInvoices()
        XCTAssertFalse(invoices.isEmpty, "Invoices should be populated after seed")

        let expenses = try DatabaseManager.shared.getAllExpenses()
        XCTAssertFalse(expenses.isEmpty, "Expenses should be populated after seed")
    }

    func testVehicleCRUD() throws {
        let newVehicle = Vehicle(
            name: "Test Truck #99",
            type: .truck,
            licensePlate: "TEST-999",
            make: "Freightliner",
            model: "Cascadia",
            year: 2025,
            vin: "TESTVIN1234567890",
            status: .available,
            currentOdometer: 5000,
            fuelType: .diesel
        )

        try DatabaseManager.shared.saveVehicle(newVehicle)
        let fetched = try DatabaseManager.shared.getAllVehicles().first { $0.id == newVehicle.id }
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.name, "Test Truck #99")

        var updated = newVehicle
        updated.currentOdometer = 12000
        try DatabaseManager.shared.saveVehicle(updated)

        let reFetched = try DatabaseManager.shared.getAllVehicles().first { $0.id == newVehicle.id }
        XCTAssertEqual(reFetched?.currentOdometer, 12000)

        try DatabaseManager.shared.deleteVehicle(updated)
        let afterDelete = try DatabaseManager.shared.getAllVehicles().first { $0.id == newVehicle.id }
        XCTAssertNil(afterDelete)
    }

    func testDriverCRUD() throws {
        let newDriver = Driver(
            firstName: "Alex",
            lastName: "Smith",
            email: "asmith@test.com",
            phone: "555-0999",
            licenseNumber: "CDL-TEST-123",
            licenseState: "TX",
            licenseExpiry: Date().addingTimeInterval(180 * 86400),
            status: .active,
            hireDate: Date(),
            rating: 4.8
        )

        try DatabaseManager.shared.saveDriver(newDriver)
        let fetched = try DatabaseManager.shared.getAllDrivers().first { $0.id == newDriver.id }
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.fullName, "Alex Smith")

        try DatabaseManager.shared.deleteDriver(newDriver)
        let afterDelete = try DatabaseManager.shared.getAllDrivers().first { $0.id == newDriver.id }
        XCTAssertNil(afterDelete)
    }

    func testTripVehicleStatusAutoSync() throws {
        let customer = Customer(companyName: "Sync Test Customer", contactName: "Contact", email: "c@test.com", phone: "555-1111", type: .commercial, address: "Addr", city: "City", state: "TX", zip: "75000", creditLimit: 10000, paymentTerms: 30)
        try DatabaseManager.shared.saveCustomer(customer)

        let vehicle = Vehicle(name: "Sync Test Vehicle", type: .truck, licensePlate: "SYNC-01", make: "Volvo", model: "VNL", year: 2024, vin: "SYNCVIN123", status: .available, currentOdometer: 1000, fuelType: .diesel)
        try DatabaseManager.shared.saveVehicle(vehicle)

        var trip = Trip(jobNumber: Trip.generateJobNumber(), customerId: customer.id, driverId: nil, vehicleId: vehicle.id, status: .inTransit, pickupAddress: "P", pickupCity: "PC", pickupState: "TX", pickupZip: "75000", pickupDate: Date(), deliveryAddress: "D", deliveryCity: "DC", deliveryState: "TX", deliveryZip: "75001", rate: 500, fuelSurcharge: 50, totalAmount: 550)
        try DatabaseManager.shared.saveTrip(trip)

        // Vehicle should now be inUse
        let vehicleAfterInTransit = try DatabaseManager.shared.getAllVehicles().first { $0.id == vehicle.id }
        XCTAssertEqual(vehicleAfterInTransit?.status, .inUse, "Vehicle status should be updated to inUse when trip is inTransit")

        // Transition trip to completed
        trip.status = .completed
        try DatabaseManager.shared.saveTrip(trip)

        let vehicleAfterCompleted = try DatabaseManager.shared.getAllVehicles().first { $0.id == vehicle.id }
        XCTAssertEqual(vehicleAfterCompleted?.status, .available, "Vehicle status should revert to available when trip completes")

        // Cleanup
        try DatabaseManager.shared.deleteTrip(trip)
        try DatabaseManager.shared.deleteVehicle(vehicle)
        try DatabaseManager.shared.deleteCustomer(customer)
    }

    func testDeleteTripInvoiceCleanup() throws {
        let customer = Customer(companyName: "Cleanup Test Customer", contactName: "Contact", email: "clean@test.com", phone: "555-2222", type: .commercial, address: "Addr", city: "City", state: "TX", zip: "75000", creditLimit: 10000, paymentTerms: 30)
        try DatabaseManager.shared.saveCustomer(customer)

        let trip = Trip(jobNumber: Trip.generateJobNumber(), customerId: customer.id, status: .completed, pickupAddress: "P", pickupCity: "PC", pickupState: "TX", pickupZip: "75000", pickupDate: Date(), deliveryAddress: "D", deliveryCity: "DC", deliveryState: "TX", deliveryZip: "75001", rate: 1000, fuelSurcharge: 100, totalAmount: 1100)
        try DatabaseManager.shared.saveTrip(trip)

        let invoice = Invoice(invoiceNumber: Invoice.generateInvoiceNumber(), customerId: customer.id, tripIds: [trip.id], invoiceDate: Date(), dueDate: Date().addingTimeInterval(30*86400), subtotal: 1000, tax: 80, total: 1080, status: .draft)
        try DatabaseManager.shared.saveInvoice(invoice)

        // Delete trip
        try DatabaseManager.shared.deleteTrip(trip)

        // Verify trip removed from invoice
        let invoices = try DatabaseManager.shared.getAllInvoices()
        if let inv = invoices.first(where: { $0.id == invoice.id }) {
            XCTAssertFalse(inv.tripIds.contains(trip.id), "Deleted trip ID should no longer be present in invoice tripIds")
        }

        // Cleanup
        try DatabaseManager.shared.deleteInvoice(invoice)
        try DatabaseManager.shared.deleteCustomer(customer)
    }

    func testDashboardStatsAndReportsAggregates() throws {
        try DatabaseManager.shared.seedDemoData()

        let stats = try DatabaseManager.shared.getDashboardStats()
        XCTAssertGreaterThan(stats.totalVehicles, 0)
        XCTAssertGreaterThan(stats.totalDrivers, 0)
        XCTAssertGreaterThanOrEqual(stats.monthlyRevenue, 0)

        let revenueByMonth = try DatabaseManager.shared.getRevenueByMonth(months: 6)
        XCTAssertEqual(revenueByMonth.count, 6, "getRevenueByMonth should return exactly 6 months of data")

        let expensesCat = try DatabaseManager.shared.getExpensesByCategory()
        XCTAssertFalse(expensesCat.isEmpty)

        let fleetUtil = try DatabaseManager.shared.getFleetUtilization()
        XCTAssertFalse(fleetUtil.isEmpty)

        let tripsByStatus = try DatabaseManager.shared.getTripsByStatus()
        XCTAssertFalse(tripsByStatus.isEmpty)
    }
}
