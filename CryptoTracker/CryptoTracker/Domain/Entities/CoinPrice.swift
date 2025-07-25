import Foundation

// MARK: - ViewModel
struct CoinPrice: Decodable {
    let usd: Double?

    let timestamp: Double?
    let price: Double?
    
    init(usd: Double?) {
        self.usd = usd
        self.timestamp = nil
        self.price = nil
    }
    
    init(timestamp: Double, price: Double) {
        self.timestamp = timestamp
        self.price = price
        self.usd = nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.usd = try container.decodeIfPresent(Double.self, forKey: .usd)
        self.timestamp = nil
        self.price = nil
    }
    
    private enum CodingKeys: String, CodingKey {
        case usd
    }
}

// MARK: - Response Model
typealias CoinPricesResponse = [String: CoinPrice]

struct CoinPriceHistoryResponse: Decodable {
    let prices: [[Double]]
    let marketCaps: [[Double]]
    let totalVolumes: [[Double]]
    
    private enum CodingKeys: String, CodingKey {
        case prices
        case marketCaps = "market_caps"
        case totalVolumes = "total_volumes"
    }
}
