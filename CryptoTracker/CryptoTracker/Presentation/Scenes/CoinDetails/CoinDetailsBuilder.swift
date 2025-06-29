import UIKit

protocol CoinDetailsBuilder {
    func setCoin(_ coin: CoinModel) -> CoinDetailsBuilder
    func build() -> UIViewController
}

final class CoinDetailsBuilderImpl: CoinDetailsBuilder {
    private let appContext: AppContext

    init
    (
        appContext: AppContext
    ) {
        self.appContext = appContext
    }

    private(set) var coin: CoinModel = .empty
    func setCoin(_ coin: CoinModel) -> CoinDetailsBuilder {
        self.coin = coin
        return self
    }

    func build() -> UIViewController {
        let viewController = CoinDetailsViewController()
        let router = CoinDetailsRouterImpl(view: viewController)
        let viewModel = CoinDetailsViewModel(
            router: router,
            coin: coin
        )
        viewController.viewModel = viewModel

        return viewController
    }
}
