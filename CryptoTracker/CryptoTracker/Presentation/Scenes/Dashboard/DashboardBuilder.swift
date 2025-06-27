import UIKit

protocol DashboardBuilder {
    func build() -> UIViewController
}

final class DashboardBuilderImpl: DashboardBuilder {
    private let appContext: AppContext

    init
    (
        appContext: AppContext
    ) {
        self.appContext = appContext
    }

    func build() -> UIViewController {
        let viewController = DashboardViewController()
        let router = DashboardRouterImpl(
            view: viewController,
            homeBuilder: HomeBuilderImpl(appContext: appContext),
            favoritesBuilder: FavoritesBuilderImpl(appContext: appContext)
        )
        let viewModel = DashboardViewModel(router: router)
        viewController.viewModel = viewModel

        return viewController
    }
}
