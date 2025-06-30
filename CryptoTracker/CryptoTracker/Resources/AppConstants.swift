import Foundation

enum AppConstants {
    enum API {
        static let baseURL = "https://api.coingecko.com/api/v3"

        enum Coins {
            static let coinsMarkets = "/coins/markets"
            static let search = "/search"
            static let prices = "/simple/price"
        }
    }

    enum Cache {
        static let cashJsonName = "coin_cache.json"
        static let ttl: TimeInterval = 3600
    }

    enum FavoriteCoins {
        static let key = "FavoriteCoins"
    }

    enum Notification {
        static let significantChangeThreshold = 0.01
        static let checkSignificantPriceChangesDebounce: Double = 10.0
    }
}
