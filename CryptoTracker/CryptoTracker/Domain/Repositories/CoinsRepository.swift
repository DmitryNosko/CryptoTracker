import Combine
import UIKit

protocol CoinsRepository {
    func fetchCoinsMarkets(page: Int, perPage: Int, ids: [String]?) -> AnyPublisher<[CoinModel], APIError>
    func search(query: String) -> AnyPublisher<[CoinModel], APIError>
    func getCachedCoins() -> [CoinModel]
    func fetchCoinPriceHistory(coinId: String, timeRange: TimeRangeType) -> AnyPublisher<[CoinPrice], APIError>
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

    func search(query: String) -> AnyPublisher<[CoinModel], APIError> {
        coinsAPIService.search(query: query)
            .flatMap { [weak self] searchCoinsResponse -> AnyPublisher<[CoinModel], APIError> in
                guard let self else {
                    return Fail(error: APIError.fetchCoinsMarkets)
                        .eraseToAnyPublisher()
                }

                let coins = searchCoinsResponse.coins
                let ids = coins.map { $0.id }

                return self.coinsAPIService.fetchPrices(ids: ids)
                    .tryMap { pricesResponse in
                        return coins.map { coin in
                            let price = pricesResponse[coin.id]?.usd ?? 0.0
                            return CoinModel(
                                id: coin.id,
                                name: coin.name,
                                symbol: coin.symbol,
                                price: price,
                                image: coin.thumb,
                                isFavorite: false
                            )
                        }
                    }
                    .mapError { _ in APIError.fetchCoinsMarkets }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func getCachedCoins() -> [CoinModel] {
        return coinCache.load()
    }

    func fetchCoinPriceHistory(coinId: String, timeRange: TimeRangeType) -> AnyPublisher<[CoinPrice], APIError> {
        return coinsAPIService.fetchCoinPriceHistory(coinId: coinId, timeRange: timeRange)
            .tryMap { response in
                return response.prices.map { priceData in
                    CoinPrice(
                        timestamp: priceData[0],
                        price: priceData[1]
                    )
                }
            }
            .mapError { _ in
                return APIError.fetchCoinPriceHistory
            }
            .eraseToAnyPublisher()
    }
}
