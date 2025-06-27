import Alamofire
import Combine

protocol CoinsAPIService {
    func fetchCoinsMarkets(page: Int, perPage: Int) -> AnyPublisher<[CoinModelResponse], APIError>
}

final class CoinsAPIServiceImpl: CoinsAPIService {
    private let session: Session

    init
    (
        session: Session = .default
    ) {
        self.session = session
    }

    func fetchCoinsMarkets(
        page: Int,
        perPage: Int
    ) -> AnyPublisher<[CoinModelResponse], APIError> {
        let endpoint = CoinsTargetType.coinsMarkets(page: page, perPage: perPage)
        let url = "\(endpoint.baseURL)\(endpoint.path)"

        return session.request(
            url,
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: endpoint.encoding,
            headers: endpoint.headers
        )
        .publishData()
        .tryMap { result in
            guard let data = result.data else {
                throw APIError.fetchCoinsMarkets
            }
            return data
        }
        .decode(type: [CoinModelResponse].self, decoder: JSONDecoder())
        .mapError { error in
            debugPrint("🛑 error to fetchCoinsMarkets = \(error)")
            return .fetchCoinsMarkets
        }
        .eraseToAnyPublisher()
    }
}
