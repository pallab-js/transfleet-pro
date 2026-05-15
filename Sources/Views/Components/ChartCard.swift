import SwiftUI
import Charts

struct ChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            if #available(macOS 14.0, *) {
                content
                    .frame(height: 200)
            } else {
                Text("Chart requires macOS 14+")
                    .frame(height: 200)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}
