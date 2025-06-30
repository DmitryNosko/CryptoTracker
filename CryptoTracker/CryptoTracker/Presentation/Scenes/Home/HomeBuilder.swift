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
        let router = HomeRouterImpl(
            view: viewController,
            coinDetailsBuilder: CoinDetailsBuilderImpl(appContext: appContext)
        )

        let viewModel = HomeViewModel(
            router: router,
            coinsRepository: appContext.resolve(CoinsRepository.self),
            favoritesStore: appContext.resolve(FavoritesStore.self),
            coinFilteringService: appContext.resolve(CoinFilteringService.self),
            coinSortingService: appContext.resolve(CoinSortingService.self),
            priceAlertService: appContext.resolve(PriceAlertService.self),
            notificationService: appContext.resolve(NotificationService.self)
        )
        viewController.viewModel = viewModel

        return viewController
    }
}
