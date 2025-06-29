import Foundation
import Combine

protocol CoinSearchService {
    func search(_ coins: [CoinModel], query: String) -> [CoinModel]
    func searchFromAPI(query: String) -> AnyPublisher<[CoinModel], Never>
}

final class CoinSearchServiceImpl: CoinSearchService {
    private let coinsRepository: CoinsRepository
    
    init(coinsRepository: CoinsRepository) {
        self.coinsRepository = coinsRepository
    }
    
    func search(_ coins: [CoinModel], query: String) -> [CoinModel] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedQuery.isEmpty else { return coins }
        
        return coins.filter { coin in
            coin.name.lowercased().contains(trimmedQuery) ||
            coin.symbol.lowercased().contains(trimmedQuery)
        }
    }
    
    func searchFromAPI(query: String) -> AnyPublisher<[CoinModel], Never> {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return Just([]).eraseToAnyPublisher() }
        
        return coinsRepository.search(query: trimmedQuery)
            .catch { _ in Just([]) }
            .eraseToAnyPublisher()
    }
} 