import SwiftUI

struct PaginationState {
    var currentPage: Int = 1
    var itemsPerPage: Int = 25

    var pageSizeOptions: [Int] { [25, 50, 100] }

    func page<T>(_ items: [T]) -> ArraySlice<T> {
        let start = (currentPage - 1) * itemsPerPage
        let end = min(start + itemsPerPage, items.count)
        guard start < items.count else { return [] }
        return items[start..<end]
    }

    func totalPages(for totalItems: Int) -> Int {
        guard totalItems > 0 else { return 1 }
        return Int(ceil(Double(totalItems) / Double(itemsPerPage)))
    }

    mutating func reset() { currentPage = 1 }
}

struct PaginationView: View {
    @Binding var state: PaginationState
    let totalItems: Int

    private var totalPages: Int {
        state.totalPages(for: totalItems)
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            Picker("Per page", selection: $state.itemsPerPage) {
                ForEach(state.pageSizeOptions, id: \.self) { size in
                    Text("\(size)").tag(size)
                }
            }
            .frame(width: 80)
            .onChange(of: state.itemsPerPage) { _, _ in
                state.reset()
            }

            Text("\(totalItems) items")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: DesignTokens.Spacing.sm) {
                Button(action: { if state.currentPage > 1 { state.currentPage -= 1 } }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(state.currentPage <= 1)
                .buttonStyle(.borderless)

                Text("Page \(state.currentPage) of \(totalPages)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button(action: { if state.currentPage < totalPages { state.currentPage += 1 } }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(state.currentPage >= totalPages)
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}
