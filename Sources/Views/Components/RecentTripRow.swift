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
                Text("\(trip.pickupCity) → \(trip.deliveryCity)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(trip.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(trip.status.color.opacity(0.2))
                    .foregroundColor(trip.status.color)
                    .cornerRadius(4)

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
