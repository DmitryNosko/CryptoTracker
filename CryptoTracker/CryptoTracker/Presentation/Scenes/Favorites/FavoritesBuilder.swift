import UIKit

protocol FavoritesBuilder {
    func build() -> UIViewController
}

final class FavoritesBuilderImpl: FavoritesBuilder {
    private let appContext: AppContext

    init
    (
        appContext: AppContext
    ) {
        self.appContext = appContext
    }

    func build() -> UIViewController {
        let viewController = FavoritesViewController()
        let router = FavoritesRouterImpl(
            view: viewController,
            coinDetailsBuilder: CoinDetailsBuilderImpl(appContext: appContext)
        )
        let viewModel = FavoritesViewModel(
            router: router,
            favoritesStore: appContext.resolve(FavoritesStore.self)
        )
        viewController.viewModel = viewModel

        return viewController
    }
}
