import UIKit
import Combine

protocol HomeRouter {
    func showAlertOfType(_ alertType: AlertType) -> AnyPublisher<AlertActionType, Never>
    func showCoinDetails(_ coin: CoinModel)
}

final class HomeRouterImpl: HomeRouter {
    private weak var view: UIViewController?
    private let coinDetailsBuilder: CoinDetailsBuilder

    init
    (
        view: UIViewController,
        coinDetailsBuilder: CoinDetailsBuilder
    ) {
        self.view = view
        self.coinDetailsBuilder = coinDetailsBuilder
    }

    func showAlertOfType(_ alertType: AlertType) -> AnyPublisher<AlertActionType, Never> {
        view?.showAlert(alertType) ?? Just(.cancel).eraseToAnyPublisher()
    }

    func showCoinDetails(_ coin: CoinModel) {
        let vc = coinDetailsBuilder
            .setCoin(coin)
            .build()
        view?.navigationController?.present(vc, animated: true)
    }
}
