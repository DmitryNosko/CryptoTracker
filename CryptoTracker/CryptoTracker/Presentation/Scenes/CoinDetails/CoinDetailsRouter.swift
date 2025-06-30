import UIKit
import Combine

protocol CoinDetailsRouter {
    func showAlertOfType(_ alertType: AlertType) -> AnyPublisher<AlertActionType, Never>
}

final class CoinDetailsRouterImpl: CoinDetailsRouter {
    private weak var view: UIViewController?

    init
    (
        view: UIViewController
    ) {
        self.view = view
    }

    func showAlertOfType(_ alertType: AlertType) -> AnyPublisher<AlertActionType, Never> {
        view?.showAlert(alertType) ?? Just(.cancel).eraseToAnyPublisher()
    }
}
