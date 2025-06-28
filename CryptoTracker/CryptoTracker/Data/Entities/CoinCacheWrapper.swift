import Foundation

struct CoinCacheWrapper: Codable {
    let timestamp: Date
    let coins: [CoinModel]
}
