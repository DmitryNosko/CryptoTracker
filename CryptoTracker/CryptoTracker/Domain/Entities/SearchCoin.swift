import Foundation

// MARK: - Response Model
struct SearchCoinsResponse: Codable {
    let coins: [SearchCoinResponse]
}

struct SearchCoinResponse: Codable {
    let id: String
    let name: String
    let apiSymbol: String
    let symbol: String
    let marketCapRank: Int?
    let thumb: String
    let large: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case apiSymbol = "api_symbol"
        case symbol
        case marketCapRank = "market_cap_rank"
        case thumb
        case large
    }
}
