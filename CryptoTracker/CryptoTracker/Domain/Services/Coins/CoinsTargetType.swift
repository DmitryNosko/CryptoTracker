import Foundation
import Alamofire

enum CoinsTargetType {
    case coinsMarkets(page: Int, perPage: Int, ids: [String]? = nil)
    case search(query: String)
    case prices(ids: [String])
}

extension CoinsTargetType {
    var baseURL: String {
        return AppConstants.API.baseURL
    }

    var path: String {
        switch self {
        case .coinsMarkets:
            return AppConstants.API.Coins.coinsMarkets
        case .search:
            return AppConstants.API.Coins.search
        case .prices:
            return AppConstants.API.Coins.prices
        }
    }

    var method: HTTPMethod {
        switch self {
        case .coinsMarkets:
            return .get
        case .search:
            return .get
        case .prices:
            return .get
        }
    }

    var headers: HTTPHeaders? {
        return ["Content-Type": "application/json"]
    }

    var parameters: Parameters? {
        switch self {
        case .coinsMarkets(let page, let perPage, let ids):
                var params: Parameters = [
                    "vs_currency": "usd",
                    "order": "market_cap_desc",
                    "per_page": perPage,
                    "page": page
                ]
                if let ids = ids, !ids.isEmpty {
                    params["ids"] = ids.joined(separator: ",")
                }
                return params
        case .search(let query):
            return [
                "query": query
            ]
        case .prices(let ids):
            return [
                "ids": ids.joined(separator: ","),
                "vs_currencies": "usd"
            ]
        }
    }

    var encoding: ParameterEncoding {
        URLEncoding.default
    }
}
