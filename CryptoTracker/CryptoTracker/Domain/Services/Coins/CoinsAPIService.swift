import Alamofire
import Combine

protocol CoinsAPIService {
    func fetchCoinsMarkets(page: Int, perPage: Int) -> AnyPublisher<[CoinModelResponse], APIError>
    func search(query: String) -> AnyPublisher<SearchCoinsResponse, APIError>
    func fetchPrices(ids: [String]) -> AnyPublisher<CoinPricesResponse, APIError>
}

final class CoinsAPIServiceImpl: CoinsAPIService {
    private let session: Session

    init
    (
        session: Session = .default
    ) {
        self.session = session
    }

    func fetchCoinsMarkets
    (
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

    func search(query: String) -> AnyPublisher<SearchCoinsResponse, APIError> {
        let endpoint = CoinsTargetType.search(query: query)
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
                throw APIError.searchCoins
            }

            return data
        }
        .decode(type: SearchCoinsResponse.self, decoder: JSONDecoder())
        .mapError { error in
            return .searchCoins
        }
        .eraseToAnyPublisher()
    }

    func fetchPrices(ids: [String]) -> AnyPublisher<CoinPricesResponse, APIError> {
        let endpoint = CoinsTargetType.prices(ids: ids)
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
                throw APIError.fetchPrices
            }

            return data
        }
        .decode(type: CoinPricesResponse.self, decoder: JSONDecoder())
        .mapError { error in
            return .fetchPrices
        }
        .eraseToAnyPublisher()
    }
}
