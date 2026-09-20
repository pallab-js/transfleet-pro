import SwiftUI
import Charts

struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        summaryCards
                        chartsSection
                    }
                    .padding(24)
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            viewModel.loadData()
        }
    }

    private var toolbar: some View {
        HStack {
            Text("Reports & Analytics")
                .font(.title)
                .fontWeight(.bold)

            Spacer()

            Picker("Report Type", selection: $viewModel.selectedReport) {
                ForEach(ReportType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .frame(width: 180)

            Button(action: { viewModel.loadData() }) {
                Image(systemName: "arrow.clockwise")
            }
            .accessibilityLabel("Refresh reports")
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            MetricCard(
                title: "Total Revenue (12 Mo)",
                value: viewModel.totalRevenue.formattedAsCurrency(),
                icon: "dollarsign.circle",
                color: .green
            )

            MetricCard(
                title: "Total Expenses (12 Mo)",
                value: viewModel.totalExpenses.formattedAsCurrency(),
                icon: "creditcard",
                color: .red
            )

            MetricCard(
                title: "Net Profit",
                value: (viewModel.totalRevenue - viewModel.totalExpenses).formattedAsCurrency(),
                icon: "chart.line.uptrend.xyaxis",
                color: .blue
            )

            MetricCard(
                title: "Profit Margin",
                value: String(format: "%.1f%%", viewModel.profitMargin),
                icon: "percent",
                color: .purple
            )
        }
    }

    @ViewBuilder
    private var chartsSection: some View {
        switch viewModel.selectedReport {
        case .revenue:
            ChartCard(title: "Monthly Revenue") {
                RevenueTrendChart(data: viewModel.revenueData)
            }

        case .expenses:
            ChartCard(title: "Expenses by Category") {
                ExpensesByCategoryChart(data: viewModel.expenseData)
            }

        case .fleet:
            ChartCard(title: "Fleet Utilization") {
                FleetUtilizationChart(data: viewModel.fleetUtilizationData)
            }

        case .trips:
            ChartCard(title: "Trip Status Distribution") {
                TripStatusDistributionChart(data: viewModel.tripStatusData)
            }

        case .profitLoss:
            VStack(spacing: 16) {
                ChartCard(title: "Monthly Revenue") {
                    RevenueTrendChart(data: viewModel.revenueData)
                }
                ChartCard(title: "Expenses by Category") {
                    ExpensesByCategoryChart(data: viewModel.expenseData)
                }
            }
        }
    }
}
