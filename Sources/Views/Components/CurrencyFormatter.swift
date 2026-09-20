import Foundation

extension Double {
    private static let cachedFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        return formatter
    }()

    func formattedAsCurrency(currencyCode: String? = nil) -> String {
        if let code = currencyCode {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = code
            return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
        }
        return Self.cachedFormatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}
