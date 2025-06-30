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
        let coinDetailsBuilder = CoinDetailsBuilderImpl(appContext: appContext)
        let router = HomeRouterImpl(view: viewController, coinDetailsBuilder: coinDetailsBuilder)

        let viewModel = HomeViewModel(
            router: router,
            coinsRepository: appContext.resolve(CoinsRepository.self),
            favoritesStore: appContext.resolve(FavoritesStore.self),
            coinFilteringService: CoinFilteringServiceImpl(),
            coinSortingService: CoinSortingServiceImpl()
        )
        viewController.viewModel = viewModel

        return viewController
    }
}
