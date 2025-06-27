import Foundation
import Alamofire

enum CoinsTargetType {
    case coinsMarkets(page: Int, perPage: Int)
}

extension CoinsTargetType {
    var baseURL: String {
        switch self {
        case .coinsMarkets:
            return AppConstants.API.baseURL
        }
    }

    var path: String {
        switch self {
        case .coinsMarkets:
            return AppConstants.API.Coins.coinsMarkets
        }
    }

    var method: HTTPMethod {
        switch self {
        case .coinsMarkets:
            return .get
        }
    }

    var headers: HTTPHeaders? {
        return ["Content-Type": "application/json"]
    }

    var parameters: Parameters? {
        switch self {
        case .coinsMarkets(let page, let perPage):
            return [
                "vs_currency": "usd",
                "order": "market_cap_desc",
                "per_page": perPage,
                "page": page
            ]
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .coinsMarkets:
            return URLEncoding.default
        }
    }
}
