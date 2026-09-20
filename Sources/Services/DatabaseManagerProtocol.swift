import Foundation

protocol Repository {
    associatedtype Entity
    func save(_ entity: Entity) throws
    func getAll() throws -> [Entity]
    func delete(_ entity: Entity) throws
}

@MainActor
protocol DatabaseManagerProtocol {
    var databaseError: String? { get }
    func initializeDatabase()

    func saveVehicle(_ vehicle: Vehicle) throws
    func getAllVehicles() throws -> [Vehicle]
    func deleteVehicle(_ vehicle: Vehicle) throws

    func saveDriver(_ driver: Driver) throws
    func getAllDrivers() throws -> [Driver]
    func deleteDriver(_ driver: Driver) throws

    func saveTrip(_ trip: Trip) throws
    func getAllTrips() throws -> [Trip]
    func deleteTrip(_ trip: Trip) throws

    func saveCustomer(_ customer: Customer) throws
    func getAllCustomers() throws -> [Customer]
    func deleteCustomer(_ customer: Customer) throws

    func saveInvoice(_ invoice: Invoice) throws
    func getAllInvoices() throws -> [Invoice]
    func deleteInvoice(_ invoice: Invoice) throws

    func saveExpense(_ expense: Expense) throws
    func getAllExpenses() throws -> [Expense]
    func deleteExpense(_ expense: Expense) throws

    func saveMaintenanceRecord(_ record: MaintenanceRecord) throws
    func getAllMaintenanceRecords(for vehicleId: UUID?) throws -> [MaintenanceRecord]
    func deleteMaintenanceRecord(_ record: MaintenanceRecord) throws

    func saveFuelLog(_ log: FuelLog) throws
    func getAllFuelLogs(for vehicleId: UUID?) throws -> [FuelLog]
    func deleteFuelLog(_ log: FuelLog) throws

    func saveCertification(_ cert: Certification) throws
    func getAllCertifications(for driverId: UUID?) throws -> [Certification]
    func deleteCertification(_ cert: Certification) throws

    func saveSettings(_ settings: BusinessSettings) throws
    func loadSettings() -> BusinessSettings

    func getDashboardStats() throws -> DashboardStats
    func getRevenueByMonth(months: Int) throws -> [(Date, Double)]
    func getExpensesByCategory() throws -> [(ExpenseCategory, Double)]
    func getFleetUtilization(includeRetired: Bool) throws -> [(VehicleStatus, Int)]
    func getTripsByStatus() throws -> [(TripStatus, Int)]

    func exportAllData() throws -> Data
    func importAllData(from data: Data) throws
}
