import SwiftUI

struct RecentTripRow: View {
    let trip: Trip
    let customerName: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(trip.jobNumber)
                        .font(.headline)
                    Text(customerName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("\(trip.pickupCity) -> \(trip.deliveryCity)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(status: trip.status.rawValue, color: trip.status.color)

                HStack(spacing: 8) {
                    Text(trip.pickupDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(trip.totalAmount.formattedAsCurrency())
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
    }
}
