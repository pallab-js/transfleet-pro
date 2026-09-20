import SwiftUI

@main
struct TransFleetProApp: App {
    @StateObject private var appState = AppState()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 1200, minHeight: 800)
                .alert("Database Error", isPresented: $appState.showDatabaseError) {
                    Button("Retry") {
                        appState.retryDatabaseInit()
                    }
                    Button("Quit", role: .destructive) {
                        NSApplication.shared.terminate(nil)
                    }
                } message: {
                    Text(appState.databaseErrorMessage)
                }
        }
        .windowStyle(.automatic)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Trip") {
                    appState.selectedTab = .trips
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(100))
                        appState.showNewTripSheet = true
                    }
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("New Vehicle") {
                    appState.selectedTab = .fleet
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(100))
                        appState.showNewVehicleSheet = true
                    }
                }

                Button("New Driver") {
                    appState.selectedTab = .drivers
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(100))
                        appState.showNewDriverSheet = true
                    }
                }

                Button("New Customer") {
                    appState.selectedTab = .customers
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(100))
                        appState.showNewCustomerSheet = true
                    }
                }
            }

            CommandGroup(after: .sidebar) {
                Button("Dashboard") {
                    appState.selectedTab = .dashboard
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Fleet") {
                    appState.selectedTab = .fleet
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Drivers") {
                    appState.selectedTab = .drivers
                }
                .keyboardShortcut("3", modifiers: .command)

                Button("Trips") {
                    appState.selectedTab = .trips
                }
                .keyboardShortcut("4", modifiers: .command)

                Button("Customers") {
                    appState.selectedTab = .customers
                }
                .keyboardShortcut("5", modifiers: .command)

                Button("Finance") {
                    appState.selectedTab = .finance
                }
                .keyboardShortcut("6", modifiers: .command)

                Button("Reports") {
                    appState.selectedTab = .reports
                }
                .keyboardShortcut("7", modifiers: .command)

                Button("Settings") {
                    appState.selectedTab = .settings
                }
                .keyboardShortcut("8", modifiers: .command)
            }
        }
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case fleet = "Fleet"
    case drivers = "Drivers"
    case trips = "Trips"
    case customers = "Customers"
    case finance = "Finance"
    case reports = "Reports"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.bottom.50percent"
        case .fleet: return "bus"
        case .drivers: return "person.2"
        case .trips: return "shippingbox"
        case .customers: return "person.crop.circle"
        case .finance: return "dollarsign.circle"
        case .reports: return "chart.bar"
        case .settings: return "gear"
        }
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var selectedTab: AppTab = .dashboard
    @Published var showNewTripSheet = false
    @Published var showNewVehicleSheet = false
    @Published var showNewDriverSheet = false
    @Published var showNewCustomerSheet = false
    @Published var showDatabaseError = false
    @Published var databaseErrorMessage = ""

    init() {
        retryDatabaseInit()
    }

    func retryDatabaseInit() {
        DatabaseManager.shared.initializeDatabase()
        if let error = DatabaseManager.shared.databaseError {
            databaseErrorMessage = error
            showDatabaseError = true
        }
    }
}
