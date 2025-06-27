import UIKit

protocol HomeBuilder {
    func build() -> UIViewController
}

final class HomeBuilderImpl: HomeBuilder {
    private let appContext: AppContext

    init
    (
        appContext: AppContext
    ) {
        self.appContext = appContext
    }

    func build() -> UIViewController {
        let viewController = HomeViewController()
        let router = HomeRouterImpl(view: viewController)
        let viewModel = HomeViewModel(router: router)
        viewController.viewModel = viewModel

        return viewController
    }
}
