import Foundation
import SwiftUI

// MARK: - Dashboard ViewModel
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var stats: DashboardStats = DashboardStats(
        totalVehicles: 0, activeVehicles: 0, totalDrivers: 0, activeDrivers: 0,
        todayTrips: 0, pendingTrips: 0, monthlyRevenue: 0, monthlyExpenses: 0,
        fleetUtilization: 0, overdueMaintenance: 0, expiringLicenses: 0, activeCustomers: 0
    )
    @Published var recentTrips: [Trip] = []
    @Published var revenueData: [(Date, Double)] = []
    @Published var fleetUtilizationData: [(VehicleStatus, Int)] = []
    @Published var isLoading = false

    func loadData() {
        isLoading = true
        stats = DatabaseManager.shared.getDashboardStats()
        recentTrips = Array(DatabaseManager.shared.getAllTrips().prefix(10))
        revenueData = DatabaseManager.shared.getRevenueByMonth(months: 6)
        fleetUtilizationData = DatabaseManager.shared.getFleetUtilization()
        isLoading = false
    }

    var profitMargin: Double {
        guard stats.monthlyRevenue > 0 else { return 0 }
        return ((stats.monthlyRevenue - stats.monthlyExpenses) / stats.monthlyRevenue) * 100
    }
}

// MARK: - Fleet ViewModel
@MainActor
class FleetViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var selectedVehicle: Vehicle?
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var filterStatus: VehicleStatus?

    var filteredVehicles: [Vehicle] {
        var result = vehicles

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.licensePlate.localizedCaseInsensitiveContains(searchText) ||
                $0.make.localizedCaseInsensitiveContains(searchText) ||
                $0.model.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }

        return result
    }

    func loadData() {
        isLoading = true
        vehicles = DatabaseManager.shared.getAllVehicles()
        isLoading = false
    }

    func deleteVehicle(_ vehicle: Vehicle) {
        _ = DatabaseManager.shared.deleteVehicle(vehicle)
        vehicles.removeAll { $0.id == vehicle.id }
    }

    func saveVehicle(_ vehicle: Vehicle) {
        _ = DatabaseManager.shared.saveVehicle(vehicle)
        loadData()
    }
}

// MARK: - Driver ViewModel
@MainActor
class DriverViewModel: ObservableObject {
    @Published var drivers: [Driver] = []
    @Published var selectedDriver: Driver?
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var filterStatus: DriverStatus?

    var filteredDrivers: [Driver] {
        var result = drivers

        if !searchText.isEmpty {
            result = result.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText) ||
                $0.phone.localizedCaseInsensitiveContains(searchText) ||
                $0.licenseNumber.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }

        return result
    }

    func loadData() {
        isLoading = true
        drivers = DatabaseManager.shared.getAllDrivers()
        isLoading = false
    }

    func deleteDriver(_ driver: Driver) {
        _ = DatabaseManager.shared.deleteDriver(driver)
        drivers.removeAll { $0.id == driver.id }
    }

    func saveDriver(_ driver: Driver) {
        _ = DatabaseManager.shared.saveDriver(driver)
        loadData()
    }

    func isLicenseExpiring(_ driver: Driver, withinDays: Int = 30) -> Bool {
        let futureDate = Date().addingTimeInterval(Double(withinDays) * 24 * 60 * 60)
        return driver.licenseExpiry <= futureDate && driver.status == .active
    }
}

// MARK: - Trip ViewModel
@MainActor
class TripViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var customers: [Customer] = []
    @Published var drivers: [Driver] = []
    @Published var vehicles: [Vehicle] = []
    @Published var selectedTrip: Trip?
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var filterStatus: TripStatus?

    var filteredTrips: [Trip] {
        var result = trips

        if !searchText.isEmpty {
            result = result.filter {
                $0.jobNumber.localizedCaseInsensitiveContains(searchText) ||
                $0.pickupCity.localizedCaseInsensitiveContains(searchText) ||
                $0.deliveryCity.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }

        return result
    }

    func loadData() {
        isLoading = true
        trips = DatabaseManager.shared.getAllTrips()
        customers = DatabaseManager.shared.getAllCustomers()
        drivers = DatabaseManager.shared.getAllDrivers()
        vehicles = DatabaseManager.shared.getAllVehicles()
        isLoading = false
    }

    func deleteTrip(_ trip: Trip) {
        _ = DatabaseManager.shared.deleteTrip(trip)
        trips.removeAll { $0.id == trip.id }
    }

    func saveTrip(_ trip: Trip) {
        _ = DatabaseManager.shared.saveTrip(trip)
        loadData()
    }

    func customerName(for trip: Trip) -> String {
        customers.first { $0.id == trip.customerId }?.companyName ?? "Unknown"
    }

    func driverName(for trip: Trip) -> String {
        guard let driverId = trip.driverId else { return "Unassigned" }
        return drivers.first { $0.id == driverId }?.fullName ?? "Unknown"
    }

    func vehicleName(for trip: Trip) -> String {
        guard let vehicleId = trip.vehicleId else { return "Unassigned" }
        return vehicles.first { $0.id == vehicleId }?.name ?? "Unknown"
    }
}

// MARK: - Customer ViewModel
@MainActor
class CustomerViewModel: ObservableObject {
    @Published var customers: [Customer] = []
    @Published var selectedCustomer: Customer?
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var filterType: CustomerType?

    var filteredCustomers: [Customer] {
        var result = customers

        if !searchText.isEmpty {
            result = result.filter {
                $0.companyName.localizedCaseInsensitiveContains(searchText) ||
                $0.contactName.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText) ||
                $0.phone.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let type = filterType {
            result = result.filter { $0.type == type }
        }

        return result
    }

    func loadData() {
        isLoading = true
        customers = DatabaseManager.shared.getAllCustomers()
        isLoading = false
    }

    func deleteCustomer(_ customer: Customer) {
        _ = DatabaseManager.shared.deleteCustomer(customer)
        customers.removeAll { $0.id == customer.id }
    }

    func saveCustomer(_ customer: Customer) {
        _ = DatabaseManager.shared.saveCustomer(customer)
        loadData()
    }
}

// MARK: - Finance ViewModel
@MainActor
class FinanceViewModel: ObservableObject {
    @Published var invoices: [Invoice] = []
    @Published var expenses: [Expense] = []
    @Published var customers: [Customer] = []
    @Published var isLoading = false
    @Published var selectedTab: FinanceTab = .invoices

    var totalRevenue: Double {
        invoices.filter { $0.status == .paid }.reduce(0) { $0 + $1.total }
    }

    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var outstandingAmount: Double {
        invoices.filter { $0.status == .sent || $0.status == .overdue }.reduce(0) { $0 + $1.total }
    }

    var overdueInvoices: [Invoice] {
        invoices.filter { $0.status == .overdue }
    }

    func loadData() {
        isLoading = true
        invoices = DatabaseManager.shared.getAllInvoices()
        expenses = DatabaseManager.shared.getAllExpenses()
        customers = DatabaseManager.shared.getAllCustomers()
        isLoading = false
    }

    func saveInvoice(_ invoice: Invoice) {
        _ = DatabaseManager.shared.saveInvoice(invoice)
        loadData()
    }

    func deleteInvoice(_ invoice: Invoice) {
        _ = DatabaseManager.shared.deleteInvoice(invoice)
        invoices.removeAll { $0.id == invoice.id }
    }

    func saveExpense(_ expense: Expense) {
        _ = DatabaseManager.shared.saveExpense(expense)
        loadData()
    }

    func deleteExpense(_ expense: Expense) {
        _ = DatabaseManager.shared.deleteExpense(expense)
        expenses.removeAll { $0.id == expense.id }
    }

    func customerName(for invoice: Invoice) -> String {
        customers.first { $0.id == invoice.customerId }?.companyName ?? "Unknown"
    }

    var expensesByCategory: [(ExpenseCategory, Double)] {
        DatabaseManager.shared.getExpensesByCategory()
    }
}

enum FinanceTab: String, CaseIterable {
    case invoices = "Invoices"
    case expenses = "Expenses"
}

// MARK: - Reports ViewModel
@MainActor
class ReportsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var selectedReport: ReportType = .revenue

    @Published var revenueData: [(Date, Double)] = []
    @Published var expenseData: [(ExpenseCategory, Double)] = []
    @Published var fleetUtilizationData: [(VehicleStatus, Int)] = []
    @Published var tripStatusData: [(TripStatus, Int)] = []

    var totalRevenue: Double {
        revenueData.reduce(0) { $0 + $1.1 }
    }

    var totalExpenses: Double {
        expenseData.reduce(0) { $0 + $1.1 }
    }

    var profitMargin: Double {
        guard totalRevenue > 0 else { return 0 }
        return ((totalRevenue - totalExpenses) / totalRevenue) * 100
    }

    func loadData() {
        isLoading = true
        revenueData = DatabaseManager.shared.getRevenueByMonth(months: 12)
        expenseData = DatabaseManager.shared.getExpensesByCategory()
        fleetUtilizationData = DatabaseManager.shared.getFleetUtilization()
        tripStatusData = DatabaseManager.shared.getTripsByStatus()
        isLoading = false
    }
}

enum ReportType: String, CaseIterable {
    case revenue = "Revenue"
    case expenses = "Expenses"
    case fleet = "Fleet Utilization"
    case trips = "Trips"
    case profitLoss = "Profit & Loss"
}

// MARK: - Settings ViewModel
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var settings: BusinessSettings = .default

    func loadData() {
        if let data = UserDefaults.standard.data(forKey: "business_settings"),
           let decoded = try? JSONDecoder().decode(BusinessSettings.self, from: data) {
            settings = decoded
        }
    }

    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "business_settings")
        }
    }

    func resetToDefaults() {
        settings = .default
        saveSettings()
    }

    func exportData() -> URL? {
        let vehicles = DatabaseManager.shared.getAllVehicles()
        let drivers = DatabaseManager.shared.getAllDrivers()
        let trips = DatabaseManager.shared.getAllTrips()
        let customers = DatabaseManager.shared.getAllCustomers()
        let invoices = DatabaseManager.shared.getAllInvoices()
        let expenses = DatabaseManager.shared.getAllExpenses()

        struct ExportData: Codable {
            let exportDate: String
            let vehicles: [Vehicle]
            let drivers: [Driver]
            let trips: [Trip]
            let customers: [Customer]
            let invoices: [Invoice]
            let expenses: [Expense]
        }

        let exportData = ExportData(
            exportDate: ISO8601DateFormatter().string(from: Date()),
            vehicles: vehicles,
            drivers: drivers,
            trips: trips,
            customers: customers,
            invoices: invoices,
            expenses: expenses
        )

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("transfleet_export.json")

        do {
            let data = try JSONEncoder().encode(exportData)
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Export failed: \(error)")
            return nil
        }
    }
}