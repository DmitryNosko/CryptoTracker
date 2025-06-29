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
        let router = FavoritesRouterImpl(view: viewController)
        let viewModel = FavoritesViewModel(
            router: router,
            coinsRepository: appContext.resolve(CoinsRepository.self),
            favoritesStore: appContext.resolve(FavoritesStore.self)
        )
        viewController.viewModel = viewModel

        return viewController
    }
}
