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

            /// Добавил данный код чтобы не показывать 429 ошибку на UI так как ее получаем если привысить бесплатное количество запросов  за короткий промежуток времени
            /// {"status":{"error_code":429,"error_message":"You've exceeded the Rate Limit. Please visit https://www.coingecko.com/en/api/pricing to subscribe to our API plans for higher rate limits."}}
            if let json = try? JSONSerialization.jsonObject(with: data, options: []), !(json is [Any]) {
                return Data("[]".utf8)
            }

            return data
        }
        .decode(type: [CoinModelResponse].self, decoder: JSONDecoder())
        .mapError { error in
            return .fetchCoinsMarkets
        }
        .eraseToAnyPublisher()
    }
}
