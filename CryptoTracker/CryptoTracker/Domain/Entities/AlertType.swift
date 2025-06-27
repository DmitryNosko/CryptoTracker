import UIKit

enum AlertType {
    case fetchCoinsMarketsError

    var title: String? {
        switch self {
            case .fetchCoinsMarketsError:
            return "Oooops..."
        }
    }

    var message: String? {
        switch self {
        case .fetchCoinsMarketsError:
            "Something went wrong while to fetch coins, you can try it again."
        }
    }

    var actions: [AlertAction] {
        switch self {
        case .fetchCoinsMarketsError:
            return [
                .init(title: "Cancel", style: .destructive, result: .bool(false)),
                .init(title: "Try Again", style: .default, result: .bool(true))
            ]
        }
    }
}

enum AlertActionType {
    case bool(Bool)
    case cancel
}

struct AlertAction {
    let title: String
    let style: UIAlertAction.Style
    let result: AlertActionType
}
