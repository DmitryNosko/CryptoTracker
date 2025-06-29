import Foundation

protocol CoinFilteringService {
    func filter(_ coins: [CoinModel], by option: FilterOptionType) -> [CoinModel]
}

final class CoinFilteringServiceImpl: CoinFilteringService {
    func filter(_ coins: [CoinModel], by option: FilterOptionType) -> [CoinModel] {
        switch option {
        case .top10:
            return Array(coins.prefix(10))
        case .priceAbove1:
            return coins.filter { $0.price > 1 }
        }
    }
}
