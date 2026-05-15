import Foundation

extension Double {
    func formattedAsCurrency(currencyCode: String? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        if let code = currencyCode {
            formatter.currencyCode = code
        }
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}
