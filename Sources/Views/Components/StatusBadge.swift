import SwiftUI

struct StatusBadge: View {
    let status: String
    let color: Color

    var body: some View {
        Text(status)
            .font(.caption)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(DesignTokens.CornerRadius.sm)
            .accessibilityLabel("Status: \(status)")
    }
}

struct SearchField: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
        }
        .padding(DesignTokens.Spacing.sm)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(DesignTokens.CornerRadius.md)
        .frame(width: 200)
        .accessibilityLabel(placeholder)
    }
}
