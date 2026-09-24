import Foundation

extension Double {
    @MainActor
    private static var customFormatters: [String: NumberFormatter] = [:]

    @MainActor
    private static let cachedFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        return formatter
    }()

    @MainActor
    func formattedAsCurrency(currencyCode: String? = nil) -> String {
        guard let code = currencyCode else {
            return Self.cachedFormatter.string(from: NSNumber(value: self)) ?? "$0.00"
        }
        if let existing = Self.customFormatters[code] {
            return existing.string(from: NSNumber(value: self)) ?? "$0.00"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        Self.customFormatters[code] = formatter
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}
