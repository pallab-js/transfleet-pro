import SwiftUI

extension TripStatus {
    var color: Color {
        switch self {
        case .completed: return .green
        case .inTransit: return .orange
        case .pending: return .gray
        case .cancelled: return .red
        case .delivered: return .teal
        case .assigned: return .blue
        }
    }
}
