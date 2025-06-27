import UIKit
import Combine

protocol RootRouter {
    func showMainScene()
}

final class RootRouterImpl: RootRouter {
    private weak var view: UIViewController?
    private let dashboardBuilder: DashboardBuilder

    init
    (
        view: UIViewController,
        dashboardBuilder: DashboardBuilder
    ) {
        self.view = view
        self.dashboardBuilder = dashboardBuilder
    }

    func showMainScene() {
        let vc = dashboardBuilder
            .build()
        vc.modalPresentationStyle = .fullScreen
        view?.navigationController?.present(vc, animated: true)
    }
}
