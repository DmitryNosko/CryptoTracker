import UIKit

enum AlertType {
    case fetchCoinsMarketsError
    case fetchCoinsPriceHistory
    case sort
    case filter

    var title: String? {
        switch self {
        case .fetchCoinsMarketsError:
            return "Oooops..."
        case .fetchCoinsPriceHistory:
            return "Oooops..."
        case .sort:
            return "Sort by"
        case .filter:
            return "Filter"
        }
    }

    var message: String? {
        switch self {
        case .fetchCoinsMarketsError:
            return "Something went wrong while fetching coins, you can try again."
        case .fetchCoinsPriceHistory:
            return "Something went wrong while fetching coins price history, you can try again."
        case .sort, .filter:
            return nil
        }
    }

    var actions: [AlertAction] {
        switch self {
        case .fetchCoinsMarketsError:
            return [
                .init(title: "Cancel", style: .destructive, result: .bool(false)),
                .init(title: "Try Again", style: .default, result: .bool(true))
            ]
        case .fetchCoinsPriceHistory:
            return [
                .init(title: "Cancel", style: .destructive, result: .bool(false)),
                .init(title: "Try Again", style: .default, result: .bool(true))
            ]
        case .sort:
            return [
                .init(title: "Price ↑", style: .default, result: .sort(.priceAscending)),
                .init(title: "Price ↓", style: .default, result: .sort(.priceDescending)),
                .init(title: "Name A-Z", style: .default, result: .sort(.nameAZ)),
                .init(title: "Name Z-A", style: .default, result: .sort(.nameZA)),
                .init(title: "Cancel", style: .cancel, result: .cancel)
            ]

        case .filter:
            return [
                .init(title: "Top 10", style: .default, result: .filter(.top10)),
                .init(title: "Price > $1", style: .default, result: .filter(.priceAbove1)),
                .init(title: "Cancel", style: .cancel, result: .cancel)
            ]
        }
    }
}

enum AlertActionType {
    case bool(Bool)
    case sort(SortOptionType)
    case filter(FilterOptionType?)
    case cancel
}

struct AlertAction {
    let title: String
    let style: UIAlertAction.Style
    let result: AlertActionType
}
