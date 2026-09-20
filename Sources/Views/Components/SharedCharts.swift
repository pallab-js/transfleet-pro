import SwiftUI
import Charts

struct RevenueTrendChart: View {
    let data: [(Date, Double)]

    var body: some View {
        Chart(data, id: \.0) { item in
            BarMark(
                x: .value("Month", item.0, unit: .month),
                y: .value("Revenue", item.1)
            )
            .foregroundStyle(Color.blue.gradient)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { value in
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Revenue trend chart showing monthly revenue data")
    }
}

struct FleetUtilizationChart: View {
    let data: [(VehicleStatus, Int)]

    var body: some View {
        Chart(data, id: \.0) { item in
            SectorMark(
                angle: .value("Count", item.1),
                innerRadius: .ratio(0.5),
                angularInset: 2
            )
            .foregroundStyle(by: .value("Status", item.0.rawValue))
            .cornerRadius(4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fleet utilization chart showing vehicle status distribution")
    }
}

struct ExpensesByCategoryChart: View {
    let data: [(ExpenseCategory, Double)]

    var body: some View {
        Chart(data, id: \.0) { item in
            BarMark(
                x: .value("Category", item.0.rawValue),
                y: .value("Amount", item.1)
            )
            .foregroundStyle(Color.red.gradient)
            .cornerRadius(4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Expenses by category chart")
    }
}

struct TripStatusDistributionChart: View {
    let data: [(TripStatus, Int)]

    var body: some View {
        Chart(data, id: \.0) { item in
            BarMark(
                x: .value("Status", item.0.rawValue),
                y: .value("Count", item.1)
            )
            .foregroundStyle(Color.blue.gradient)
            .cornerRadius(4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Trip status distribution chart")
    }
}
