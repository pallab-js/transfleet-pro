import SwiftUI

struct PaginationState {
    var currentPage: Int = 1
    var itemsPerPage: Int = 25

    var pageSizeOptions: [Int] { [25, 50, 100] }

    func validCurrentPage(for totalItems: Int) -> Int {
        let maxPage = totalPages(for: totalItems)
        return max(1, min(currentPage, maxPage))
    }

    func page<T>(_ items: [T]) -> ArraySlice<T> {
        guard !items.isEmpty else { return [] }
        let validPage = validCurrentPage(for: items.count)
        let start = (validPage - 1) * itemsPerPage
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

    private var displayPage: Int {
        state.validCurrentPage(for: totalItems)
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
                Button(action: { if displayPage > 1 { state.currentPage = displayPage - 1 } }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(displayPage <= 1)
                .buttonStyle(.borderless)

                Text("Page \(displayPage) of \(totalPages)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button(action: { if displayPage < totalPages { state.currentPage = displayPage + 1 } }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(displayPage >= totalPages)
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

