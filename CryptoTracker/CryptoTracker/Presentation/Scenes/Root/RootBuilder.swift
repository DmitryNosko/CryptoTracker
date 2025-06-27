import UIKit

protocol RootBuilder {
    func build() -> UIViewController
}

final class RootBuilderImpl: RootBuilder {
    private let appContext: AppContext

    init
    (
        appContext: AppContext
    ) {
        self.appContext = appContext
    }

    func build() -> UIViewController {
        let viewController = RootViewController()
        let router = RootRouterImpl(
            view: viewController,
            dashboardBuilder: DashboardBuilderImpl(appContext: appContext)
        )
        let viewModel = RootViewModel(router: router)
        viewController.viewModel = viewModel

        return viewController
    }
}
