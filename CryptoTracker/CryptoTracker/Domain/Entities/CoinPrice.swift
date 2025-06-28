import Foundation

// MARK: - Response Model
typealias CoinPricesResponse = [String: CoinPrice]

struct CoinPrice: Decodable {
    let usd: Double?
}
