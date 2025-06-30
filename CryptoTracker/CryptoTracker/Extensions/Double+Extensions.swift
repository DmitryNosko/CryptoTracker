import Foundation

extension Double {
    enum FormatStyle {
        case largeNumber /// 1.25B, 250.2K, etc.
        case supply /// 1B, 250K
    }

    func formatted(style: FormatStyle) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = style == .largeNumber ? 2 : 0

        let value: Double
        let suffix: String

        switch self {
        case 1_000_000_000_000... where style == .largeNumber:
            value = self / 1_000_000_000_000
            suffix = "T"
        case 1_000_000_000...:
            value = self / 1_000_000_000
            suffix = "B"
        case 1_000_000...:
            value = self / 1_000_000
            suffix = "M"
        case 1_000...:
            value = self / 1_000
            suffix = "K"
        default:
            return formatter.string(from: NSNumber(value: self)) ?? "0"
        }

        let formatted = formatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(formatted)\(suffix)"
    }
}

