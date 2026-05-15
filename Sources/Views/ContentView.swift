import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } detail: {
            DetailView()
        }
        .frame(minWidth: 1200, minHeight: 800)
    }
}

struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List(selection: $appState.selectedTab) {
            Section("Operations") {
                ForEach([AppTab.dashboard, AppTab.fleet, AppTab.drivers, AppTab.trips]) { tab in
                    SidebarRow(tab: tab, isSelected: appState.selectedTab == tab)
                        .tag(tab)
                }
            }

            Section("Business") {
                ForEach([AppTab.customers, AppTab.finance]) { tab in
                    SidebarRow(tab: tab, isSelected: appState.selectedTab == tab)
                        .tag(tab)
                }
            }

            Section("Analytics") {
                ForEach([AppTab.reports]) { tab in
                    SidebarRow(tab: tab, isSelected: appState.selectedTab == tab)
                        .tag(tab)
                }
            }

            Section("System") {
                SidebarRow(tab: AppTab.settings, isSelected: appState.selectedTab == AppTab.settings)
                    .tag(AppTab.settings)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("TransFleet Pro")
    }
}

struct SidebarRow: View {
    let tab: AppTab
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tab.icon)
                .font(.system(size: 16))
                .frame(width: 24)

            Text(tab.rawValue)
                .font(.body)

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

struct DetailView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch appState.selectedTab {
            case .dashboard:
                DashboardView()
            case .fleet:
                FleetView()
            case .drivers:
                DriversView()
            case .trips:
                TripsView()
            case .customers:
                CustomersView()
            case .finance:
                FinanceView()
            case .reports:
                ReportsView()
            case .settings:
                SettingsView()
            }
        }
    }
}