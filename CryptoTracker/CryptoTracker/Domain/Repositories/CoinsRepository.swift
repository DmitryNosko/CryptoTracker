import Combine
import UIKit

protocol CoinsRepository {
    func fetchCoinsMarkets(page: Int, perPage: Int) -> AnyPublisher<[CoinModel], APIError>
}

final class CoinsRepositoryImpl: CoinsRepository {
    private let coinsAPIService: CoinsAPIService

    init
    (
        coinsAPIService: CoinsAPIService
    ) {
        self.coinsAPIService = coinsAPIService
    }

    func fetchCoinsMarkets
    (
        page: Int,
        perPage: Int
    ) -> AnyPublisher<[CoinModel], APIError> {
        coinsAPIService.fetchCoinsMarkets(page: page, perPage: perPage)
            .tryMap { coinsModelResponse in
                return coinsModelResponse.compactMap { CoinModel.from(response: $0) }
            }
            .mapError { error -> APIError in
                return APIError.fetchCoinsMarkets
            }
            .eraseToAnyPublisher()
    }
}
