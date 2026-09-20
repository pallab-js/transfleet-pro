import SwiftUI

extension VehicleStatus {
    var color: Color {
        switch self {
        case .available: return .green
        case .inUse: return .blue
        case .maintenance: return .orange
        case .retired: return .gray
        }
    }
}

extension DriverStatus {
    var color: Color {
        switch self {
        case .active: return .green
        case .onLeave: return .orange
        case .suspended: return .red
        case .terminated: return .gray
        }
    }
}

extension InvoiceStatus {
    var color: Color {
        switch self {
        case .draft: return .gray
        case .sent: return .blue
        case .paid: return .green
        case .overdue: return .red
        case .cancelled: return .gray
        }
    }
}
