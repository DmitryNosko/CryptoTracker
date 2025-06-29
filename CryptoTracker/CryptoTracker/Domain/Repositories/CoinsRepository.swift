import Combine
import UIKit

protocol CoinsRepository {
    func fetchCoinsMarkets(page: Int, perPage: Int, ids: [String]?) -> AnyPublisher<[CoinModel], APIError>
    func search(query: String) -> AnyPublisher<[CoinModel], APIError>
    func getCachedCoins() -> [CoinModel]
}

final class CoinsRepositoryImpl: CoinsRepository {
    private let coinsAPIService: CoinsAPIService
    private let coinCache: CoinCache

    init
    (
        coinsAPIService: CoinsAPIService,
        coinCache: CoinCache
    ) {
        self.coinsAPIService = coinsAPIService
        self.coinCache = coinCache
    }

    func fetchCoinsMarkets
    (
        page: Int,
        perPage: Int,
        ids: [String]?
    ) -> AnyPublisher<[CoinModel], APIError> {
        coinsAPIService.fetchCoinsMarkets(page: page, perPage: perPage, ids: ids)
            .tryMap { coinsModelResponse in
                let coins = coinsModelResponse.compactMap { CoinModel.fromCoinModel(response: $0) }
                self.coinCache.save(coins)

                return coins
            }
            .mapError { _ in
                return APIError.fetchCoinsMarkets
            }
            .eraseToAnyPublisher()
    }

    func getCachedCoins() -> [CoinModel] {
        return coinCache.load()
    }

    func search
    (
        query: String
    ) -> AnyPublisher<[CoinModel], APIError> {
        coinsAPIService.search(query: query)
            .flatMap { [weak self] searchCoinsResponse -> AnyPublisher<[CoinModel], APIError> in
                guard let self else {
                    return Fail(error: APIError.fetchCoinsMarkets)
                        .eraseToAnyPublisher()
                }

                let coins = searchCoinsResponse.coins
                let ids = coins.map { $0.id }

                return self.coinsAPIService.fetchPrices(ids: ids)
                    .map { pricesResponse in
                        coins.map { coin in
                            let price = pricesResponse[coin.id]?.usd ?? 0.0
                            return CoinModel(
                                id: coin.id,
                                name: coin.name,
                                symbol: coin.symbol,
                                price: price,
                                image: coin.thumb
                            )
                        }
                    }
                    .mapError { _ in
                        APIError.fetchCoinsMarkets
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
