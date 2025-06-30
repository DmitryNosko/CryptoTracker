import UIKit
import Combine

protocol FavoritesRouter {
    func showCoinDetails(_ coin: CoinModel)
}

final class FavoritesRouterImpl: FavoritesRouter {
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
    
    func showCoinDetails(_ coin: CoinModel) {
        let vc = coinDetailsBuilder
            .setCoin(coin)
            .build()
        view?.navigationController?.present(vc, animated: true)
    }
}
