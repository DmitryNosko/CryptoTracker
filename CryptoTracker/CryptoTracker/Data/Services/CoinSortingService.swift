import Foundation

protocol CoinSortingService {
    func sort(_ coins: [CoinModel], by option: SortOptionType) -> [CoinModel]
}

final class CoinSortingServiceImpl: CoinSortingService {
    func sort(_ coins: [CoinModel], by option: SortOptionType) -> [CoinModel] {
        switch option {
        case .priceAscending:
            return coins.sorted { $0.price < $1.price }
        case .priceDescending:
            return coins.sorted { $0.price > $1.price }
        case .nameAZ:
            return coins.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .nameZA:
            return coins.sorted { $0.name.lowercased() > $1.name.lowercased() }
        }
    }
} 
