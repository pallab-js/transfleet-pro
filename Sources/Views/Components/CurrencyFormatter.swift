import Foundation

extension Double {
    func formattedAsCurrency(currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}
