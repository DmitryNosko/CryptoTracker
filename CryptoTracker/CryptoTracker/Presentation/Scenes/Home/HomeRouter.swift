import UIKit
import Combine

protocol HomeRouter {
    func showAlertOfType(_ alertType: AlertType) -> AnyPublisher<AlertActionType, Never>
}

final class HomeRouterImpl: HomeRouter {
    private weak var view: UIViewController?

    init
    (
        view: UIViewController
    ) {
        self.view = view
    }

    func showAlertOfType
    (
        _ alertType: AlertType
    ) -> AnyPublisher<AlertActionType, Never> {
        view?.showAlert(alertType) ?? Just(.cancel).eraseToAnyPublisher()
    }
}
