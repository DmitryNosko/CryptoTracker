import Foundation
import UIKit

// MARK: - ViewModel
struct CoinModel: Codable, Equatable {
    let id: String
    let name: String
    let symbol: String
    let price: Double
    let image: String
    var isFavorite: Bool

    // For Chart
    var marketCap: Double?
    var marketCapRank: Int?
    var totalVolume: Double?
    var priceChange24h: Double?
    var priceChangePercentage24h: Double?
    var high24h: Double?
    var low24h: Double?
    var circulatingSupply: Double?
    var totalSupply: Double?
    var maxSupply: Double?

    var imageURL: URL? {
        URL(string: image)
    }
}

extension CoinModel {
    static let empty: CoinModel = .init(
        id: String(),
        name: String(),
        symbol: String(),
        price: Double(),
        image: String(),
        isFavorite: Bool(),
        marketCap: nil,
        marketCapRank: nil,
        totalVolume: Double(),
        priceChange24h: nil,
        priceChangePercentage24h: nil,
        high24h: nil,
        low24h: nil,
        circulatingSupply: nil,
        totalSupply: nil,
        maxSupply: nil
    )

    static func fromCoinModel(response: CoinModelResponse) -> CoinModel {
        return CoinModel(
            id: response.id,
            name: response.name,
            symbol: response.symbol,
            price: response.currentPrice,
            image: response.image,
            isFavorite: false,
            marketCap: response.marketCap,
            marketCapRank: response.marketCapRank,
            totalVolume: response.totalVolume,
            priceChange24h: response.priceChange24h,
            priceChangePercentage24h: response.priceChangePercentage24h,
            high24h: response.high24h,
            low24h: response.low24h,
            circulatingSupply: response.circulatingSupply,
            totalSupply: response.totalSupply,
            maxSupply: response.maxSupply
        )
    }

    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 8
        let formatted = formatter.string(from: NSNumber(value: price)) ?? "$0.00"

        return "~" + formatted.replacingOccurrences(of: " ", with: "")
    }
    
    var formattedMarketCap: String {
        guard let marketCap = marketCap else { return "N/A" }
        return marketCap.formatted(style: .largeNumber)
    }
    
    var formattedVolume: String {
        return (totalVolume ?? 0.0).formatted(style: .largeNumber)
    }
    
    var formattedPriceChange24h: String {
        guard let change = priceChangePercentage24h else { return "0.00%" }
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", change))%"
    }
    
    var priceChangeColor: UIColor {
        guard let change = priceChangePercentage24h else { return .label }
        return change >= 0 ? .systemGreen : .systemRed
    }
}

// MARK: - Response Model
struct CoinModelResponse: Codable, Identifiable {
    let id: String
    let symbol: String
    let name: String
    let image: String
    let currentPrice: Double
    let marketCap: Double?
    let marketCapRank: Int?
    let fullyDilutedValuation: Double?
    let totalVolume: Double
    let high24h: Double?
    let low24h: Double?
    let priceChange24h: Double?
    let priceChangePercentage24h: Double?
    let marketCapChange24h: Double?
    let marketCapChangePercentage24h: Double?
    let circulatingSupply: Double?
    let totalSupply: Double?
    let maxSupply: Double?
    let ath: Double?
    let athChangePercentage: Double?
    let athDate: String?
    let atl: Double?
    let atlChangePercentage: Double?
    let atlDate: String?
    let roi: ROI?
    let lastUpdated: String?

    struct ROI: Codable {
        let times: Double
        let currency: String
        let percentage: Double
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case image
        case currentPrice = "current_price"
        case marketCap = "market_cap"
        case marketCapRank = "market_cap_rank"
        case fullyDilutedValuation = "fully_diluted_valuation"
        case totalVolume = "total_volume"
        case high24h = "high_24h"
        case low24h = "low_24h"
        case priceChange24h = "price_change_24h"
        case priceChangePercentage24h = "price_change_percentage_24h"
        case marketCapChange24h = "market_cap_change_24h"
        case marketCapChangePercentage24h = "market_cap_change_percentage_24h"
        case circulatingSupply = "circulating_supply"
        case totalSupply = "total_supply"
        case maxSupply = "max_supply"
        case ath
        case athChangePercentage = "ath_change_percentage"
        case athDate = "ath_date"
        case atl
        case atlChangePercentage = "atl_change_percentage"
        case atlDate = "atl_date"
        case roi
        case lastUpdated = "last_updated"
    }
}

