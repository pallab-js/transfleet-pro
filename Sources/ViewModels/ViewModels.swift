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
    @Published var recentTripCustomerNames: [UUID: String] = [:]
    @Published var revenueData: [(Date, Double)] = []
    @Published var fleetUtilizationData: [(VehicleStatus, Int)] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var profitMargin: Double {
        guard stats.monthlyRevenue > 0 else { return 0 }
        return ((stats.monthlyRevenue - stats.monthlyExpenses) / stats.monthlyRevenue) * 100
    }

    func loadData() {
        isLoading = true
        Task {
            do {
                stats = try DatabaseManager.shared.getDashboardStats()
                let customers = try DatabaseManager.shared.getAllCustomers()
                recentTripCustomerNames = Dictionary(uniqueKeysWithValues: customers.map { ($0.id, $0.companyName) })
                recentTrips = Array(try DatabaseManager.shared.getAllTrips().prefix(10))
                revenueData = try DatabaseManager.shared.getRevenueByMonth(months: 6)
                fleetUtilizationData = try DatabaseManager.shared.getFleetUtilization()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
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
    @Published var errorMessage: String?

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
        Task {
            do {
                vehicles = try DatabaseManager.shared.getAllVehicles()
            } catch {
                errorMessage = error.localizedDescription
            }
            selectedVehicle = nil
            isLoading = false
        }
    }

    func deleteVehicle(_ vehicle: Vehicle) {
        do {
            try DatabaseManager.shared.deleteVehicle(vehicle)
            vehicles.removeAll { $0.id == vehicle.id }
            if selectedVehicle?.id == vehicle.id {
                selectedVehicle = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveVehicle(_ vehicle: Vehicle) {
        do {
            try DatabaseManager.shared.saveVehicle(vehicle)
            loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
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
    @Published var errorMessage: String?

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
        Task {
            do {
                drivers = try DatabaseManager.shared.getAllDrivers()
            } catch {
                errorMessage = error.localizedDescription
            }
            selectedDriver = nil
            isLoading = false
        }
    }

    func deleteDriver(_ driver: Driver) {
        do {
            try DatabaseManager.shared.deleteDriver(driver)
            drivers.removeAll { $0.id == driver.id }
            if selectedDriver?.id == driver.id {
                selectedDriver = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveDriver(_ driver: Driver) {
        do {
            try DatabaseManager.shared.saveDriver(driver)
            loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isLicenseExpiring(_ driver: Driver, withinDays: Int = 30) -> Bool {
        let now = Date()
        let futureDate = now.addingTimeInterval(Double(withinDays) * 24 * 60 * 60)
        return driver.licenseExpiry > now && driver.licenseExpiry <= futureDate && driver.status == .active
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
    @Published var errorMessage: String?

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
        Task {
            do {
                trips = try DatabaseManager.shared.getAllTrips()
                customers = try DatabaseManager.shared.getAllCustomers()
                drivers = try DatabaseManager.shared.getAllDrivers()
                vehicles = try DatabaseManager.shared.getAllVehicles()
            } catch {
                errorMessage = error.localizedDescription
            }
            selectedTrip = nil
            isLoading = false
        }
    }

    func deleteTrip(_ trip: Trip) {
        do {
            try DatabaseManager.shared.deleteTrip(trip)
            trips.removeAll { $0.id == trip.id }
            if selectedTrip?.id == trip.id {
                selectedTrip = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveTrip(_ trip: Trip) {
        do {
            try DatabaseManager.shared.saveTrip(trip)
            loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
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
        return vehicles.first { $0.id == vehicleId }?.displayName ?? "Unknown"
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
    @Published var errorMessage: String?

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
        Task {
            do {
                customers = try DatabaseManager.shared.getAllCustomers()
            } catch {
                errorMessage = error.localizedDescription
            }
            selectedCustomer = nil
            isLoading = false
        }
    }

    func deleteCustomer(_ customer: Customer) {
        do {
            try DatabaseManager.shared.deleteCustomer(customer)
            customers.removeAll { $0.id == customer.id }
            if selectedCustomer?.id == customer.id {
                selectedCustomer = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveCustomer(_ customer: Customer) {
        do {
            try DatabaseManager.shared.saveCustomer(customer)
            loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
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
    @Published var errorMessage: String?

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
        Task {
            do {
                invoices = try DatabaseManager.shared.getAllInvoices()
                expenses = try DatabaseManager.shared.getAllExpenses()
                customers = try DatabaseManager.shared.getAllCustomers()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func saveInvoice(_ invoice: Invoice) {
        do {
            try DatabaseManager.shared.saveInvoice(invoice)
            loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteInvoice(_ invoice: Invoice) {
        do {
            try DatabaseManager.shared.deleteInvoice(invoice)
            invoices.removeAll { $0.id == invoice.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveExpense(_ expense: Expense) {
        do {
            try DatabaseManager.shared.saveExpense(expense)
            loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteExpense(_ expense: Expense) {
        do {
            try DatabaseManager.shared.deleteExpense(expense)
            expenses.removeAll { $0.id == expense.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func customerName(for invoice: Invoice) -> String {
        customers.first { $0.id == invoice.customerId }?.companyName ?? "Unknown"
    }

    var expensesByCategory: [(ExpenseCategory, Double)] {
        var result: [ExpenseCategory: Double] = [:]
        for expense in expenses {
            result[expense.category, default: 0] += expense.amount
        }
        return result.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
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
    @Published var errorMessage: String?

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
        Task {
            do {
                revenueData = try DatabaseManager.shared.getRevenueByMonth(months: 12)
                expenseData = try DatabaseManager.shared.getExpensesByCategory()
                fleetUtilizationData = try DatabaseManager.shared.getFleetUtilization()
                tripStatusData = try DatabaseManager.shared.getTripsByStatus()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
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
    @Published var errorMessage: String?

    func loadData() {
        settings = DatabaseManager.shared.loadSettings()
    }

    func saveSettings() {
        do {
            try DatabaseManager.shared.saveSettings(settings)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetToDefaults() {
        settings = .default
        saveSettings()
    }

    func exportData() -> URL? {
        do {
            let data = try DatabaseManager.shared.exportAllData()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = formatter.string(from: Date())
            let filename = "transfleet_export_\(timestamp).json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: tempURL)
            return tempURL
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func importData(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            try DatabaseManager.shared.importAllData(from: data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
