import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                statsGrid
                chartsSection
                recentActivitySection
            }
            .padding(24)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            viewModel.loadData()
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Overview of your transportation business")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: {
                viewModel.loadData()
            }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            MetricCard(
                title: "Total Vehicles",
                value: "\(viewModel.stats.totalVehicles)",
                subtitle: "\(viewModel.stats.activeVehicles) active",
                icon: "bus",
                color: .blue
            )

            MetricCard(
                title: "Active Drivers",
                value: "\(viewModel.stats.activeDrivers)",
                subtitle: "of \(viewModel.stats.totalDrivers) total",
                icon: "person.2",
                color: .green
            )

            MetricCard(
                title: "Today's Trips",
                value: "\(viewModel.stats.todayTrips)",
                subtitle: "\(viewModel.stats.pendingTrips) pending",
                icon: "shippingbox",
                color: .orange
            )

            MetricCard(
                title: "Monthly Revenue",
                value: viewModel.stats.monthlyRevenue.formattedAsCurrency(),
                subtitle: "Profit: \(String(format: "%.1f", viewModel.profitMargin))%",
                icon: "dollarsign.circle",
                color: .purple
            )
        }
    }

    private var chartsSection: some View {
        HStack(spacing: 16) {
            ChartCard(title: "Revenue Trend") {
                RevenueTrendChart(data: viewModel.revenueData)
            }

            ChartCard(title: "Fleet Utilization") {
                FleetUtilizationChart(data: viewModel.fleetUtilizationData)
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Trips")
                .font(.headline)

            if viewModel.recentTrips.isEmpty {
                Text("No recent trips")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentTrips.prefix(5)) { trip in
                        RecentTripRow(trip: trip, customerName: viewModel.recentTripCustomerNames[trip.customerId] ?? "Unknown")
                        Divider()
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
        }
    }
}
