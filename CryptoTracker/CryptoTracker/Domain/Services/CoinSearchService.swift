import Foundation
import Combine

protocol CoinSearchService {
    func searchFromAPI(query: String) -> AnyPublisher<[CoinModel], Never>
}

final class CoinSearchServiceImpl: CoinSearchService {
    private let coinsRepository: CoinsRepository
    
    init(coinsRepository: CoinsRepository) {
        self.coinsRepository = coinsRepository
    }
    
    func searchFromAPI(query: String) -> AnyPublisher<[CoinModel], Never> {
        return coinsRepository.searchCoins(query: query)
            .catch { _ in
                return Just([])
            }
            .eraseToAnyPublisher()
    }
} 